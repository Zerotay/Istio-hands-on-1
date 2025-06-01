#!/bin/bash

set -e

cat <<EOF | kind create cluster --config=-
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
name: vap
nodes:
  - role: control-plane
    image: kindest/node:v1.32.2
  - role: worker
    image: kindest/node:v1.32.2
EOF

kubectl create ns ns-test --context kind-vap

cat <<EOF | kubectl apply --context kind-vap -f -
apiVersion: admissionregistration.k8s.io/v1
kind: ValidatingAdmissionPolicy
metadata:
  name: test-policy
spec:
  failurePolicy: Fail
  matchConstraints:
    matchPolicy: Equivalent
    resourceRules:
      - apiGroups:
          - '*'
        apiVersions:
          - '*'
        operations:
          - CREATE
          - UPDATE
        resources:
          - deployments
        scope: '*'
  paramKind:
    apiVersion: v1
    kind: ConfigMap
  validations:
    - expression: "object.spec.replicas == int(params.data.replica)"
      message: Invalid replica count
EOF

cat <<EOF | kubectl apply --context kind-vap -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: param-test
  namespace: ns-test
data:
  replica: '3'
EOF

cat <<EOF | kubectl apply --context kind-vap -f -
apiVersion: admissionregistration.k8s.io/v1
kind: ValidatingAdmissionPolicyBinding
metadata:
  name: "test-binding"
spec:
  matchResources:
    matchPolicy: Equivalent
    namespaceSelector:
      matchLabels:
        kubernetes.io/metadata.name: ns-test
  paramRef:
    name: param-test
    namespace: ns-test
    parameterNotFoundAction: Deny
  policyName: test-policy
  validationActions:
    - Deny
EOF

sleep 5

cat <<EOF | kubectl apply --context kind-vap -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: test
  namespace: ns-test
spec:
  replicas: 1
  selector:
    matchLabels:
      app: test
  template:
    metadata:
      labels:
        app: test
    spec:
      containers:
        - name: test
          image: busybox:latest
          command: ["sleep", "3600"]
EOF
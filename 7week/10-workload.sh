kwest -n istioinaction apply -f ch12/webapp-deployment-svc.yaml
kwest -n istioinaction apply -f ch12/webapp-gw-vs.yaml
kwest -n istioinaction apply -f ch12/catalog-svc.yaml

keast -n istioinaction apply -f ch12/catalog.yaml

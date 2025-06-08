# Metadata about this makefile and position
MKFILE_PATH := $(lastword $(MAKEFILE_LIST))
CURRENT_DIR := $(patsubst %/,%,$(dir $(realpath $(MKFILE_PATH))))

# Ensure GOPATH
GOPATH ?= $(HOME)/go
GOBIN ?= $(GOPATH)/bin
GOVERSION := $(shell go version | awk '{print $3}' | sed -e 's/^go//')
GOFILES ?= $(shell go list $(TEST) | grep -v /vendor/)

# List all our actual files, excluding vendor

# Tags specific for building
GOTAGS ?=

# Get the project metadata
PROJECT := $(CURRENT_DIR:$(GOPATH)/src/%=%)
OWNER ?= Zerotay
NAME ?= headerer
VERSION := $(shell cat "${CURRENT_DIR}/VERSION")
TIMESTAMP := $(shell date)

# Get local ARCH; on Intel Mac, 'uname -m' returns x86_64 which we turn into amd64.
# Not using 'go env GOOS/GOARCH' here so 'make docker' will work without local Go install.
ARCH     ?= $(shell A=$$(uname -m); [ $$A = x86_64 ] && A=amd64; echo $$A)
OS       ?= $(shell uname | tr [[:upper:]] [[:lower:]])
PLATFORM = $(OS)/$(ARCH)
BIN      = $(NAME)

version:
	@echo $(VERSION)
.PHONY: version

build:
	CGO_ENABLED=0 go build cmd/main.go \
		-a \
		-o="${BIN}" \
		-trimpath \
		-buildvcs=false
.PHONY: build

DOCKERUSERNAME=zerotay
TAG=$(DOCKERUSERNAME)/simple-$(NAME):$(VERSION)
docker:
	docker build --platform linux/amd64,linux/arm64 --push --tag ${TAG} .
	@echo 'Image built; run "docker run --rm ${TAG}" to try it out.'
.PHONY: docker

# clean removes any previous binaries
clean:
	@rm -rf "${BIN}"
.PHONY: clean

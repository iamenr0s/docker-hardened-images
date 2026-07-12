DISTRO   ?= debian
VERSION  ?= 12
FLAVOR   ?= micro
IMAGE    ?= $(DISTRO)-hardened:$(VERSION)-$(FLAVOR)
REGISTRIES ?= docker.io/CHANGEME/$(DISTRO)-hardened quay.io/CHANGEME/$(DISTRO)-hardened

export REGISTRIES

.PHONY: help lint build test sbom scan sign push all

help:            ## Show this help
	@grep -E '^[a-z]+:.*##' $(MAKEFILE_LIST) | awk -F':.*## ' '{printf "  %-8s %s\n", $$1, $$2}'

lint:            ## Lint Dockerfiles with hadolint
	hadolint --config .hadolint.yaml images/$(DISTRO)/Dockerfile

build:           ## Build image locally (host arch)
	scripts/build.sh $(DISTRO) $(VERSION) $(FLAVOR)

test: build      ## Run container-structure-tests
	container-structure-test test \
	  --image $(firstword $(REGISTRIES)):$(VERSION)-$(FLAVOR) \
	  --config tests/$(DISTRO)/$(FLAVOR).yaml

sbom:            ## Generate SBOMs with syft
	scripts/sbom.sh $(firstword $(REGISTRIES)):$(VERSION)-$(FLAVOR) sbom

scan:            ## Scan with grype + trivy (fails on fixable High/Critical)
	scripts/scan.sh $(firstword $(REGISTRIES)):$(VERSION)-$(FLAVOR)

push:            ## Build multi-arch and push to all registries
	scripts/build.sh $(DISTRO) $(VERSION) $(FLAVOR) --push

all: lint build test sbom scan   ## Full local pipeline


RELEASE := prometheus
NAMESPACE := kube-system

CHART_NAME := stable/prometheus
CHART_VERSION ?= 11.7.0

DEV_CLUSTER ?= p4-development
DEV_PROJECT ?= planet-4-151612
DEV_ZONE ?= us-central1-a

PROD_CLUSTER ?= planet4-production
PROD_PROJECT ?= planet4-production
PROD_ZONE ?= us-central1-a

.DEFAULT_TARGET: status

lint:
	@find . -type f -name '*.yml' | xargs yamllint
	@find . -type f -name '*.yaml' | xargs yamllint

init:
	helm init --client-only
	helm repo update

dev: lint init
ifndef CI
	$(error Please commit and push, this is intended to be run in a CI environment)
endif
	gcloud config set project $(DEV_PROJECT)
	gcloud container clusters get-credentials $(DEV_CLUSTER) --zone $(DEV_ZONE) --project $(DEV_PROJECT)
	-kubectl label namespace $(NAMESPACE)
	helm upgrade --install --force --wait $(RELEASE) \
		--namespace=$(NAMESPACE) \
		--version $(CHART_VERSION) \
		-f values.yaml \
		$(CHART_NAME)
	$(MAKE) history

prod: lint init
ifndef CI
	$(error Please commit and push, this is intended to be run in a CI environment)
endif
	gcloud config set project $(PROD_PROJECT)
	gcloud container clusters get-credentials $(PROD_PROJECT) --zone $(PROD_ZONE) --project $(PROD_PROJECT)
	-kubectl label namespace $(NAMESPACE)
	helm upgrade --install --force --wait $(RELEASE) \
		--namespace=$(NAMESPACE) \
		--version $(CHART_VERSION) \
		-f values.yaml \
		$(CHART_NAME)
	$(MAKE) history

destroy:
	helm delete --purge $(RELEASE)

history:
	helm history $(RELEASE) --max=5

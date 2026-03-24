# ============================================================================
# Author: Serges Horace Teutchou Tchamba
# Role:   DevSecOps & Platform Engineering
# Purpose:
#   Unified automation for:
#     - k3s installation and teardown
#     - Kubernetes namespace initialization
#     - Helm deployments across dev/qa/staging/prod
#     - Environment lifecycle management
# ============================================================================

SHELL := /bin/bash

# -----------------------------
# k3s automation scripts
# -----------------------------
INSTALL_SCRIPT := scripts/k3s-install.sh
UNINSTALL_SCRIPT := scripts/k3s-uninstall.sh

.PHONY: install-k3s uninstall-k3s k8s-init

install-k3s:
	@chmod +x $(INSTALL_SCRIPT)
	sudo $(INSTALL_SCRIPT)

uninstall-k3s:
	@chmod +x $(UNINSTALL_SCRIPT)
	@echo ">>> Full k3s teardown starting"
	sudo $(UNINSTALL_SCRIPT) server || true
	sudo $(UNINSTALL_SCRIPT) agent || true
	@echo ">>> k3s fully removed from system"

k8s-init:
	@chmod +x scripts/k8s-init.sh
	@./scripts/k8s-init.sh

# -----------------------------
# Helm deployment automation
# -----------------------------
CHART_NAME=movie-platform
CHART_PATH=./movie-platform

DEV_NS=dev
QA_NS=qa
STAGING_NS=staging
PROD_NS=prod

DEV_VALUES=$(CHART_PATH)/values-dev.yaml
QA_VALUES=$(CHART_PATH)/values-qa.yaml
STAGING_VALUES=$(CHART_PATH)/values-staging.yaml
PROD_VALUES=$(CHART_PATH)/values-prod.yaml

.PHONY: help
help:
	@echo "Available commands:"
	@echo "  make install-k3s        - Install k3s cluster"
	@echo "  make uninstall-k3s      - Remove k3s completely"
	@echo "  make k8s-init           - Initialize namespaces and base config"
	@echo "  make deploy-dev         - Deploy to dev namespace"
	@echo "  make deploy-qa          - Deploy to qa namespace"
	@echo "  make deploy-staging     - Deploy to staging namespace"
	@echo "  make deploy-prod        - Deploy to prod namespace"
	@echo "  make uninstall-dev      - Remove dev deployment"
	@echo "  make uninstall-qa       - Remove qa deployment"
	@echo "  make uninstall-staging  - Remove staging deployment"
	@echo "  make uninstall-prod     - Remove prod deployment"
	@echo "  make list               - List all Helm releases"

deploy-dev:
	helm upgrade --install $(CHART_NAME)-dev $(CHART_PATH) \
	    -n $(DEV_NS) -f $(DEV_VALUES)

deploy-qa:
	helm upgrade --install $(CHART_NAME)-qa $(CHART_PATH) \
	    -n $(QA_NS) -f $(QA_VALUES)

deploy-staging:
	helm upgrade --install $(CHART_NAME)-staging $(CHART_PATH) \
	    -n $(STAGING_NS) -f $(STAGING_VALUES)

deploy-prod:
	helm upgrade --install $(CHART_NAME)-prod $(CHART_PATH) \
	    -n $(PROD_NS) -f $(PROD_VALUES)

uninstall-dev:
	helm uninstall $(CHART_NAME)-dev -n $(DEV_NS)

uninstall-qa:
	helm uninstall $(CHART_NAME)-qa -n $(QA_NS)

uninstall-staging:
	helm uninstall $(CHART_NAME)-staging -n $(STAGING_NS)

uninstall-prod:
	helm uninstall $(CHART_NAME)-prod -n $(PROD_NS)

list:
	helm list -A

# ============================================================================
# Jenkins Automation
# ============================================================================

JENKINS_CONTAINER=jenkins
JENKINS_IMAGE=jenkins/jenkins:lts

.PHONY: jenkins-start jenkins-stop jenkins-restart jenkins-logs jenkins-status

jenkins-start:
	@echo ">>> Starting Jenkins container"
	docker run -d \
	  --name $(JENKINS_CONTAINER) \
	  -p 8080:8080 -p 50000:50000 \
	  -v jenkins_home:/var/jenkins_home \
	  -v /usr/local/bin/kubectl:/usr/local/bin/kubectl \
	  -v /usr/local/bin/helm:/usr/local/bin/helm \
	  -v /etc/rancher/k3s/k3s.yaml:/root/.kube/config:ro \
	  -v /var/run/docker.sock:/var/run/docker.sock \
	  $(JENKINS_IMAGE)

jenkins-stop:
	@echo ">>> Stopping Jenkins container"
	docker stop $(JENKINS_CONTAINER) || true

jenkins-restart:
	@echo ">>> Restarting Jenkins container"
	docker restart $(JENKINS_CONTAINER)

jenkins-logs:
	@echo ">>> Jenkins logs (Ctrl+C to exit)"
	docker logs -f $(JENKINS_CONTAINER)

jenkins-status:
	@echo ">>> Jenkins container status"
	docker ps -a | grep $(JENKINS_CONTAINER) || true
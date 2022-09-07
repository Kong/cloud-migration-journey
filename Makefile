.DEFAULT_GOAL := help

# Project Configuration
CONFIG_NAME ?= kmj

# Containers
IMAGE_BASE_NAME ?= kmj
DEFAULT_TAG ?= latest
RELEASE_TAG ?= `git rev-parse --short HEAD`

# AWS
AWS_CREDS_PATH = $(HOME)/.aws/credentials
AWS_CONFIG_PATH = $(HOME)/.aws/config

# Docker
DOCKER_MOUNTS = ""

#!! target: description
#!! ===================: ====================================================================================
#!! help: Lists the available make targets.  Run a make target by running 'make <target name>'
help:
	@clear
	@printf '\e[1;32m%-6s\e[m' " Kong Migration Journey:"
	@printf "\n\n"
	@grep -E '(\#!!\s{1}.*\:\s{1})(.*$$)' $(MAKEFILE_LIST) | tr -d '#!!' | awk 'BEGIN {FS = ":"}; {printf "\033[36m%-20s\033[35m %s\n", $$1, $$2}'


#!! build: Build and prepare Kong Migration Journey for demonstration
build:
	@echo "Creating local configuration in $(HOME)/.$(CONFIG_NAME)..."
	@mkdir -p $(HOME)/.$(CONFIG_NAME)/{ansible,tf,logs}
	@echo "Removing old Kong Migration Journey container builds if they exist..."
	@- docker rmi `docker images $(IMAGE_BASE_NAME)-tf --format='{{.ID}}'` -f > /dev/null 2>&1
	@echo "Building Kong Migration Journey containers..."
	@docker build ./automation/ -t $(IMAGE_BASE_NAME)-tf:$(RELEASE_TAG) -t $(IMAGE_BASE_NAME)-tf:$(DEFAULT_TAG) -f ./automation/Dockerfile.terraform
	@echo "Done!"


#!! infra.prep: Prepare to build your Kong Migration Journey demonstration infrastructure
infra.prep:
	@echo "Let's make sure your AWS CLI is configured, press return to avoid making changes to existing configurations..."
	@aws configure
	@echo "Planning your Kong Migration Journey demonstration infrastructure deployment..."
	@docker run --rm -v $(HOME)/.$(CONFIG_NAME):/kmj/out -v $(AWS_CREDS_PATH):/root/.aws/credentials -v $(AWS_CONFIG_PATH):/root/.aws/config --name=$(IMAGE_BASE_NAME)-tf  $(IMAGE_BASE_NAME)-tf:latest plan -out /kmj/out/tf/plan.out > $(HOME)/.$(CONFIG_NAME)/logs/infra.prep.log 2>&1
	@echo "Done!"
	@echo "Review the logs at $(HOME)/.$(CONFIG_NAME)/logs/infra.prep.log"

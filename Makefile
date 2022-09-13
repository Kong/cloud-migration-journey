.DEFAULT_GOAL := help

# Project Configuration
CONFIG_NAME ?= kmj

# Containers
IMAGE_BASE_NAME ?= kmj
DEFAULT_TAG ?= latest
RELEASE_TAG ?= `git rev-parse --short HEAD`

# AWS
AWS_CREDS_PATH ?= $(HOME)/.aws/credentials

# Terraform
TF_VARS ?= user.tfvars

#!! target: description
#!! ===================: ====================================================================================
#!! help: Lists the available make targets.  Run a make target by running 'make <target name>'
help:
	@clear
	@printf '\e[1;32m%-6s\e[m' " Kong Migration Journey:"
	@printf "\n\n"
	@grep -E '(\#!!\s{1}.*\:\s{1})(.*$$)' $(MAKEFILE_LIST) | tr -d '#!!' | awk 'BEGIN {FS = ":"}; {printf "\033[36m%-20s\033[35m %s\n", $$1, $$2}'


#!! build: Build and prepare Kong Migration Journey utility containers for demo based off of local repository clone
build:
	@clear
	@echo "Removing old Kong Migration Journey utility containers if they exist..."
	@- docker rmi `docker images $(IMAGE_BASE_NAME)-tf --format='{{.ID}}'` -f > /dev/null 2>&1
	@- docker rmi `docker images $(IMAGE_BASE_NAME)-ansible --format='{{.ID}}'` -f > /dev/null 2>&1
	@echo "Building Kong Migration Journey utility containers..."
	@echo "Terraform utility container build..."
	@docker build ./automation/ -t $(IMAGE_BASE_NAME)-tf:$(RELEASE_TAG) -t $(IMAGE_BASE_NAME)-tf:$(DEFAULT_TAG) -f ./automation/Dockerfile.terraform
	@echo "Ansible utility container build..."
	@docker build ./automation -t $(IMAGE_BASE_NAME)-ansible:$(RELEASE_TAG) -t $(IMAGE_BASE_NAME)-ansible:$(DEFAULT_TAG) -f ./automation/Dockerfile.ansible
	@echo "Done!"


#!! prep: Prepare your local workstation for the Kong Migration Journey demo.
prep:
	@clear
	@echo "Let's make sure your AWS CLI is configured, press return to avoid making changes to existing configurations..."
	@aws configure
	@echo "Creating local configuration directory and files in $(HOME)/.$(CONFIG_NAME)..."
	@mkdir -p $(HOME)/.$(CONFIG_NAME)/{ansible,tf,logs,ec2,eks}
	@if [ ! -f $(HOME)/.$(CONFIG_NAME)/tf/$(TF_VARS) ]; then \
		echo "Copying default terraform customization variables to $(HOME)/.$(CONFIG_NAME)/tf/$(TF_VARS)..."; \
		cp ./automation/configs/user.tfvars $(HOME)/.$(CONFIG_NAME)/tf/$(TF_VARS); \
	else \
		echo "Default terraform customization variables exist, not copying..."; \
	fi
	@printf "\n\n"
	@printf "To customize your demo infrastructure, such as AWS region and availability zones, edit:\n$(HOME)/.$(CONFIG_NAME)/tf/$(TF_VARS)\nDone!"


#!! infra.deploy: Deploys your Kong Migration Journey demo infrastructure.
infra.deploy:
	@clear
	@echo "Deploying your Kong Migration Journey demo AWS infrastructure..."
	@echo "This will take some time: estimate 10-15min..."
	@- ME=`whoami` && \
	docker run \
		--rm \
		-v $(HOME)/.$(CONFIG_NAME):/$(CONFIG_NAME)/out \
		-v $(AWS_CREDS_PATH):/root/.aws/credentials \
		-v $(HOME)/.$(CONFIG_NAME)/tf/$(TF_VARS):/root/$(TF_VARS):ro \
		--name=$(IMAGE_BASE_NAME)-tf \
		$(IMAGE_BASE_NAME)-tf:latest \
		apply -state=/$(CONFIG_NAME)/out/tf/terraform.tfstate \
			-var-file="/root/$(TF_VARS)" \
			-var "me=$$ME" \
			-auto-approve \
			> $(HOME)/.$(CONFIG_NAME)/logs/infra.deploy.log 2>&1; \
		if [ $$? -ne 0 ]; then echo "Error with deployment. See logs for details!"; else echo "Done!";fi
	@printf "\n\nReview the logs at:\n$(HOME)/.$(CONFIG_NAME)/logs/infra.deploy.log"


#!! infra.destroy: Destroys all of your Kong Migration Journey demo infrastructure.
infra.destroy:
	@clear
	@echo "Destroying your Kong Migration Journey demo infrastructure..."
	@echo "This will take some time: estimate 10-15min..."
	@ME=`whoami` && \
	docker run \
		--rm \
		-v $(HOME)/.$(CONFIG_NAME):/$(CONFIG_NAME)/out \
		-v $(AWS_CREDS_PATH):/root/.aws/credentials \
		-v $(HOME)/.$(CONFIG_NAME)/tf/$(TF_VARS):/root/$(TF_VARS):ro \
		--name=$(IMAGE_BASE_NAME)-tf \
		$(IMAGE_BASE_NAME)-tf:latest \
		destroy -state=/$(CONFIG_NAME)/out/tf/terraform.tfstate \
			-var-file="/root/$(TF_VARS)"\
			-var "me=$$ME" \
			-auto-approve \
			> $(HOME)/.$(CONFIG_NAME)/logs/infra.destroy.log 2>&1;
	@echo "Removing terraform state file: $(HOME)/.$(CONFIG_NAME)/tf/terraform.state..."
	@rm -f $(HOME)/.$(CONFIG_NAME)/tf/terraform.tfstate
	@echo "Removing ansible inventory file: $(HOME)/.$(CONFIG_NAME)/ansible/inventory.yml..."
	@rm -f $(HOME)/.$(CONFIG_NAME)/ansible/inventory.yml
	@echo "Done!"
	@printf "\n\nReview the logs at:\n$(HOME)/.$(CONFIG_NAME)/logs/infra.destroy.log"

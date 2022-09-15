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


# Help Outputs
# base64 encoded due to shell char issues for output
TITLE = "IDrilojilojilZcgIOKWiOKWiOKVlyDilojilojilojilojilojilojilZcg4paI4paI4paI4pWXICAg4paI4paI4pWXIOKWiOKWiOKWiOKWiOKWiOKWiOKVlwogOuKWiOKWiOKVkSDilojilojilZTilZ3ilojilojilZTilZDilZDilZDilojilojilZfilojilojilojilojilZcgIOKWiOKWiOKVkeKWiOKWiOKVlOKVkOKVkOKVkOKVkOKVnQogOuKWiOKWiOKWiOKWiOKWiOKVlOKVnSDilojilojilZEgICDilojilojilZHilojilojilZTilojilojilZcg4paI4paI4pWR4paI4paI4pWRICDilojilojilojilZcKIDrilojilojilZTilZDilojilojilZcg4paI4paI4pWRICAg4paI4paI4pWR4paI4paI4pWR4pWa4paI4paI4pWX4paI4paI4pWR4paI4paI4pWRICAg4paI4paI4pWRCiA64paI4paI4pWRICDilojilojilZfilZrilojilojilojilojilojilojilZTilZ3ilojilojilZEg4pWa4paI4paI4paI4paI4pWR4pWa4paI4paI4paI4paI4paI4paI4pWU4pWdCiA64pWa4pWQ4pWdICDilZrilZDilZ0g4pWa4pWQ4pWQ4pWQ4pWQ4pWQ4pWdIOKVmuKVkOKVnSAg4pWa4pWQ4pWQ4pWQ4pWdIOKVmuKVkOKVkOKVkOKVkOKVkOKVnSAK"
SUBTITLE = "ICAgX18gIF9fIF8gICAgICAgICAgICAgICAgIF8gICBfICAgICAgICAgICAgIDogICAgICAgXyAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgCiAgfCAgXC8gIChfKSAgICAgICAgICAgICAgIHwgfCAoXykgICAgICAgICAgICA6ICAgICAgfCB8ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIAogIHwgXCAgLyB8XyAgX18gXyBfIF9fIF9fIF98IHxfIF8gIF9fXyAgXyBfXyAgOiAgICAgIHwgfCBfX18gIF8gICBfIF8gX18gXyBfXyAgIF9fXyBfICAgXyAKICB8IHxcL3wgfCB8LyBfYCB8ICdfXy8gX2AgfCBfX3wgfC8gXyBcfCAnXyBcIDogIF8gICB8IHwvIF8gXHwgfCB8IHwgJ19ffCAnXyBcIC8gXyBcIHwgfCB8CiAgfCB8ICB8IHwgfCAoX3wgfCB8IHwgKF98IHwgfF98IHwgKF8pIHwgfCB8IHw6IHwgfF9ffCB8IChfKSB8IHxffCB8IHwgIHwgfCB8IHwgIF9fLyB8X3wgfAogIHxffCAgfF98X3xcX18sIHxffCAgXF9fLF98XF9ffF98XF9fXy98X3wgfF98OiAgXF9fX18vIFxfX18vIFxfXyxffF98ICB8X3wgfF98XF9fX3xcX18sIHwKICAgICAgICAgICAgIF9fLyB8ICAgICAgICAgICAgICAgICAgICAgICAgICAgIDogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIF9fLyB8CiAgICAgICAgICAgIHxfX18vICAgICAgICAgICAgICAgICAgICAgICAgICAgICA6ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIHxfX18vIAo="







#!! target: description
#!! ===================: ======================================================================================
#!! help: Lists the available make targets.  Run a make target by running 'make <target name>'
help:
	@clear
	@printf "\n\n"
	@echo "$(TITLE)" | base64 -d | awk 'BEGIN {FS = ":"}; {printf "\033[36m%-35s\033[1;37m %s\n", $$1, $$2}'
	@echo "$(SUBTITLE)" | base64 -d | awk 'BEGIN {FS = ":"}; {printf "        \033[0;32m%-0s\033[35m%s\n", $$1, $$2}'
	@printf "\n"
	@grep -E '(\#!!\s{1}.*\:\s{1})(.*$$)' $(MAKEFILE_LIST) | tr -d '#!!' | awk 'BEGIN {FS = ":"}; {printf "\033[36m%-20s\033[35m%s\n", $$1, $$2}'
	@printf "\n\n"


#!! build: Build and prepare utility containers for demo based off of local repository clone
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
	@printf "To customize your demo infrastructure, such as AWS region and availability zones, edit:\n$(HOME)/.$(CONFIG_NAME)/tf/$(TF_VARS)\nDone!\n"


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
	@printf "\n\nReview the logs at:\n$(HOME)/.$(CONFIG_NAME)/logs/infra.deploy.log\n"


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
	@echo "Done!"
	@printf "\n\nReview the logs at:\n$(HOME)/.$(CONFIG_NAME)/logs/infra.destroy.log\n"
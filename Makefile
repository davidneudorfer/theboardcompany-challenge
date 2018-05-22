# http://clarkgrubb.com/makefile-style-guide
# MAKEFLAGS += --warn-undefined-variables
SHELL := bash
.SHELLFLAGS := -eu -o pipefail -c
.DEFAULT_GOAL := help
.DELETE_ON_ERROR:
.SUFFIXES:

# Platform-specific variables
# ---------------------------
.PLATFORM_INFO:= $(shell python -m platform)
ifeq ($(findstring centos,$(PLATFORM_INFO)),centos)
	PLATFORM:= centos
endif
ifeq ($(findstring Ubuntu,$(PLATFORM_INFO)),Ubuntu)
	PLATFORM:= ubuntu
endif
ifeq ($(findstring Darwin,$(PLATFORM_INFO)),Darwin)
	PLATFORM:= darwin
endif

# List of possible environments
# ------------------------
STAGING = dev ops
ALLENVS = $(STAGING) production

# Check ENV name
# ------------------------
# this is defaulted to dev in .envrc
ifeq ($(filter $(TBCENV),$(ALLENVS)),)
$(error Valid TBCENV values include: $(ALLENVS))
endif

# Set target directory
# ------------------------
# Checks if
ifneq ($(filter $(TBCENV),$(STAGING)),)
ENVDIR=terraform/envs/staging/$(TBCENV)
PREFIX=staging
else
ENVDIR=terraform/envs/production/$(TBCENV)
PREFIX=production
endif

# Check target directory existence
# ------------------------
ifeq (,$(wildcard $(ENVDIR)))
$(error Target directory [$(ENVDIR)] does not exist!)
endif

# AWS shortcuts
# ------------------------

aws: ## print currently configured AWS IAM user
	@aws iam get-user

bucket : ## first time setup to ensure terraform config bucket exists
	@BUCKET="$$(aws s3 ls | grep theboardcompany-terraform)"; \
	if [[ $$? -eq 1 ]]; then \
	  echo "$(BUCKET)"; \
		aws s3 mb s3://theboardcompany-terraform; \
	else \
		echo "bucket already exists"; \
	fi
	@echo "ensure versioning is enabled"
	@aws s3api put-bucket-versioning \
	  --bucket theboardcompany-terraform \
		--versioning-configuration Status=Enabled

spot:
	@aws ec2 describe-spot-price-history \
	  --availability-zone us-west-2a \
	  --product-descriptions "Linux/UNIX (Amazon VPC)" \
	  --instance-types m3.medium | jq -r '.[][].SpotPrice' | jq -s max

# TODO: ensure only one key is created if it already exists
private-key-describe: ## list key pairs
	@aws ec2 describe-key-pairs | jq -r '.KeyPairs[].KeyName'

private-key-generate: ## generate key
	@ssh-keygen -q -t rsa -b 4096 -N "" -C "theboardcompany" -f /tmp/theboardcompany

private-key-import: ## import keypair
	@aws ec2 import-key-pair \
	  --key-name theboardcompany \
	  --public-key-material file:///tmp/theboardcompany.pub

private-key-move: ## move private key
	@mkdir -p ssh && mv /tmp/theboardcompany* ./ssh/

private: private-key-generate private-key-import private-key-move

# TODO: code to help with private key
config-bucket : ## first time setup to ensure application config bucket exists
	@BUCKET="$$(aws s3 --profile $$CLIENT ls | grep $$CLIENT-config)"; \
	if [[ $$? -eq 1 ]]; then \
		echo "$(BUCKET)"; \
		aws s3 --profile $(CLIENT) mb s3://$(CLIENT)-config; \
	else \
		echo "bucket already exists"; \
	fi
	@echo "ensure versioning is enabled"
	@aws s3api --profile $(CLIENT) put-bucket-versioning \
	  --bucket $(CLIENT)-config \
		--versioning-configuration Status=Enabled

# Terraform shortcuts
# ------------------------

init: ## terraform: initialize env
	@cd $(ENVDIR); \
	  terraform init

get: ## terraform: configure modules
	@cd $(ENVDIR); \
	  terraform get -update

plan: ## terraform: output plan to file
	@cd $(ENVDIR); \
	  terraform plan -out terraform.tfplan

apply: ## terraform: apply outputed plan
	@cd $(ENVDIR); \
	  terraform apply terraform.tfplan

output: ## terraform: print all outputs
	@cd $(ENVDIR); \
	  terraform output

destroy: ## terraform: destroy environment
	@cd $(ENVDIR); \
		aws s3 rb s3://tbc-bastion-logs --force; \
	  terraform destroy --force

# Lambda
# ------------------------

LAMBDAS = alb-logcollector
lambda:
	@echo ">>> building lambdas <<<"
	@$(foreach lambda,$(LAMBDAS),\
		(cd terraform/modules/aws/lambdas/$(lambda)/files; \
		if [ $$(find -s . ! -name "*.md5" -type f -exec md5 {} \; | md5) == $$(cat .md5) ]; then \
			echo "not building $(lambda)"; \
		else \
		rm ../build.zip; \
		echo "building $(lambda)"; \
		if test -f "package.json"; then npm install --production --loglevel=http;fi; \
		echo "zipping $(lambda)"; \
		zip -q -r ../build.zip . -x package.json -x package-lock.json; \
		echo $$(find -s . ! -name "*.md5" -type f -exec md5 {} \; | md5) > .md5; \
		fi);)

# Docker
# ------------------------
DOCKERS = letsencrypt
docker:
	@echo ">>> building docker images <<<"
	@$(foreach docker,$(DOCKERS),\
		(cd terraform/modules/aws/ecs-spotfleet-$(docker)/docker;\
		    if [ $$(find -s . ! -name "*.md5" -type f -exec md5 {} \; | md5) == $$(cat .md5) ]; then \
				echo "not building $(docker)"; \
			else \
				echo ">>> building $(docker) <<<"; \
				docker build . -t docker.lzops.io/lrnz/$(docker):latest; \
				echo ">>> pushing $(docker) <<<"; \
				docker push docker.lzops.io/lrnz/$(docker):latest; \
				echo $$(find -s . ! -name "*.md5" -type f -exec md5 {} \; | md5) > .md5; \
			fi);)

# Notes:
# ------------------------

todo: ## list all TODO, FIXME, and FUTURE code tags
	@leasot --filetype .yaml --tags FUTURE *

# PHONY (non-file) Targets
# ------------------------
.PHONY: all plan apply output lambda
# `make help` -  see http://marmelab.com/blog/2016/02/29/auto-documented-makefile.html
# ------------------------------------------------------------------------------------

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

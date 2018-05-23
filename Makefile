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
STAGING = base ops dev
ALLENVS = $(STAGING) production

# Check ENV name
# ------------------------
# this is defaulted to dev in .envrc
ifeq ($(filter $(TBCENV),$(ALLENVS)),)
$(error Valid TBCENV values include: $(ALLENVS))
endif

# Set target directory
# ------------------------
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

output: ## terraform: print environment outputs
	@cd $(ENVDIR); \
	  terraform output

destroy: ## terraform: destroy environment
	@cd $(ENVDIR); \
	  terraform destroy --force

setup:
	@$(foreach env,$(STAGING),\
		echo ">>> building $(env) environment <<<"; \
		export TBCENV=$(env); echo $(TBCENV); export -n TBCENV; \
	)

# set TBCENV=$(env); make init plan apply; unset TBCENV; \

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

# SSH Key
# ------------------------

private-key-generate: ## generate key
	@ssh-keygen -q -t rsa -b 4096 -N "" -C "theboardcompany" -f /tmp/theboardcompany

private-key-import: ## import keypair
	@aws ec2 import-key-pair \
		--key-name theboardcompany \
		--public-key-material file:///tmp/theboardcompany.pub

private-key-move: ## move private key
	@mkdir -p ssh && mv /tmp/theboardcompany* ./ssh/

ssh: private-key-generate private-key-import private-key-move

# Notes:
# ------------------------

todo: ## list all TODO, FIXME, and FUTURE tags
	@leasot --filetype .yaml --tags FUTURE *

# PHONY (non-file) Targets
# ------------------------
.PHONY: all aws bucket spot init get plan apply output destroy lambda docker
# `make help` -  see http://marmelab.com/blog/2016/02/29/auto-documented-makefile.html
# ------------------------------------------------------------------------------------

help: ## show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

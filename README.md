# The Board Company

## Challenge
Tasked with setting up an Application Load Balancer (ELBv2) that outputs logs to S3 I chose to use S3 Event Notifications to trigger a Lambda function that:

- unzips gz file
- transforms json
- POST to log collector

Useful Links:

- URL: https://challenge.tbc.vasandani.me/
- Log Collector: https://challenge-logcollector.herokuapp.com/log/view/theboardcompany

## Setup

1) Manually create a new zone (i.e. tbc.vasandani.me) this will become the base domain
2) Copy the NS records from tbc.vasandani.me and create a new record with type Name Server and the value the NS records you copied from step 1.
3) Update [terraform/envs/staging/base/terraform.tfvars](https://github.com/davidneudorfer/theboardcompany-challenge/blob/master/terraform/envs/staging/base/terraform.tfvars#L9) with the base domain
5) Generate a new key by running `make ssh`. This will geneate a new SSH key named "theboardcomapny", upload it to AWS, and place it in a folder named ssh in the current directory.
6) run `make bucket` to setup an S3 bucket named `theboardcomapny-terraform` to store terraform config.
6) Run `TBCENV=base make init plan apply` to build out a terraform state that includes dns zone info and ACM certificate info.
5) Run `TBCENV=ops make init plan apply` to build out a vpc that contains:
    - Bastion Host
        - AutoScaled t2.nano
        - Network Load Balancer
    - Docker Registry
        - Elastic Container Service
        - SpotFleet
5) Run `TBCENV=dev make init plan apply` to build out a vpc that contains:
    - Bastion Host
    - Challenge App
        - Elastic Container Service
        - SpotFleet
        - Application Load Balancer
        - ALB Logging Lambda

## Terraform

This repo contains all the code to provision all environments. To speed up development offical and community modules from the Terraform Registry were used.

## Lambda
Modified [aws-sample/amazon-elasticsearch-lambda-samples](https://github.com/aws-samples/amazon-elasticsearch-lambda-samples/blob/master/src/s3_lambda_es.js) to extract gzip'd log files and push modified json to custom endpoint.

From the source:
> To avoid loading an entire (typically large) log file into memory, this is implemented as a pipeline of filters, streaming log data from S3 to the [log collector].
> - Flow: S3 file stream -> Log Line stream -> Log Record stream -> [log collector]

## Make

run `make` to see all available commands.

# The Board Company

## Challenge
Tasked with setting up an Application Load Balancer (ELBv2) that outputs logs to S3 I chose to use S3 Event Notifications to trigger a Lambda function that:

- unzips gz file
- transforms json
- POST to log collector

Useful Links:

- URL: https://challenge.tbc.vasandani.me/
- Bucket: challenge-dev-alb-logs
- Log Collector: https://challenge-logcollector.herokuapp.com/log/view/theboardcompany

## Setup

1) manually create a new zone (i.e. tbc.vasandani.me) this will become the base domain
2) copy the NS records from tbc.vasandani.me and create a new record with type Name Server and the value the NS records you copied from step 1.
3) update terraform/envs/staging/base/terraform.tfvars with the base domain
4) run `TBCENV=base make plan apply`
5) 

## Terraform

This repo contains all the code to provision all environments. To speed up development offical and community modules from the Terraform Registry were used.

## AWS

ops  
dev

## Lambda
Modified [aws-sample/amazon-elasticsearch-lambda-samples](https://github.com/aws-samples/amazon-elasticsearch-lambda-samples/blob/master/src/s3_lambda_es.js) to extract gzip'd log files and push modified json to custom endpoint.

From the source:
> To avoid loading an entire (typically large) log file into memory, this is implemented as a pipeline of filters, streaming log data from S3 to the [log collector].
> - Flow: S3 file stream -> Log Line stream -> Log Record stream -> [log collector]

## Make

run `make` to see all available commands.

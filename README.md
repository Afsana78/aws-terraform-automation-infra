
# AWS Infrastructure & DevSecOps Technical Assessment

This repository contains the complete solution for the AWS DevOps & Terraform Assessment.

## Repository Layout

* **'main.tf'**: Module provisioning 5 EC2 instances using 'for_each' with custom lifecycle rules.
* **'variables.tf'**: Input definitions and parameter configurations for all resources.
* **'outputs.tf'**: Outputs mapping instance names to IDs and private IP addresses.
* **'backend.tf'**: Remote S3 state backend with DynamoDB locking configuration.
* **'iam.tf'**: Multi-account IAM role structures, groups, and cross-account access rules.
* **'task4_ci_policy.json'**: Custom least-privilege IAM policy written for CI/CD pipeline deployments.
* **'NOTES.md'**: Detailed architectural reasoning, bug fixes, and security explanations.
  

## Usage

1. Initialize Terraform plugins and remote backend:
2. ## Usage

1. Initialize Terraform plugins and remote backend:
   '''bash
   terraform init
   '''

2. Validate the configuration syntax:
   '''bash
   terraform validate
   '''

3. Generate and inspect execution plan:
   '''bash
   terraform plan
   '''

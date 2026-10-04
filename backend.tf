# terraform {
#   backend "s3" {
#     bucket       = "my-company-tfstate-bucket"
#     key          = "environments/prod/terraform.tfstate"
#     region       = "us-east-1"
#     use_lockfile = true
#     encrypt      = true
#   }
# }

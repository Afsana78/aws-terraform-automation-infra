
variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "environment" {
  type    = string
  default = "prod"
}

variable "owner" {
  type    = string
  default = "devops-team"
}

variable "instances" {
  description = "Map of EC2 configurations driven by a single variable"
  type = map(object({
    ami           = string
    instance_type = string
    root_gb       = number
    volume_type   = string
    iops          = optional(number)
    key_name      = string
    prevent_destroy = optional(bool, false)
  }))
  default = {
    "web-app" = {
      ami             = "ami-0c55b159cbfafe1f0"
      instance_type   = "t3.micro"
      root_gb         = 20
      volume_type     = "gp3"
      key_name        = "web-key"
      prevent_destroy = false
    },
    "api-server" = {
      ami             = "ami-0c55b159cbfafe1f0"
      instance_type   = "t3.small"
      root_gb         = 30
      volume_type     = "gp3"
      key_name        = "api-key"
      prevent_destroy = false
    },
    "db-primary" = {
      ami             = "ami-0c55b159cbfafe1f0"
      instance_type   = "r5.large"
      root_gb         = 100
      volume_type     = "io2"
      iops            = 3000
      key_name        = "db-key"
      prevent_destroy = true # Safeguarded instance
    },
    "cache-node" = {
      ami             = "ami-0c55b159cbfafe1f0"
      instance_type   = "m5.large"
      root_gb         = 40
      volume_type     = "gp3"
      key_name        = "cache-key"
      prevent_destroy = false
    },
    "worker-node" = {
      ami             = "ami-0c55b159cbfafe1f0"
      instance_type   = "c5.large"
      root_gb         = 50
      volume_type     = "gp2"
      key_name        = "worker-key"
      prevent_destroy = false
    }
  }
}

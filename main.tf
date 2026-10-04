
provider "aws" {
  region = var.aws_region
}

# Standard instances without destruction protection
resource "aws_instance" "standard" {
  for_each = {
    for k, v in var.instances : k => v if !v.prevent_destroy
  }

  ami           = each.value.ami
  instance_type = each.value.instance_type
  key_name      = each.value.key_name

  root_block_device {
    volume_size           = each.value.root_gb
    volume_type           = each.value.volume_type
    iops                  = each.value.iops
    delete_on_termination = true
  }

  tags = {
    Name        = each.key
    Environment = var.environment
    Owner       = var.owner
  }
}

# Protected instance (db-primary) with explicit lifecycle block
resource "aws_instance" "protected" {
  for_each = {
    for k, v in var.instances : k => v if v.prevent_destroy
  }

  ami           = each.value.ami
  instance_type = each.value.instance_type
  key_name      = each.value.key_name

  root_block_device {
    volume_size           = each.value.root_gb
    volume_type           = each.value.volume_type
    iops                  = each.value.iops
    delete_on_termination = true
  }

  lifecycle {
    prevent_destroy = true
  }

  tags = {
    Name        = each.key
    Environment = var.environment
    Owner       = var.owner
  }
}


locals {
  all_instances = merge(aws_instance.standard, aws_instance.protected)
}

output "instance_ids" {
  description = "Map of instance name -> instance ID"
  value       = { for k, v in local.all_instances : k => v.id }
}

output "instance_private_ips" {
  description = "Map of instance name -> private IP"
  value       = { for k, v in local.all_instances : k => v.private_ip }
}

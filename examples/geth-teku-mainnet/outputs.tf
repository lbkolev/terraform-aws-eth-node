output "key_pair" {
  value       = module.key_pair
  description = "Details around the SSH key pair for the manager node"
  sensitive   = true
}

output "node" {
  value       = module.nodes
  description = "Details around the EC2"
}

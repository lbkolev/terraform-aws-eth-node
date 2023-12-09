output "ebs" {
  value       = aws_ebs_volume.this
  description = "EBS volumes created for the client(s)"
}

output "security_group" {
  value       = aws_security_group.this
  description = "Security group created for the client(s)"
}

output "compute" {
  value       = aws_autoscaling_group.this
  description = "Compute created for the client(s)"
}

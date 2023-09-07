output "ebs" {
  value       = aws_ebs_volume.this
  description = "EBS volumes created for the client(s)"
}

output "security_group" {
  value       = aws_security_group.this
  description = "Security group created for the client(s)"
}

output "ec2" {
  value       = aws_instance.this
  description = "EC2 instance created for the client(s)"
}

output "ebs_attachment" {
  value       = aws_volume_attachment.this
  description = "EBS volume attachment(s) created for the client(s)"
}

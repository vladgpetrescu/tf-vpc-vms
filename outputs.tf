output "public_vm_ip_address" {
  description = "Elastic IP attached to the public VM"
  value       = aws_eip.public_vm_eip.public_ip
}

output "private_vm_ip_address" {
  description = "The AWS private IP address for the private VM"
  value       = try(aws_instance.private[0].private_ip, "Private VM not created - set create_private_resources = true")
}

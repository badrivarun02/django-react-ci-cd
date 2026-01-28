output "ec2_public_ip" {
  description = "Public IP of the EC2 instance"
  value       = module.ec2.public_ip
}

output "ssh_command" {
  description = "SSH command to connect"
  value       = "ssh -i ${var.project_name}-key.pem ubuntu@${module.ec2.public_ip}"
}


output "frontend_url" {
  description = "URL to React frontend"
  value       = "http://${module.ec2.public_ip}:80"
}
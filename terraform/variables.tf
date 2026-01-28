variable "aws_region" {
  description = "AWS Region"
  type        = string
  default     = "ap-south-1" # Change to your preferred region
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "project_name" {
  description = "Project name for tagging"
  type        = string
  default     = "hello-world-app"
}

variable "repo_url" {
  description = "GitHub repo URL to clone on EC2"
  type        = string
  default     = "https://github.com/yourusername/your-repo.git" # ← change
}

variable "repo_branch" {
  description = "Branch to checkout"
  type        = string
  default     = "main"
}
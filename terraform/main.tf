# Data sources for dynamic values
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical (official Ubuntu owner)

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"] # 24.04 LTS (Noble) – or use "jammy-22.04" for 22.04
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# Generate SSH key pair automatically (no manual .pem needed)
resource "tls_private_key" "ec2_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "ec2_key" {
  key_name   = "${var.project_name}-key"
  public_key = tls_private_key.ec2_key.public_key_openssh

  provisioner "local-exec" {
    command = <<EOT
      echo '${tls_private_key.ec2_key.private_key_pem}' > ./${var.project_name}-key.pem
      chmod 400 ./${var.project_name}-key.pem
    EOT
  }
}

# Security Group via module
module "sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 5.2"

  name        = "${var.project_name}-sg"
  description = "Allow SSH, HTTP, HTTPS"
  vpc_id      = data.aws_vpc.default.id

  ingress_with_cidr_blocks = [
    # SSH – restrict in production
    {
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      description = "SSH access"
      cidr_blocks = "49.43.230.35/32" # or your IP for better security
    },

    # Public ports – only these should be open to the world
    {
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      description = "HTTP"
      cidr_blocks = "0.0.0.0/0"
    },
    {
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      description = "HTTPS"
      cidr_blocks = "0.0.0.0/0"
    },

  ]

  egress_rules = ["all-all"]
}

# EC2 via module + user_data bootstrap
module "ec2" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "~> 5.7"

  name                   = "${var.project_name}-ec2"
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  key_name               = aws_key_pair.ec2_key.key_name
  vpc_security_group_ids = [module.sg.security_group_id]
  subnet_id              = data.aws_subnets.default.ids[0]

  # Bootstrap script: Install Docker, Compose, clone repo, start app
  user_data = templatefile("${path.module}/user_data.sh.tpl", {
    repo_url    = var.repo_url
    repo_branch = var.repo_branch
  })

  tags = {
    Name        = "${var.project_name}-ec2"
    Environment = "demo"
  }
}
provider "aws" {
  region = "us-east-2"
}

data "aws_ami" "ubuntu" {
  most_recent      = true
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }
  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
  owners = ["099720109477"] # Canonical
}

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"
  
  name = "netology-diplom-vpc"
  cidr = "10.0.0.0/16"

  azs             = ["us-east-2c"]
  public_subnets  = ["10.0.101.0/24"]

  enable_nat_gateway = true
  enable_vpn_gateway = false

  tags = {
    Terraform = "true"
    Environment = "stage"
  }
}

resource "aws_security_group" "netology-diplom-sg" {
  name   = "netology-sg"
  vpc_id = module.vpc.vpc_id

  egress {
    protocol    = -1
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group_rule" "ssh" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.netology-diplom-sg.id
}

resource "aws_security_group_rule" "http" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.netology-diplom-sg.id
}


resource "aws_security_group_rule" "icmp" {
  type              = "ingress"
  from_port         = -1
  to_port           = -1
  protocol          = "icmp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.netology-diplom-sg.id
}

resource "aws_key_pair" "diplom-key" {
  key_name   = "diplom-key"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC3jPcGUpn2D2hOZ6m2BIG1FPux6vMmvVUqCElHbJCBfiIFIeqXl+9s+uzL7z4lMz92+fhExy+SfivSC2sMRgbLF6odvjoziGjfFb9jaWdntUqNPOd5MjSxSHLztq0N08E//cg5SzqaVghW/Fjom8QhEYBlzPZ7rNbs3fVwRN4MXpC8E1IkUQMwJU6D0bzERSDw6kK6y7XQ7Qm6xo/QFPaz7YWlrI07Efgjz0GY3lHv5MFlgMKiIZdIE7BGoAP8m9VxyvfNB1aXquoYtktOoVgMVXbNsGjboMzVyyHqBD1HFBhebzuvybOFyttoQ68x2ZXdfNTHYp7I9nLfrDDP8wFl ecriptor@CAB-WSM-0009889"
}


resource "aws_instance" "diplom-vm" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3.small"
  key_name  = "diplom-key"
  count = 3
  subnet_id = module.vpc.public_subnets[0]
  security_groups = [aws_security_group.netology-diplom-sg.id]
}

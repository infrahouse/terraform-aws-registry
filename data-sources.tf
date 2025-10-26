data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

data "aws_ami" "ecs_latest" {
  most_recent = true

  filter {
    name   = "name"
    values = ["amzn2-ami-ecs-hvm-*"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["591542846629"] # Amazon
}

data "aws_subnet" "frontend_subnet" {
  id = var.subnets_frontend[0]
}

data "aws_internet_gateway" "main" {
  filter {
    name   = "attachment.vpc-id"
    values = [data.aws_subnet.frontend_subnet.vpc_id]
  }
}

data "aws_route53_zone" "zone" {
  zone_id = var.zone_id
}

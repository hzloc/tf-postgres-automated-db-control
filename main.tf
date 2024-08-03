terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }
  backend "s3" {
    bucket         = "tf-states-hzlocs-2332"
    dynamodb_table = "tf-state"
    key            = "hzloc_tf-postgres-automated-db-control.tfstate"
    region         = "eu-central-1"
  }
  required_version = ">=1.2.0"
}

provider "aws" {
  region = "eu-central-1"
}

data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_vpc" "vpc_database" {
  cidr_block           = var.vpc_cidr_block
  enable_dns_hostnames = true
  tags = {
    Name = "vpc_database"
  }
}

resource "aws_internet_gateway" "postgres_igw" {
  vpc_id = aws_vpc.vpc_database.id
  tags = {
    Name = "postgres_igw"
  }
}

resource "aws_subnet" "postgres_public_subnet" {
  vpc_id            = aws_vpc.vpc_database.id
  count             = var.subnet_count.public
  cidr_block        = var.public_subnet_cidr_blocks[count.index]
  availability_zone = data.aws_availability_zones.available.names[count.index]
  tags = {
    Name = "db_public_subnets_${count.index}"
  }
}

resource "aws_subnet" "postgres_private_subnet" {
  vpc_id            = aws_vpc.vpc_database.id
  count             = var.subnet_count.private
  cidr_block        = var.private_subnet_cidr_blocks[count.index]
  availability_zone = data.aws_availability_zones.available.names[count.index]
  tags = {
    Name = "db_private_subnets_${count.index}"
  }
}

resource "aws_route_table" "postgres_public_rt" {
  vpc_id = aws_vpc.vpc_database.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.postgres_igw.id
  }
}
resource "aws_route_table_association" "public" {
  route_table_id = aws_route_table.postgres_public_rt.id
  count          = var.subnet_count.public
  subnet_id      = aws_subnet.postgres_public_subnet[count.index].id
}

resource "aws_route_table" "postgres_private_rt" {
  vpc_id = aws_vpc.vpc_database.id
}

resource "aws_route_table_association" "private" {
  route_table_id = aws_route_table.postgres_private_rt.id
  count          = var.subnet_count.private
  subnet_id      = aws_subnet.postgres_private_subnet[count.index].id
}

resource "aws_security_group" "tutorial_ec2_sg" {
  name        = "tutorial_ec2_sg"
  description = "Security group to connect postgres through ec2"
  vpc_id      = aws_vpc.vpc_database.id

  ingress {
    description = "Allow all traffic through HTTP"
    from_port   = "80"
    to_port     = "80"
    protocol    = "tcp"
    cidr_blocks = ["${var.whitelisted_ip}/32"]
  }

  ingress {
    description = "Allow port 9000 to outside"
    from_port   = "9000"
    to_port     = "9000"
    protocol    = "tcp"
    cidr_blocks = ["${var.whitelisted_ip}/32"]
  }

  ingress {
    description = "Allow ssh from my computer"
    from_port   = "22"
    to_port     = "22"
    protocol    = "tcp"
    cidr_blocks = ["${var.whitelisted_ip}/32"]
  }

  egress {
    description = "Allow all outbound connections"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "postgres_ec2_sg"
  }
}

resource "aws_ecr_repository" "db_migration_repository" {
  name                 = var.ecr_name_repo
  image_tag_mutability = "MUTABLE"
}

resource "aws_security_group" "tutorial_db_sg" {
  name        = "tutorial_db_sg"
  description = "Security group to connect postgres"
  vpc_id      = aws_vpc.vpc_database.id

  ingress {
    description     = "Allow connection through ec2"
    from_port       = "5432"
    to_port         = "5432"
    protocol        = "tcp"
    security_groups = [aws_security_group.tutorial_ec2_sg.id]
  }

  tags = {
    Name = "postgres_db_sg"
  }
}

resource "aws_db_subnet_group" "postgres_sg" {
  name        = "postgres_subnet_group"
  description = "Subnet group for the postgres db"
  subnet_ids  = [for subnet in aws_subnet.postgres_private_subnet : subnet.id]
}

resource "aws_db_instance" "postgres_db" {
  instance_class              = var.settings.database.instance_class
  allocated_storage           = var.settings.database.allocated_storage
  allow_major_version_upgrade = var.settings.database.allow_major_version_upgrade
  auto_minor_version_upgrade  = true
  db_name                     = var.settings.database.db_name
  engine                      = var.settings.database.engine
  engine_version              = var.settings.database.engine_version
  password                    = var.db_password
  username                    = var.db_username
  db_subnet_group_name        = aws_db_subnet_group.postgres_sg.id
  vpc_security_group_ids      = [aws_security_group.tutorial_db_sg.id]
  skip_final_snapshot         = true
}
data "aws_key_pair" "tutorial_kp" {
  key_name           = "tutorial_kp"
  include_public_key = true

  filter {
    name   = "key-name"
    values = ["tutorial_kp"]
  }
}

data "aws_ami" "ubuntu" {
  most_recent = true
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
  owners = ["099720109477"]
}

resource "aws_instance" "postgres_ec2_instance" {
  count                  = var.settings.app.count
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.settings.app.instance_type
  subnet_id              = aws_subnet.postgres_public_subnet[count.index].id
  key_name               = data.aws_key_pair.tutorial_kp.key_name
  vpc_security_group_ids = [aws_security_group.tutorial_ec2_sg.id]
  tags = {
    Name = "postgres_ec2_instance_${count.index}"
  }
  associate_public_ip_address = true
}

resource "aws_iam_role" "db_migrate_lambda" {
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid    = "DynamoMigrator",
        Effect = "Allow",
        Action : [
          "sts:AssumeRole",
          "ecr:BatchGetImage",
          "ecr:GetDownloadUrlForLayer"
        ],
        Principal = {
          Service = "lambda.amazonaws.com"
        },
      }
    ]
  })
}

resource "aws_iam_role_policy" "dynamo_db_migrator_policy" {
  role = aws_iam_role.db_migrate_lambda.id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = {
      Sid    = "Dd"
      Effect = "Allow"
      Action = [
        "ec2:*",
        "lambda:*",
        "ecr:*"
      ],
      Resource = "*"
    }
  })

}

data "aws_ecr_image" "service_image" {
  repository_name = aws_ecr_repository.db_migration_repository.name
  image_tag       = "latest"
}

resource "aws_lambda_function" "db_migration_lambda" {
  function_name = "migrate_db"
  role          = aws_iam_role.db_migrate_lambda.arn
  image_uri     = "${aws_ecr_repository.db_migration_repository.repository_url}:${data.aws_ecr_image.service_image.image_tag}"
  handler       = "lambda_function.handler"
  runtime       = "python3.10"
  package_type  = "Image"

  vpc_config {
    security_group_ids = ["${aws_security_group.tutorial_ec2_sg.id}"]
    subnet_ids         = ["${aws_subnet.postgres_public_subnet[0].id}"]

  }
}
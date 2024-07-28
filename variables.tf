variable "vpc_cidr_block" {
  type        = string
  default     = "10.0.0.0/16"
  description = "CIDR block for vpc_db"
}

variable "subnet_count" {
  description = "Number of subnets"
  type        = map(number)
  default = {
    public  = 1
    private = 2
  }
}

variable "public_subnet_cidr_blocks" {
  type        = list(string)
  description = "Available CIDR blocks for public subnets"
  default = [
    "10.0.1.0/24",
    "10.0.2.0/24",
    "10.0.3.0/24",
    "10.0.4.0/24"
  ]
}

variable "private_subnet_cidr_blocks" {
  type        = list(string)
  description = "Available CIDR blocks for private subnets"
  default = [
    "10.0.101.0/24",
    "10.0.102.0/24",
    "10.0.103.0/24",
    "10.0.104.0/24"
  ]
}

variable "settings" {
  description = "Settings for the RDS and EC2"
  type        = map(any)
  default = {
    "database" = {
      engine                      = "postgres"
      allocated_storage           = 10
      engine_version              = "14.12"
      allow_major_version_upgrade = false
      auto_minor_version_upgrade  = true
      instance_class              = "db.t3.micro"
      db_name                     = "fddomain"
    },
    "app" = {
      instance_type = "t2.micro"
      count         = 1
    }
  }
}

variable "db_username" {
  type        = string
  description = "DB username"
  sensitive = true
}

variable "db_password" {
  type        = string
  sensitive = false
  description = "DB master password"
}

variable "whitelisted_ip" {
  sensitive   = true
  type        = string
  description = "Whitelisted IPS"
}
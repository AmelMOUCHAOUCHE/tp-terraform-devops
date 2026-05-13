variable "aws_region" {
  description = "Région AWS cible"
  type        = string
  default     = "eu-west-3"
}

variable "project_name" {
  description = "Nom du projet"
  type        = string
}

variable "environment" {
  description = "Environnement (dev, staging, prod)"
  type        = string
  default     = "dev"
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "L'environnement doit être dev, staging ou prod."
  }
}

variable "owner" {
  description = "Nom ou email du responsable"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR du VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidr" {
  description = "CIDR du subnet public"
  type        = string
  default     = "10.0.1.0/24"
}

variable "instance_type" {
  description = "Type d'instance EC2"
  type        = string
  default     = "t3.micro"
}

variable "my_ip" {
  description = "Votre IP publique (format x.x.x.x/32)"
  type        = string
}

variable "db_password" {
  description = "Mot de passe de la base de données"
  type        = string
  sensitive   = true
}

locals {
  instance_type = {
    dev  = "t3.micro"
    prod = "t3.small"
  }
}


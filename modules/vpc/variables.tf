# modules/vpc/variables.tf

variable "project_name" {
  description = "Nome do projeto"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block para a VPC"
  type        = string
}

variable "availability_zones" {
  description = "Lista de Availability Zones para usar"
  type        = list(string)
}

variable "create_nat_gateway" {
  description = "Se deve criar um NAT Gateway"
  type        = bool
  default     = false
}

variable "create_private_subnets" {
  description = "Se deve criar subnets privadas"
  type        = bool
  default     = false
}
variable "aws_access_key" {
  description = "AWS access key"
  type        = string
  sensitive   = true
}

variable "aws_secret_key" {
  description = "AWS secret key"
  type        = string
  sensitive   = true
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "eu-central-1"
}

variable "cidr" {
  description = "VPC CIDR"
  type        = string
  default     = "10.0.0.0/16"
}

variable "subnets" {
  description = "List of subnet CIDRs"
  type        = list(string)
  default     = ["10.0.0.0/24", "10.0.1.0/24"]
}

variable "availability_zones" {
  description = "List of availability zones for subnets"
  type        = list(string)
  default     = ["eu-central-1a", "eu-central-1b"]
}

variable "cpu" {
  description = "ECS task CPU unit provisioning (number in vCPUs, for example: 1024)"
  type        = string
  default     = "512"
}

variable "memory" {
  description = "ECS task memory unit provisioning (number in MiB, for example: 2048)"
  type        = string
  default     = "1024"
}

variable "docker_image" {
  description = "Docker image to deploy on ECS"
  type        = string
  default     = "rtsiomenko/lemonade-assignment:latest"
}

variable "application_port" {
  description = "Port for application"
  type        = number
  default     = 8080
}
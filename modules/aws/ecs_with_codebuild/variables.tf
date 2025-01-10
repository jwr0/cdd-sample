variable "environment_name" {
  description = "The name of the environment to create."
  type        = string
}

variable "cidr_block" {
  description = "The CIDR block to use for the VPC."
  type        = string
  default     = "10.0.0.0/16"
}
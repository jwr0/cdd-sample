variable "environment_name" {
  description = "The name of the environment to create."
  type        = string
}

variable "cidr_block" {
  description = "The CIDR block to use for the VPC."
  type        = string
  default     = "10.0.0.0/16"
}

variable "on_prem_ip_address" {
  description = "The publicly routable IP address of the on-prem network (or of your local laptop). Must be a valid CIDR (eg. if its a single IP address, it should end in /32)."
  type        = string
}

variable "launch_production_ec2_instance" {
  description = "Whether or not to launch an EC2 instance in which similates other servers running in AWS which hit the ECS services built by this module."
  type        = bool
  default     = false
}
variable "env" {
  description = "Environment Identifier"
}

variable "ami_id" {
  description = "AMI ID to be used"
}

variable "instance_type" {
  description = "EC2 Instance Type"
}

variable "min_instance_count" {
  description = "Min. Number of Instance"
}

variable "max_instance_count" {
  description = "Max. Number of Instance"
}

variable "ssh_public_key" {
  description = "Public SSH Key Used by the Instance"
}

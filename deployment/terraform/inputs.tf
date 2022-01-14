variable "env" {
  description = "Environment identifier"
}

variable "ec2_instance_type" {
  description = "EC2 instance type"
  default     = "t3a.micro"
}

variable "rds_instance_class" {
  description = "RDS instance class"
  default     = "db.t3.micro"
}

variable "min_instance_count" {
  description = "Min. number of instances"
  default     = 2
}

variable "max_instance_count" {
  description = "Max. number of instance"
  default     = 2
}

variable "rds_allocated_storage" {
  description = "Size of allocated storage for RDS (GB)"
  default     = 10
}

variable "lambda_filename" {
  description = "Location of the lambda deployment zip"
}

variable "lambda_timeout" {
  description = "Timeout duration of the lambda service (seconds)"
  default     = 240
}

variable "grader_timeout" {
  description = "Timeout duration of the grader (milliseconds)"
  default     = 15000
}

variable "api_ssh_key_name" {
  description = "SSH key that the API instances should authorise (must already exist in AWS)"
}

variable "assets_bucket" {
  description = "The S3 bucket containing the story assets."
}

variable "config_bucket" {
  description = "The S3 bucket containing the backend configuration (cadet.exs)."
}

variable "config_object" {
  description = "The key of (i.e. path to) the backend configuration in config_bucket, with no leading /."
}

variable "cadet_release_url" {
  description = "The URL to the Cadet release tarball"
  default     = ""
}

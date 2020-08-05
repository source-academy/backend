terraform {
  backend "s3" {
    bucket  = "cadet-terraform-state"
    key     = "cadet.tfstate"
    region  = "ap-southeast-1"
    encrypt = "true"
    acl     = "private"
  }
}

provider "aws" {
  region  = "ap-southeast-1"
  profile = "cadet"
  version = "~> 3.0"
}

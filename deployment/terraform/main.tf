terraform {
  backend "s3" {
    bucket  = "cadet-terraform-state"
    key     = "cadet.tfstate"
    region  = "ap-southeast-1"
    encrypt = "true"
    acl     = "private"
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }

    random = {
      source  = "hashicorp/random"
      version = "~> 3.1"
    }
  }
}

provider "aws" {
  region = "ap-southeast-1"
}

data "aws_region" "current" {}

data "aws_caller_identity" "current" {}

locals {
  account_id = data.aws_caller_identity.current.account_id
  region     = data.aws_region.current.name
}

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
  version = "~> 1.20"
}

module "staging" {
  source = "./cadet"

  env                = "stg"
  ami_id             = "ami-02fe9d7e"
  instance_type      = "t2.micro"
  min_instance_count = 2
  max_instance_count = 2
  ssh_public_key     = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDUWVRkdWFKgcGCdiha2Xpmfg68M+nbrUuuK3zZ07Fyf+VeW3cuwUcyfhp7nyoFP4WpsWO+0sEMpbd0t5krxvAjkhn2llBJrMhqV1GfT/NSi+i0vLp6CNWEGZntUUNnIt9+hmceD5W3BmGfyNMVBH+RVLVDquo6YaiiwzYSg4pfJO6pikrvmvHnOrRZ5YEZmSeMmc1vHeDxL1UqJDzoizvH3eXVixyMa+6EMOx2iDzWXJLlJuEU8FV5nSjmLa6Ld7jbLWc0rUUvnGYp+KwlpZMLJ3+bgdAgyzKMO7pAlr65wO5qi18Jq2mppFaNdUgv9j1xVe0yeyJ06vu70S6e7g4FFfHV2ov/Fu+ADKwmIsTYVBwVlctqok9LoF1rDc+J5LCmyoEoYNZbgcIPjYZOxm6R/OJ8IzTSRzHP8FinychphA3mM70QPTREQdL+AVzM28IA4g39zQA/dVrRilXuj2RB+kpM68hLhfHdpvYJXMcgHisOuuHDvkVkMz111hwORah7PJrFN7QquXrj0gYbKrM2rvExxiTxHk9wH2MPdYEY2l6nSHjgwHWO7EpSOg4nTwFSOqe01k5VtE1V9BthKbty8OvP8I8ZaosGJix/XxV/QJHAC+C2DB8RQorAW/0ZWRPRgN9B3mTIfkjtJMPLUxeI8r9dtrMJmMqMPzW07BlzVQ== source-academy@comp.nus.edu.sg"
}

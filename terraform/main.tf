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

  env                   = "stg"
  ami_id                = "ami-573f032b"
  ec2_instance_type     = "t2.micro"
  rds_instance_class    = "db.t2.micro"
  min_instance_count    = 2
  max_instance_count    = 2
  rds_allocated_storage = 10
  rds_password          = "postgres"
  ssh_public_key        = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQC5LX23pkdYNFlXdAr/24hND0YUNynL1LCd4hQQxGGx0LBcrKOsHekpXTh091eFk7DvXQpq828VdnZdd6lTDrdmR9j9Uf5xRpRA81TNHC3HhDxgdfJleoMFu8eF44WPtt6ItxqC2ajP2Lw3UJgEctTpUyqlOrETRxhMpMNzxhIgLw9ygesiuGdtN6LaItW3R2Ec8pBxboPrMxBWze++CAG5mpRinI9BuONxBG1DAOQFitcLgGu+p9zpwJcNYRJwrZDlG98g+BsU2b4eEamXbQAxLdFLMHZPDCmV2a01pSfPIaQXoAKZqj/nGLPsTL1FIjZIxXNHtV7Tvvct4HtvzUaNDg1miLV6zlvFPTWMcE7dV+Mbj2aS1sl2eTcLZ5XTJr4so43nf4lH1ujxBODNCCm/68ck9wlf2GUkqyp+dPHr/ObMRcX6JSYs1c8NseSJlDmc87MCclGyxkBA+6on/3IUGsogz4gHupVJdVoR8ffWT2+jk06XLQmVIM1Th2JjV152Htn39RRmId6WuoynMCinaTaB/b5m4cEZNdttLlRmqbRCsOAr/W+BuWH9jtNi/c1qKZBJLyZE408JB9CCe+tFJgQ1hNDL+RAUKlLk6F7Xivft1nYaV58FA3U27mtMPp+RZItALTNAmA/pKfS7W4ACOhDHfpEfmUA4IzaJfruKYQ== ningyuan.sg@gmail.com"
}

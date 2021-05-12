resource "aws_s3_bucket" "sourcecasts" {
  bucket = "${var.env}-cadet-sourcecasts"
  acl    = "public-read"

  tags = {
    Name        = "${title(var.env)} Cadet Sourcecasts"
    Environment = var.env
  }
}

data "aws_s3_bucket" "assets" {
  bucket = var.assets_bucket
}

data "aws_s3_bucket" "config" {
  bucket = var.config_bucket
}

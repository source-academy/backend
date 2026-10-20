data "aws_s3_bucket" "assets" {
  bucket = var.assets_bucket
}

data "aws_s3_bucket" "config" {
  bucket = var.config_bucket
}

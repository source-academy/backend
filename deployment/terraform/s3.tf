resource "aws_s3_bucket" "sourcecasts" {
  bucket = "${var.env}-cadet-sourcecasts"
  acl    = "public-read"

  tags = {
    Name        = "${title(var.env)} Cadet Sourcecasts"
    Environment = var.env
  }
}

resource "aws_s3_bucket" "assets" {
  bucket = var.assets_bucket
  acl    = "public-read"

  tags = {
    Name = "Source Academy Assets"
  }

  cors_rule {
    allowed_headers = [
      "*"
    ]
    allowed_methods = [
      "GET",
      "HEAD"
    ]
    allowed_origins = [
      "*",
    ]
    expose_headers  = []
    max_age_seconds = 3000
  }
}

resource "aws_s3_bucket" "config" {
  bucket = var.config_bucket

  tags = {
    Name = "Source Academy Backend Configuration"
  }
}

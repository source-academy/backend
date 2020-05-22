resource "aws_s3_bucket" "sourcecasts" {
  bucket        = "${var.env}-cadet-sourcecasts"
  acl           = "public-read"
  force_destroy = true

  tags {
    Name        = "${title(var.env)} Cadet Sourcecasts"
    Environment = "${var.env}"
  }
}

resource "aws_s3_bucket" "assets" {
  bucket        = "${var.env}-cadet-assets"
  acl           = "private"
  force_destroy = true

  tags {
    Name        = "${title(var.env)} Cadet Assets"
    Environment = "${var.env}"
  }
}

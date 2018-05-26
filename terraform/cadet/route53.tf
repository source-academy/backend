resource "aws_route53_zone" "internal" {
  name    = "cadet.internal"
  comment = "Cadet Internal Zone"
  vpc_id  = "${aws_vpc.cadet.id}"

  tags {
    Name        = "${title(var.env)} Cadet Assets"
    Environment = "${var.env}"
  }
}

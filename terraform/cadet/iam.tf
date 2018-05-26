data "aws_iam_policy_document" "assets" {
  statement {
    effect = "Allow"

    actions = [
      "s3:GetObject",
    ]

    resources = [
      "${aws_s3_bucket.assets.arn}",
      "${aws_s3_bucket.assets.arn}/*",
    ]
  }
}

data "aws_iam_policy_document" "assume_policy" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_instance_profile" "api" {
  name = "${var.env}-cadet-api"
  role = "${aws_iam_role.api.name}"
}

resource "aws_iam_role" "api" {
  name               = "${var.env}-cadet-api"
  assume_role_policy = "${data.aws_iam_policy_document.assume_policy.json}"
}

resource "aws_iam_policy" "assets" {
  name        = "${var.env}-cadet-assets"
  description = "Allow Read and Write Access to Assets Bucket"
  policy      = "${data.aws_iam_policy_document.assets.json}"
}

resource "aws_iam_role_policy_attachment" "api_s3" {
  role       = "${aws_iam_role.api.name}"
  policy_arn = "${aws_iam_policy.assets.arn}"
}

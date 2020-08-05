data "aws_iam_policy_document" "assets" {
  statement {
    effect  = "Allow"
    actions = ["s3:*"]
    resources = [
      aws_s3_bucket.sourcecasts.arn,
      "${aws_s3_bucket.sourcecasts.arn}/*",
      aws_s3_bucket.assets.arn,
      "${aws_s3_bucket.assets.arn}/*",
    ]
  }
}

data "aws_iam_policy_document" "grader" {
  statement {
    effect    = "Allow"
    actions   = ["lambda:InvokeFunction"]
    resources = [aws_lambda_function.grader.arn]
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
  role = aws_iam_role.api.name
}

resource "aws_iam_role" "api" {
  name               = "${var.env}-cadet-api"
  assume_role_policy = data.aws_iam_policy_document.assume_policy.json
}

resource "aws_iam_policy" "assets" {
  name        = "${var.env}-cadet-assets"
  description = "Allows R/W access to production Sourcecasts and assets buckets"
  policy      = data.aws_iam_policy_document.assets.json
}

resource "aws_iam_policy" "grader" {
  name        = "${var.env}-cadet-grader"
  description = "Allows invocation of the prod-cadet-grader Lambda"
  policy      = data.aws_iam_policy_document.grader.json
}

resource "aws_iam_role_policy_attachment" "api_assets" {
  role       = aws_iam_role.api.name
  policy_arn = aws_iam_policy.assets.arn
}

resource "aws_iam_role_policy_attachment" "api_grader" {
  role       = aws_iam_role.api.name
  policy_arn = aws_iam_policy.grader.arn
}

resource "aws_iam_role" "grader" {
  name = "${var.env}-cadet-grader"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_lambda_function" "grader" {
  filename         = "${var.lambda_filename}"
  function_name    = "${var.env}-cadet-grader"
  handler          = "build/index.runAll"
  role             = "${aws_iam_role.grader.arn}"
  runtime          = "nodejs8.10"
  timeout          = "${var.lambda_timeout}"
  source_code_hash = "${base64sha256(file("${var.lambda_filename}"))}"

  environment {
    variables = {
      TIMEOUT = "${var.grader_timeout}"
    }
  }
}

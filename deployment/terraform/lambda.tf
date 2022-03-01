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
  filename         = var.lambda_filename
  layers           = [data.aws_lambda_layer_version.xvfb.arn]
  function_name    = "${var.env}-cadet-grader"
  handler          = "index.runAll"
  role             = aws_iam_role.grader.arn
  runtime          = "nodejs12.x"
  timeout          = var.lambda_timeout
  source_code_hash = filebase64sha256(var.lambda_filename)
  memory_size      = 512

  environment {
    variables = {
      TIMEOUT = var.grader_timeout
    }
  }
}

data "aws_lambda_layer_version" "xvfb" {
  layer_name = "xvfb"
}

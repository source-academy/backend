data "aws_iam_policy_document" "assets" {
  statement {
    effect  = "Allow"
    actions = ["s3:*"]
    resources = [
      aws_s3_bucket.sourcecasts.arn,
      "${aws_s3_bucket.sourcecasts.arn}/*",
      data.aws_s3_bucket.assets.arn,
      "${data.aws_s3_bucket.assets.arn}/*",
    ]
  }
}

data "aws_iam_policy_document" "config" {
  statement {
    effect  = "Allow"
    actions = ["s3:ListBucket", "s3:PutObject", "s3:GetObject", "s3:DeleteObject"]
    resources = [
      data.aws_s3_bucket.config.arn,
      "${data.aws_s3_bucket.config.arn}/*"
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

data "aws_iam_policy_document" "db_secret" {
  statement {
    effect    = "Allow"
    actions   = ["secretsmanager:GetSecretValue"]
    resources = [aws_secretsmanager_secret.db.arn]
  }
}

data "aws_iam_policy_document" "assume_frontend" {
  statement {
    effect    = "Allow"
    actions   = ["sts:AssumeRole"]
    resources = [aws_iam_role.frontend.arn]
  }
}

data "aws_iam_policy_document" "sling_client" {
  statement {
    effect    = "Allow"
    actions   = ["iot:Receive", "iot:Subscribe", "iot:Connect", "iot:Publish"]
    resources = ["arn:aws:iot:*:*:topicfilter/*", "arn:aws:iot:*:*:topic/*", "arn:aws:iot:*:*:client/*"]
  }
}

data "aws_iam_policy_document" "sling_backend" {
  statement {
    effect    = "Allow"
    actions   = ["iot:CreateThing", "iot:AddThingToThingGroup"]
    resources = ["arn:aws:iot:*:*:thinggroup/${var.env}-sling", "arn:aws:iot:*:*:thing/${var.env}-sling:*"]
  }

  statement {
    effect    = "Allow"
    actions   = ["iot:AttachThingPrincipal", "iot:CreateKeysAndCertificate", "iot:DescribeEndpoint"]
    resources = ["*"]
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

data "aws_iam_policy_document" "assume_frontend_policy" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }

    principals {
      type        = "AWS"
      identifiers = [aws_iam_role.api.arn]
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

resource "aws_iam_role" "frontend" {
  name               = "${var.env}-cadet-frontend"
  assume_role_policy = data.aws_iam_policy_document.assume_frontend_policy.json
}

resource "aws_iam_policy" "assets" {
  name        = "${var.env}-cadet-assets"
  description = "Allows R/W access to the ${aws_s3_bucket.sourcecasts.bucket} and ${data.aws_s3_bucket.assets.bucket} S3 buckets"
  policy      = data.aws_iam_policy_document.assets.json
}

resource "aws_iam_policy" "config" {
  name        = "${var.env}-cadet-config"
  description = "Allows read access to the ${data.aws_s3_bucket.config.bucket} S3 bucket"
  policy      = data.aws_iam_policy_document.config.json
}

resource "aws_iam_policy" "grader" {
  name        = "${var.env}-cadet-grader"
  description = "Allows invocation of the ${aws_lambda_function.grader.function_name} Lambda"
  policy      = data.aws_iam_policy_document.grader.json
}

resource "aws_iam_policy" "db_secret" {
  name        = "${var.env}-cadet-db_secret"
  description = "Allows access to the ${aws_secretsmanager_secret.db.name} secret in Secrets Manager"
  policy      = data.aws_iam_policy_document.db_secret.json
}

resource "aws_iam_policy" "sling_client" {
  name        = "${var.env}-cadet-sling_client"
  description = "Allows access to the AWS IoT endpoints used by the Sling client"
  policy      = data.aws_iam_policy_document.sling_client.json
}

resource "aws_iam_policy" "sling_backend" {
  name        = "${var.env}-cadet-sling_backend"
  description = "Allows access to the AWS IoT endpoints needed by a Sling backend"
  policy      = data.aws_iam_policy_document.sling_backend.json
}

resource "aws_iam_policy" "assume_frontend" {
  name        = "${var.env}-cadet-assume_frontend"
  description = "Allows the backend to generate AWS access tokens for the frontend"
  policy      = data.aws_iam_policy_document.assume_frontend.json
}

resource "aws_iam_role_policy_attachment" "api_assets" {
  role       = aws_iam_role.api.name
  policy_arn = aws_iam_policy.assets.arn
}

resource "aws_iam_role_policy_attachment" "api_config" {
  role       = aws_iam_role.api.name
  policy_arn = aws_iam_policy.config.arn
}

resource "aws_iam_role_policy_attachment" "api_grader" {
  role       = aws_iam_role.api.name
  policy_arn = aws_iam_policy.grader.arn
}

resource "aws_iam_role_policy_attachment" "api_ssm" {
  role       = aws_iam_role.api.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "api_db_secret" {
  role       = aws_iam_role.api.name
  policy_arn = aws_iam_policy.db_secret.arn
}

resource "aws_iam_role_policy_attachment" "api_sling_backend" {
  role       = aws_iam_role.api.name
  policy_arn = aws_iam_policy.sling_backend.arn
}

resource "aws_iam_role_policy_attachment" "api_assume_frontend" {
  role       = aws_iam_role.api.name
  policy_arn = aws_iam_policy.assume_frontend.arn
}

resource "aws_iam_role_policy_attachment" "frontend_sling_client" {
  role       = aws_iam_role.frontend.name
  policy_arn = aws_iam_policy.sling_client.arn
}

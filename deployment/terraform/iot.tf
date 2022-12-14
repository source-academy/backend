resource "aws_iot_policy" "sling" {
  name   = "${var.env}-sling"
  policy = data.aws_iam_policy_document.iot_sling.json
}

data "aws_iam_policy_document" "iot_sling" {
  statement {
    effect    = "Allow"
    actions   = ["iot:Connect"]
    resources = ["arn:aws:iot:${local.region}:${local.account_id}:client/$${iot:Connection.Thing.ThingName}"]
  }

  statement {
    effect = "Allow"
    actions = [
      "iot:Subscribe"
    ]
    resources = [
      "arn:aws:iot:${local.region}:${local.account_id}:topicfilter/$${iot:ClientId}/run",
      "arn:aws:iot:${local.region}:${local.account_id}:topicfilter/$${iot:ClientId}/stop",
      "arn:aws:iot:${local.region}:${local.account_id}:topicfilter/$${iot:ClientId}/ping",
      "arn:aws:iot:${local.region}:${local.account_id}:topicfilter/$${iot:ClientId}/input",
      "arn:aws:iot:${local.region}:${local.account_id}:topicfilter/$${iot:ClientId}/monitor"
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "iot:Receive"
    ]
    resources = [
      "arn:aws:iot:${local.region}:${local.account_id}:topic/$${iot:ClientId}/run",
      "arn:aws:iot:${local.region}:${local.account_id}:topic/$${iot:ClientId}/stop",
      "arn:aws:iot:${local.region}:${local.account_id}:topic/$${iot:ClientId}/ping",
      "arn:aws:iot:${local.region}:${local.account_id}:topic/$${iot:ClientId}/input",
      "arn:aws:iot:${local.region}:${local.account_id}:topic/$${iot:ClientId}/monitor"
    ]
  }

  statement {
    effect  = "Allow"
    actions = ["iot:Publish"]
    resources = [
      "arn:aws:iot:${local.region}:${local.account_id}:topic/$${iot:ClientId}/status",
      "arn:aws:iot:${local.region}:${local.account_id}:topic/$${iot:ClientId}/display",
      "arn:aws:iot:${local.region}:${local.account_id}:topic/$${iot:ClientId}/hello",
      "arn:aws:iot:${local.region}:${local.account_id}:topic/$${iot:ClientId}/monitor"
    ]
  }
}

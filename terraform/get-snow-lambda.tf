data "aws_dynamodb_table" "update_log" {
  name = "howmuchsnowupdatelog"
}

data "aws_iam_policy_document" "get_snow" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "get_snow_lambda" {
  name               = "get_snow_lambda_role"
  assume_role_policy = data.aws_iam_policy_document.get_snow.json
}

resource "aws_cloudwatch_log_group" "get_snow_lambda" {
  name = "/aws/lambda/${aws_lambda_function.get_snow.function_name}"
  retention_in_days = var.log_retention
}

data "aws_iam_policy_document" "get_snow_lambda" {
  statement {
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]
    resources = ["arn:aws:logs:*:*:*"]
  }

  statement {
    effect = "Allow"
    actions = [ 
      "dynamodb:GetItem",
      "dynamodb:UpdateItem",
    ]   
    resources = [data.aws_dynamodb_table.update_log.arn]
  }
}

resource "aws_iam_role_policy" "get_snow_lambda" {
  name   = "howmuchsnow_get_snow_lambda_policy"
  policy = data.aws_iam_policy_document.get_snow_lambda.json
  role   = aws_iam_role.get_snow_lambda.id
}

data "archive_file" "get_snow_lambda" {
  type        = "zip"
  source_file = "${path.module}/lambdas/get_snow.py"
  output_path = "${path.module}/lambdas/get_snow.zip"
}

resource "aws_lambda_function" "get_snow" {
  function_name    = "howmuchsnow_get_snow"
  filename         = data.archive_file.get_snow_lambda.output_path
  handler          = "get_snow.handler"
  source_code_hash = data.archive_file.get_snow_lambda.output_base64sha256
  runtime          = "python3.10"
  role             = aws_iam_role.get_snow_lambda.arn
}

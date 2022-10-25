data "aws_caller_identity" "current" {}

data "archive_file" "init" {
  type        = "zip"
  source_dir  = "${path.module}/lambda_code/"
  output_path = "${path.module}/output_lambda_zip/asg_lambda.zip"
}

resource "aws_lambda_function" "asg_lambda" {
  filename      = data.archive_file.init.output_path
  function_name = "${var.name_prefix}-Lambda"
  role          = aws_iam_role.asg_role.arn
  handler       = "main_handler.lambda_handler"
  description   = "Refresh Auto Scaling Group"
  tags          = { Name = "${var.name_prefix}-Lambda" }

  source_code_hash = filebase64sha256(data.archive_file.init.output_path)

  runtime = "python3.9"
  timeout = "120"

  environment {
    variables = {
      aws_account_id     = data.aws_caller_identity.current.account_id,
      ami_platform       = var.golden_ami_details["ami_platform"],
      ami_name_regex     = var.golden_ami_details["ami_name_regex"],
      launch_template_id = var.golden_ami_details["launch_template_id"]
    }
  }
}
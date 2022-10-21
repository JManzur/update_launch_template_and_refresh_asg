data "template_file" "dotenv" {
  template = file("${path.module}/scripts/dotenv.tpl")

  vars = {
    AWS_REGION   = var.aws_region
    AWS_PROFILE  = var.aws_profile
    FUNCTION_ARN = aws_lambda_function.asg_lambda.arn
  }

  depends_on = [
    aws_lambda_function.asg_lambda
  ]
}

# Render the template and save the new file:
resource "local_file" "render_dotenv" {
  content  = data.template_file.dotenv.rendered
  filename = "${path.module}/scripts/.env"
}
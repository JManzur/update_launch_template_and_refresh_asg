# IAM Policy Source
data "aws_iam_policy_document" "asg_policy_source" {
  statement {
    sid    = "CloudWatchAccess"
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = ["arn:aws:logs:*:*:*"]
  }

  statement {
    sid    = "AutoScalingPermissions"
    effect = "Allow"
    actions = [
      "autoscaling:StartInstanceRefresh"
    ]
    resources = ["*"]
  }

  statement {
    sid    = "EC2Permissions"
    effect = "Allow"
    actions = [
      "ec2:DescribeImages",
      "ec2:CreateLaunchTemplate",
      "ec2:CreateLaunchTemplateVersion",
      "ec2:DescribeLaunchTemplateVersions",
      "ec2:DescribeLaunchTemplates",
      "ec2:ModifyLaunchTemplate"
    ]
    resources = ["*"]
  }
}

data "aws_iam_policy_document" "asg_role_source" {
  statement {
    sid    = "LambdaAssumeRole"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

# IAM Policy
resource "aws_iam_policy" "asg_policy" {
  name        = "${var.name_prefix}-Policy"
  path        = "/"
  description = "Permissions to Refresh ASG"
  policy      = data.aws_iam_policy_document.asg_policy_source.json
  tags        = { Name = "${var.name_prefix}-Policy" }
}

# IAM Role (Lambda execution role)
resource "aws_iam_role" "asg_role" {
  name               = "${var.name_prefix}-Role"
  assume_role_policy = data.aws_iam_policy_document.asg_role_source.json
  tags               = { Name = "${var.name_prefix}-Role" }
}

# Attach Role and Policy
resource "aws_iam_role_policy_attachment" "asg_attachment" {
  role       = aws_iam_role.asg_role.name
  policy_arn = aws_iam_policy.asg_policy.arn
}
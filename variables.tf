# AWS Region: North of Virginia
variable "aws_region" {
  type = string
}

variable "aws_profile" {
  type = string
}

variable "golden_ami_details" {
  type = map(string)
}

#Use: tags = { Name = "${var.name_prefix}-lambda" }
variable "name_prefix" {
  type = string
}

/* Tags Variables */
#Use: tags = merge(var.project-tags, { Name = "${var.resource-name-tag}-place-holder" }, )
variable "project-tags" {
  type = map(string)
  default = {
    Service     = "Refresh Auto Scaling Group",
    Environment = "POC",
    DeployedBy  = "JManzur - https://jmanzur.com/"
  }
}
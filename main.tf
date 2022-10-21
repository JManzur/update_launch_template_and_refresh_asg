module "refresh_asg" {
  source             = "./modules/refresh_asg"
  name_prefix        = var.name_prefix
  aws_region         = var.aws_region
  aws_profile        = var.aws_profile
  golden_ami_details = var.golden_ami_details
}
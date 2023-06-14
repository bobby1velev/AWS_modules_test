############################################
# Provider
############################################

provider "aws" {
  region     = var.aws_region
}

############################################
# Modules
############################################

module "IAM" {
  source = "./modules/IAM"
}

module "security_group" {
  source = "./modules/security_group"
}

module "network" {
  source = "./modules/network"
}

module "autoscaling" {
  source = "./modules/launch_configuration"
}

module "load_balancer" {
  source = "./modules/load_balancer"
}


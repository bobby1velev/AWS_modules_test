############################################
# Defines the two used types of subnets - public and private
############################################

variable "subnet_type" {
  default = {
    public  = "public"
    private = "private"
  }
}

############################################
# Defines the utilized cidr ranges for the 4 required subnets (the one with 2 was skipped as per task)
############################################

variable "cidr_ranges" {
  default = {
    public1  = "172.16.1.0/24"
    public2  = "172.16.3.0/24"
    private1 = "172.16.4.0/24"
    private2 = "172.16.5.0/24"
  }
}

############################################
# Defines instance type - t2 micro is the only one we use as it is free tier eligible
############################################

variable "instance_type" {
  default = "t2.micro"
  }

############################################
# Defines the used image
############################################

variable "used_image" {
  default = "ami-0e23c576dacf2e3df"
  }

############################################
# Defines the both required per task availability zones: a and b
############################################

variable "availability_zone_a" {
    type = string
    default = "eu-west-1a"
}

variable "availability_zone_b" {
    type = string
    default = "eu-west-1b"
}

############################################
# Defines the reqion in which all instances should be created: Ireland
############################################

variable "aws_region" {
  type        = string
  description = "The only region we should use"
  default     = "eu-west-1"
}

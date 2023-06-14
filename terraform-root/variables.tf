############################################
# variables
############################################

variable "subnet_type" {
  default = {
    public  = "public"
    private = "private"
  }
}

variable "cidr_ranges" {
  default = {
    public1  = "172.16.1.0/24"
    public2  = "172.16.3.0/24"
    private1 = "172.16.4.0/24"
    private2 = "172.16.5.0/24"
  }
}

variable "instance_type" {
  default = "t2.micro"
  }

variable "used_image" {
  default = "ami-0e23c576dacf2e3df"
  }

variable "availability_zone_a" {
    type = string
    default = "eu-west-1a"
}

variable "availability_zone_b" {
    type = string
    default = "eu-west-1b"
}

variable "aws_region" {
  type        = string
  description = "The only region we should use"
  default     = "eu-west-1"
}

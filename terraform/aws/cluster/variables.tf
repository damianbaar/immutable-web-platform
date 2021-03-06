
variable "map_roles" {
  type = list(map(string))

  default = [
    {
      role_arn = "arn:aws:iam::006393696278:group/DigitalRigAlphaAdmins"
      username = "admins"
      group    = "system:masters"
    },
  ]
}

variable "map_users" {
  type = list(map(string))

  default = [
    {
      user_arn = "arn:aws:iam::006393696278:user/damian_baar"
      username = "damian.baar"
      group    = "system:masters"
    },
  ]
}

data "aws_availability_zones" "available" {
  state = "available"
}

# resource "tls_private_key" "example" {
#   algorithm = "RSA"
#   rsa_bits  = 4096
# }
variable "ssh_pub_key" {
  default = "~/.ssh/id_rsa.pub"
}

variable "bootstrap" {
  type    = bool
  default = false
}

locals {
  azs = data.aws_availability_zones.available.names

  common_tags = map(
    "Owner", var.owner,
    "Project Name", var.project_name,
    "Env", var.env
  )
}

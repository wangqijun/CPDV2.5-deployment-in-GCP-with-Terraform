variable "bastion_key_path" {
  description = "My public ssh key"
   default = "./helper_scripts/id_rsa.pub"
}
variable "openshift_key_path" {
  description = "My public ssh key"
   default = "./helper_scripts/id_rsa.pub"
}
variable "gcp_region" {
  description = "Google Compute Platform region to launch servers."
  default     = "us-east1"
}
variable "gcp_project" {
  description = "Google Compute Platform project name."
  default     = "cp4d-h-pilot"
}
variable "domain" {
  description = "Specify domain name to be used for linux customization on the VMs, or leave blank to use <instance_name>.icp"
  default     = "ocp.gcp.com"
}
variable "gcp_zone" {
  type = "string"
  default = "us-east1-b"
  description = "The zone to provision into"
}
variable "gcp_amis" {
  default = "rhel-7"
}
variable "vpc_public" {
  default = "10.0.0.0/24"
  description = "the vpc public cdir range"
}
variable "vpc_private" {
  default = "10.0.1.0/24"
  description = "the vpc private cdir range"
}
variable "htpasswd" {
  default = "password"
}
variable "bastion" {
  type = "map"
  default = {
    disk_size           = 100   # Specify size or leave empty to use same size as template.
    count = 0
  }
}

variable "master" {
  type = "map"
  default = {
    disk_size           = 100   # Specify size or leave empty to use same size as template.
    count = 3
  }
}
variable "infra" {
  type = "map"
  default = {
    disk_size           = 100   # Specify size or leave empty to use same size as template.
    count = 0
  }
}
variable "nfs" {
  type = "map"
  default = {
    disk_size           = 100   # Specify size or leave empty to use same size as template.
    count = 0
  }
}
variable "worker" {
  type = "map"
  default = {
    disk_size           = 100   # Specify size or leave empty to use same size as template.
    count = 3
  }
}


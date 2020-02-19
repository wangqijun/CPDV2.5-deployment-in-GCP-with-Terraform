provider "google" {
  credentials = "${file("./cp4d-h-pilot-31b794343102.json")}"
  project     = "${var.gcp_project}"
  region      = "${var.gcp_region}"
}
terraform {
  backend "gcs" {
    bucket    = "terraform-data-h-qijun"
    prefix    = "openshift-311"
    credentials = "./cp4d-h-pilot-31b794343102.json"
  }
}
data "template_file" "sysprep-bastion" {
  template = "${file("./helper_scripts/sysprep-bastion.sh")}"
}

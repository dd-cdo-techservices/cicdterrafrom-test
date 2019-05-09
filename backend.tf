terraform {
  backend "s3" {
    bucket = "sudevfta-tfstatefiles-feb"
    key    = "cicdpipelinetfstatefiles/terraform.tfstate"
    region = "ap-south-1"
  }
}

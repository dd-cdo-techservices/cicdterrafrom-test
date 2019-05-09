terraform {
  backend "s3" {
    bucket = "sudevfta-tfstatefiles-feb"
    key    = "cicdpipelinetfstatefiles/terraform-test.tfstate"
    region = "ap-south-1"
  }
}

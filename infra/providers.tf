provider "aws" {
  region = "eu-west-1"
}

terraform {
  backend "s3" {
    bucket       = "extremely-unique-terraform-state-bucket-in-ireland"
    key          = "terraform/state.tfstate"
    region       = "eu-west-1"
    use_lockfile = true
  }
}

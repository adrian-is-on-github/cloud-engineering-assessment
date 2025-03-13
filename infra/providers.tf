
provider "aws" {
  region  = "eu-west-1"
  profile = "terraform-user"
}
provider "aws" {
  alias  = "ireland"
  region = "eu-west-1"
}
# Add more regions as needed



terraform {
  backend "s3" {
    bucket       = "extremely-unique-terraform-state-bucket-in-ireland"
    key          = "terraform/state.tfstate"
    region       = "eu-west-1"
    use_lockfile = true
  }
}

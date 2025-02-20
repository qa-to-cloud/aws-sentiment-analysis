provider "aws" {
  region = "eu-west-2"

  default_tags {
    tags = {
      environment = "dev"
      country     = "uk"
      owner       = "qa-to-cloud"
      created-by  = "aws-sentiment-analysis"
      iac_path    = "infrastructure/uk"
    }
  }
}
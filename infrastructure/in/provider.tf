provider "aws" {
  region = "ap-south-1"

  default_tags {
    tags = {
      environment = "dev"
      country     = "in"
      owner       = "qa-to-cloud"
      created-by  = "aws-sentiment-analysis"
      iac_path    = "infrastructure/in"
    }
  }
}

terraform {
  backend "s3" {
    bucket       = "motorsport-terraform-state"
    key          = "main/terraform.tfstate"
    region       = "us-east-2"
    use_lockfile = true
  }
}
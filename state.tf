terraform {
  backend "s3" {
    bucket       = "tf-backend-069256705118"
    key          = "staging/terraform.tfstate"
    region       = "eu-west-1"
    encrypt      = true
    use_lockfile = true
  }
}


# Remote state
# data "terraform_remote_state" "network" {
#   backend = "s3"
#   config = {
#     bucket = "terraform-state-prod"
#     key    = "network/terraform.tfstate"
#     region = "us-east-1"
#   }
# }

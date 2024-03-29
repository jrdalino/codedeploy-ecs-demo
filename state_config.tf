terraform {
  backend "s3" {
    region         = "ap-southeast-1"
    bucket         = "449276385511-ap-southeast-1-terraform-state" // AWS acccount where state backend is located
    key            = "codedeploy-ecs-demo-terraform.tfstate"
    encrypt        = "true"
    dynamodb_table = "terraform-state-lock"
  }
}
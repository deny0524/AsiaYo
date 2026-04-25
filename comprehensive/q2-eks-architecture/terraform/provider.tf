terraform {
  required_version = ">= 1.5"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.region
}

# 取得可用區，用於多 AZ 高可用部署
data "aws_availability_zones" "available" {
  state = "available"
}

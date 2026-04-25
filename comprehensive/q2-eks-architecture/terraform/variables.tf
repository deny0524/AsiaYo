variable "region" {
  default = "ap-northeast-1"
}

variable "cluster_name" {
  default = "asiayo-eks"
}

variable "cluster_version" {
  default = "1.31"
}

variable "vpc_cidr" {
  default = "10.0.0.0/16"
}

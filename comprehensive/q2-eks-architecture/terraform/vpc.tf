# --------------------------------------------------
# VPC 網路設計：跨 3 個 AZ 部署，確保高可用性
#   - 3 個 public subnet  (給 ALB / Ingress 使用)
#   - 3 個 private subnet (給 EKS node 使用)
#   - NAT Gateway 讓 private subnet 可對外
# --------------------------------------------------

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = "${var.cluster_name}-vpc"
  cidr = var.vpc_cidr
  azs  = slice(data.aws_availability_zones.available.names, 0, 3)

  public_subnets  = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  private_subnets = ["10.0.11.0/24", "10.0.12.0/24", "10.0.13.0/24"]

  enable_nat_gateway   = true
  single_nat_gateway   = false # 每個 AZ 各一個 NAT GW，避免單點故障
  enable_dns_hostnames = true

  # EKS 所需的 subnet tag
  public_subnet_tags = {
    "kubernetes.io/role/elb" = 1
  }
  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = 1
  }
}

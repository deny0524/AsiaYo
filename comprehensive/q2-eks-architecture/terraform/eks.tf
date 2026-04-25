# --------------------------------------------------
# EKS Cluster
#   - 使用 managed node group，AWS 負責節點生命週期管理
#   - 節點部署在 private subnet，透過 NAT GW 對外
#   - 啟用 EBS CSI driver 供 MySQL PV 使用
# --------------------------------------------------

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = var.cluster_name
  cluster_version = var.cluster_version

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  # 允許公開存取 API（方便 kubectl 操作，正式環境可限制 IP）
  cluster_endpoint_public_access = true

  # 啟用 EBS CSI driver addon，讓 StatefulSet 可使用 PersistentVolume
  cluster_addons = {
    aws-ebs-csi-driver = { most_recent = true }
    coredns            = { most_recent = true }
    kube-proxy         = { most_recent = true }
    vpc-cni            = { most_recent = true }
  }

  eks_managed_node_groups = {
    # 高可用：desired 3 個節點分散在不同 AZ
    default = {
      instance_types = ["t3.medium"]
      min_size       = 2
      max_size       = 5
      desired_size   = 3
    }
  }
}

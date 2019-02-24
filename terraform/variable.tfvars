# access_key = "YOUR_ACCESS_KEY"
# secret_key = "YOUR_SECRET_KEY"

access_key = "YOUR_ACCECC_KEY"
secret_key = "YOUR_SECRET_KEY"

region = "ap-northeast-2"

# default_internet_gateway_id = "igw-3a18cb52"

########################
## EKS
########################

eks_cluster_name                     = "terraform-eks-demo"

eks_worker_instance_type             = "t3.small"
eks_worker_desired_capacity          = 2
eks_worker_max_size                  = 10
eks_worker_min_size                  = 1
eks_worker_health_check_grace_period = 300

eks_scale_up_worker_node   = 1
eks_scale_up_cooldown      = 30
eks_scale_up_threshold     = 10
eks_scale_down_worker_node = -1
eks_scale_down_cooldown    = 30
eks_scale_down_threshold   = 5

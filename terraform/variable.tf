variable "access_key" { }
variable "secret_key" { }
variable "region" { }

# variable "default_internet_gateway_id" { }

########################
## EKS
########################

variable "eks_cluster_name" {}
variable "eks_worker_instance_type" { }
variable "eks_worker_desired_capacity" { }
variable "eks_worker_max_size" { }
variable "eks_worker_min_size" { }
variable "eks_worker_health_check_grace_period" { }

variable "eks_scale_up_worker_node" { }
variable "eks_scale_up_cooldown" { }
variable "eks_scale_up_threshold" { }
variable "eks_scale_down_worker_node" { }
variable "eks_scale_down_cooldown" { }
variable "eks_scale_down_threshold" { }


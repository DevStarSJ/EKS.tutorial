# This data source is included for ease of sample architecture deployment
# and can be swapped out as necessary.
data "aws_region" "current" {}

# EKS currently documents this required userdata for EKS worker nodes to
# properly configure Kubernetes applications on the EC2 instance.
# We utilize a Terraform local here to simplify Base64 encoding this
# information into the AutoScaling Launch Configuration.
# More information: https://docs.aws.amazon.com/eks/latest/userguide/launch-workers.html
locals {
  demo-node-userdata = <<USERDATA
#!/bin/bash
set -o xtrace
/etc/eks/bootstrap.sh --apiserver-endpoint '${aws_eks_cluster.demo.endpoint}' --b64-cluster-ca '${aws_eks_cluster.demo.certificate_authority.0.data}' '${var.eks_cluster_name}'
USERDATA
}

resource "aws_launch_configuration" "demo" {
  associate_public_ip_address = true
  iam_instance_profile        = "${aws_iam_instance_profile.demo-node.name}"
  image_id                    = "${data.aws_ami.eks-worker.id}"
  instance_type               = "m4.large"
  name_prefix                 = "terraform-eks-demo"
  security_groups             = ["${aws_security_group.demo-node.id}"]
  user_data_base64            = "${base64encode(local.demo-node-userdata)}"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "demo" {
  name                      = "${var.eks_cluster_name}"
  desired_capacity          = "${var.eks_worker_desired_capacity}"
  max_size                  = "${var.eks_worker_max_size}"
  min_size                  = "${var.eks_worker_min_size}"
  health_check_grace_period = "${var.eks_worker_health_check_grace_period}"
  launch_configuration      = "${aws_launch_configuration.demo.id}"
  vpc_zone_identifier       = ["${aws_subnet.demo.*.id}"]
  
  #[ "${split(",", "${aws_default_subnet.a.id},${aws_default_subnet.c.id}")}" ]

  tag {
    key                 = "Name"
    value               = "terraform-eks-demo"
    propagate_at_launch = true
  }

  tag {
    key                 = "kubernetes.io/cluster/${var.eks_cluster_name}"
    value               = "owned"
    propagate_at_launch = true
  }
}

resource "aws_autoscaling_policy" "scale_up" {
    name                   = "scale_up"
    scaling_adjustment     = "${var.eks_scale_up_worker_node}"
    adjustment_type        = "ChangeInCapacity"
    cooldown               = "${var.eks_scale_up_cooldown}"
    autoscaling_group_name = "${aws_autoscaling_group.demo.name}"
}

resource "aws_autoscaling_policy" "scale_down" {
    name                   = "scale_down"
    scaling_adjustment     = "${var.eks_scale_down_worker_node}"
    adjustment_type        = "ChangeInCapacity"
    cooldown               = "${var.eks_scale_down_cooldown}"
    autoscaling_group_name = "${aws_autoscaling_group.demo.name}"
}

resource "aws_cloudwatch_metric_alarm" "cpu_high" {
    alarm_name          = "cpu_high"
    comparison_operator = "GreaterThanOrEqualToThreshold"
    evaluation_periods  = "1"
    metric_name         = "CPUUtilization"
    namespace           = "AWS/EC2"
    period              = "60"
    statistic           = "Average"
    threshold           = "${var.eks_scale_up_threshold}"
    alarm_description   = "This metric monitors EC2 CPU for high utilization on agent hosts"
    alarm_actions       = [ "${aws_autoscaling_policy.scale_up.arn}" ]
    dimensions { 
      AutoScalingGroupName = "${aws_autoscaling_group.demo.name}" 
    }
}

resource "aws_cloudwatch_metric_alarm" "cpu_low" {
    alarm_name          = "cpu_low"
    comparison_operator = "LessThanOrEqualToThreshold"
    evaluation_periods  = "1"
    metric_name         = "CPUUtilization"
    namespace           = "AWS/EC2"
    period              = "60"
    statistic           = "Average"
    threshold           = "${var.eks_scale_down_threshold}"
    alarm_description   = "This metric monitors EC2 CPU for low utilization on agent hosts"
    alarm_actions       = [ "${aws_autoscaling_policy.scale_down.arn}" ]
    dimensions { 
      AutoScalingGroupName = "${aws_autoscaling_group.demo.name}" 
    }
}
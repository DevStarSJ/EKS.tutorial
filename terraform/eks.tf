resource "aws_eks_cluster" "demo" {
  name            = "${var.eks_cluster_name}"
  role_arn        = "${aws_iam_role.demo-cluster.arn}"

  vpc_config {
    security_group_ids = ["${aws_security_group.demo-cluster.id}"]
    subnet_ids         =  ["${aws_subnet.demo.*.id}"]
    # [ "${split(",", "${aws_default_subnet.a.id},${aws_default_subnet.c.id}")}" ]
    #["${aws_subnet.demo.*.id}"]
  }
}

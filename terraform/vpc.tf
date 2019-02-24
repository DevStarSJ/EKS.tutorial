# # This data source is included for ease of sample architecture deployment
# # and can be swapped out as necessary.
# data "aws_availability_zones" "available" {}

# resource "aws_vpc" "demo" {
#   cidr_block = "10.0.0.0/16"

#   tags = "${
#     map(
#      "Name", "terraform-eks-demo-node",
#      "kubernetes.io/cluster/${var.eks_cluster_name}", "shared",
#     )
#   }"
# }

# resource "aws_subnet" "demo" {
#   count = 2

#   availability_zone = "${data.aws_availability_zones.available.names[count.index]}"
#   cidr_block        = "10.0.${count.index}.0/24"
#   vpc_id            = "${aws_vpc.demo.id}"

#   tags = "${
#     map(
#      "Name", "terraform-eks-demo-node",
#      "kubernetes.io/cluster/${var.eks_cluster_name}", "shared",
#     )
#   }"
# }

# resource "aws_internet_gateway" "demo" {
#   vpc_id = "${aws_vpc.demo.id}"

#   tags = {
#     Name = "terraform-eks-demo"
#   }
# }

# resource "aws_route_table" "demo" {
#   vpc_id = "${aws_vpc.demo.id}"

#   route {
#     cidr_block = "0.0.0.0/0"
#     gateway_id = "${aws_internet_gateway.demo.id}"
#   }
# }

# resource "aws_route_table_association" "demo" {
#   count = 2

#   subnet_id      = "${aws_subnet.demo.*.id[count.index]}"
#   route_table_id = "${aws_route_table.demo.id}"
# }
resource "aws_default_vpc" "default" {
    tags = "${
        map(
            "Name", "default",
            "kubernetes.io/cluster/${var.eks_cluster_name}", "shared",
        )
    }"
}

resource "aws_default_subnet" "a" {
	availability_zone       = "ap-northeast-2a"

	tags = "${
		map(
			"Name", "default_a",
			"kubernetes.io/cluster/${var.eks_cluster_name}", "shared",
		)
	}"
}

resource "aws_default_subnet" "c" {
	availability_zone       = "ap-northeast-2c"

	tags = "${
		map(
			"Name", "default_c",
			"kubernetes.io/cluster/${var.eks_cluster_name}", "shared",
		)
	}"
}

data "aws_internet_gateway" "default" {
  internet_gateway_id = "${var.default_internet_gateway_id}"
}

resource "aws_default_route_table" "default" {
  default_route_table_id = "${aws_default_vpc.default.default_route_table_id}"

    route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${data.aws_internet_gateway.default.id}"
  }

  tags = {
    Name = "default"
  }
}

resource "aws_route_table_association" "default_route_table" {
  count = 2

  subnet_id      = "${element(split(",", "${aws_default_subnet.a.id},${aws_default_subnet.c.id}"), count.index)}"
  route_table_id = "${aws_default_route_table.default.id}"
}
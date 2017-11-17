resource "aws_vpc" "vpc_bv" {
    cidr_block = "${var.vpc_cidr}"
    enable_dns_hostnames = true
    tags {
        Name = "vpc-bv"
        project = "bv"
    }
}

resource "aws_internet_gateway" "default" {
    vpc_id = "${aws_vpc.vpc_bv.id}"
}

resource "aws_security_group" "hop" {
    name = "sg_hop"
    description = "Allow traffic"

    ingress {
        from_port = 80
        to_port = 80
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    ingress {
        from_port = 443
        to_port = 443
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    ingress {
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    ingress {
        from_port = -1
        to_port = -1
        protocol = "icmp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    egress {
        from_port = 80
        to_port = 80
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    egress {
        from_port = 443
        to_port = 443
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    egress {
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    egress {
        from_port = -1
        to_port = -1
        protocol = "icmp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    vpc_id = "${aws_vpc.vpc_bv.id}"

    tags {
        Name="sg_hop"
        project= "bv"
    }
}

resource "aws_instance" "hop" {
    ami = "${lookup(var.amis, var.aws_region)}"
    availability_zone = "eu-west-1a"
    instance_type = "t2.micro"
    key_name = "${var.aws_key_name}"
    vpc_security_group_ids = ["${aws_security_group.hop.id}"]
    subnet_id = "${aws_subnet.eu-west-1a-public.id}"
    associate_public_ip_address = true
    source_dest_check = false

    tags {
        Name = "VPC NAT"
        #Name = "HOP"
        project = "bv"
    }
}

resource "aws_eip" "hop" {
    instance = "${aws_instance.hop.id}"
    vpc = true
}

/*
  Public Subnet
*/
resource "aws_subnet" "eu-west-1a-public" {
    vpc_id = "${aws_vpc.vpc_bv.id}"

    cidr_block = "${var.public_subnet_cidr}"
    availability_zone = "eu-west-1a"

    tags {
        Name = "Public Subnet"
        project= "bv"
    }
}

resource "aws_route_table" "eu-west-1a-public" {
    vpc_id = "${aws_vpc.vpc_bv.id}"

    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = "${aws_internet_gateway.default.id}"
    }

    tags {
        Name = "Public Subnet"
        project= "bv"
    }
}

resource "aws_route_table_association" "eu-west-1a-public" {
    subnet_id = "${aws_subnet.eu-west-1a-public.id}"
    route_table_id = "${aws_route_table.eu-west-1a-public.id}"
}

/*
  Private Subnet
*/
resource "aws_subnet" "eu-west-1a-private" {
    vpc_id = "${aws_vpc.vpc_bv.id}"

    cidr_block = "${var.private_subnet_cidr}"
    availability_zone = "eu-west-1a"

    tags {
        Name = "Private Subnet"
        project= "bv"
    }
}

resource "aws_route_table" "eu-west-1a-private" {
    vpc_id = "${aws_vpc.vpc_bv.id}"

    route {
        cidr_block = "0.0.0.0/0"
        instance_id = "${aws_instance.hop.id}"
    }

    tags {
        Name = "Private Subnet"
        project= "bv"
    }
}

resource "aws_route_table_association" "eu-west-1a-private" {
    subnet_id = "${aws_subnet.eu-west-1a-private.id}"
    route_table_id = "${aws_route_table.eu-west-1a-private.id}"
}

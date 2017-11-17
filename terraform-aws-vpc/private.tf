/*
  App Servers
*/
resource "aws_security_group" "app_hello_world" {
    name = "sg_app"
    description = "Allow incoming connections."

    ingress {
        from_port = 8080
        to_port = 8080
        protocol = "tcp"
        cidr_blocks = ["${var.vpc_cidr}"]
    }
    ingress {
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = ["${var.vpc_cidr}"]
    }
    ingress {
        from_port = -1
        to_port = -1
        protocol = "icmp"
        cidr_blocks = ["${var.vpc_cidr}"]
    }

    egress {
        from_port = 8080
        to_port = 8080
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    egress {
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    #salt port are missing
    vpc_id = "${aws_vpc.vpc_bv.id}"

    tags {
        Name = "APPServerSG"
        project= "bv"
    }
}

resource "aws_instance" "app-1" {
    ami = "${lookup(var.amis, var.aws_region)}"
    availability_zone = "eu-west-1a"
    instance_type = "t2.micro"
    key_name = "${var.aws_key_name}"
    vpc_security_group_ids = ["${aws_security_group.app_hello_world.id}"]
    subnet_id = "${aws_subnet.eu-west-1a-private.id}"
    source_dest_check = false

  provisioner "file" {
    source      = "scripts/bootstrap_minion.sh"
    destination = "/tmp/bootstrap_minion.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/bootstrap_minion.sh ${aws_instance.mymaster.private_ip} app-1",
      "bash -x /tmp/bootstrap_minion.sh > /tmp/log_minion.log",
    ]
   }

    tags {
        Name = "App 1"
        project= "bv"
    }
}

#there are many other better ways to this, but I am short of time
resource "aws_instance" "app-2" {
    ami = "${lookup(var.amis, var.aws_region)}"
    availability_zone = "eu-west-1a"
    instance_type = "t2.micro"
    key_name = "${var.aws_key_name}"
    vpc_security_group_ids = ["${aws_security_group.app_hello_world.id}"]
    subnet_id = "${aws_subnet.eu-west-1a-private.id}"
    source_dest_check = false

  provisioner "file" {
    source      = "scripts/bootstrap_minion.sh"
    destination = "/tmp/bootstrap_minion.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/bootstrap_minion.sh ${aws_instance.mymaster.private_ip} app-2",
      "bash -x /tmp/bootstrap_minion.sh > /tmp/log_minion.log",
    ]

    tags {
        Name = "App 2"
        project= "bv"
    }
}


resource "aws_elb_attachment" "app-elb" {
  elb      = "${aws_elb.hello_elb.id}"
  instance = "${aws_instance.app-1.id}"
}

resource "aws_elb_attachment" "app-elb" {
  elb      = "${aws_elb.hello_elb.id}"
  instance = "${aws_instance.app-2.id}"
}


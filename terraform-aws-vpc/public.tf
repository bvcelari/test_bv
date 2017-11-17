/*
  Web Servers
*/
resource "aws_security_group" "salt" {
    name = "sg_salt"
    description = "Allow incoming HTTP connections."

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
        from_port = -1
        to_port = -1
        protocol = "icmp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    vpc_id = "${aws_vpc.vpc_bv.id}"

    tags {
        Name = "salt master"
        project= "bv"
    }
}

resource "aws_instance" "mymaster" {
    ami = "${lookup(var.amis, var.aws_region)}"
    availability_zone = "eu-west-1a"
    instance_type = "t2.micro"
    key_name = "${var.aws_key_name}"
    vpc_security_group_ids = ["${aws_security_group.salt.id}"]
    subnet_id = "${aws_subnet.eu-west-1a-public.id}"
    associate_public_ip_address = true
    source_dest_check = false

  provisioner "file" {
    source      = "scripts/bootstrap_master.sh"
    destination = "/tmp/bootstrap_master.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/bootstrap_master.sh",
      "bash -x /tmp/bootstrap_master.sh > /tmp/log_master.log",
    ]
  }


    tags {
        Name = "salt master"
        project= "bv"
    }
}

resource "aws_eip" "salt-master-ip" {
    instance = "${aws_instance.mymaster.id}"
    vpc = true
}


resource "aws_elb" "hello_elb" {
  name               = "foobar-terraform-elb"
  availability_zones = ["us-west-2a", "us-west-2b", "us-west-2c"]

  listener {
    instance_port     = 8080
    instance_protocol = "http"
    lb_port           = 80
    lb_protocol       = "http"
  }


  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    target              = "HTTP:8080/"
    interval            = 30
  }

  cross_zone_load_balancing   = true
  idle_timeout                = 400
  connection_draining         = true
  connection_draining_timeout = 400

  tags {
    Name = "bv-elb"
    project= "bv"

  }
}
»

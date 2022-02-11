resource "aws_security_group" "inbound_http" {
  vpc_id = module.aws-vpc.aws_vpc_id
  name = "http-to-ingresses-sg"

  ingress {
    from_port = 80
    protocol = "TCP"
    to_port = 80
    cidr_blocks = ["0.0.0.0/0"]
    description = "Incoming HTTP connection"
  }

  egress {
    from_port = 0
    protocol = "-1"
    to_port = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_elb" "ingresses_http_elb" {
  name               = "ingresses-http-elb-${var.aws_cluster_name}"
  subnets = module.aws-vpc.aws_subnet_ids_public
  security_groups = [aws_security_group.inbound_http.id]

  listener {
    instance_port     = 80
    instance_protocol = "http"
    lb_port           = 80
    lb_protocol       = "http"
  }

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 10
    timeout             = 3
    target              = "TCP:80"
    interval            = 15
  }

  cross_zone_load_balancing   = true
  idle_timeout                = 400
  connection_draining         = true
  connection_draining_timeout = 400

  tags = {
    Name = "kubernetes-${var.aws_cluster_name}-elb-ingresses"
  }
}


resource "aws_elb_attachment" "attach_ingresses_nodes" {
  count    = var.aws_kube_master_num
  elb      = aws_elb.ingresses_http_elb.id
  instance = element(aws_instance.k8s-worker.*.id, count.index)
}

output "classic-balancer-dns_name" {
  value = "${aws_elb.ingresses_http_elb.dns_name}"
}

provider "aws" {
  region     = "${var.region}"
}

# Create a VPC to launch our instances into
resource "aws_vpc" "takehome" {
  cidr_block = "10.10.0.0/16"
}

# Create an internet gateway to give our subnet access to the outside world
resource "aws_internet_gateway" "takehome" {
  vpc_id = "${aws_vpc.takehome.id}"
}


# Grant the VPC internet access on its main route table
resource "aws_route" "internet_access" {
  route_table_id         = "${aws_vpc.takehome.main_route_table_id}"
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = "${aws_internet_gateway.takehome.id}"

}

# Create a subnet to launch our instances into
resource "aws_subnet" "public" {
  vpc_id                  = "${aws_vpc.takehome.id}"
  cidr_block              = "10.10.1.0/24"
  map_public_ip_on_launch = true

}

# A security group for the ELB so it's accessible via the web
resource "aws_security_group" "elb" {
  name        = "takehome_elb"
  description = "takehome project"
  vpc_id      = "${aws_vpc.takehome.id}"

  # HTTP access from your location
ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["${var.home_ip}"]
  
}

  # outbound internet access
egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  
}

}

# Our default security group to access
# the instance over SSH and HTTP
resource "aws_security_group" "takehome" {
  name        = "takehome_security_group"
  description = "public"
  vpc_id      = "${aws_vpc.takehome.id}"

  # SSH access from your location
ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["${var.home_ip}"]
  
}

  # HTTP access from the VPC
ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["10.10.0.0/16"]
  
}

  # outbound internet access
egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  
}

}

# A security group to allow the frontend to access the backend database
resource "aws_security_group" "backend" {
    name        = "takehome_backend_security_group"
    description = "private"
    vpc_id      = "${aws_vpc.takehome.id}"
    
    # postgres access from the frontend
ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    security_groups = ["${aws_security_group.takehome.id}"]
}
egress {
     from_port   = 0
     to_port     = 0
     protocol    = "-1"
     cidr_blocks = ["0.0.0.0/0"]
}
}


data "aws_availability_zones" "all" {}

resource "aws_elb" "web" {
  name = "takehome-elb"
    subnets         = ["${aws_subnet.public.id}"]
  security_groups = ["${aws_security_group.elb.id}"]
  instances       = ["${aws_instance.web.id}"]

listener {
    instance_port     = 80
    instance_protocol = "http"
    lb_port           = 80
    lb_protocol       = "http"
}
listener {
    instance_port       = 80
    instance_protocol   = "http"
    lb_port             = 443
    lb_protocol         = "http"
}
health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
    target              = "HTTP:80/"
    interval            = 30
}

tags {
    Name = "frontend"
}
}

output "dns_name" {
    value = "${aws_elb.web.dns_name}"
}

resource "aws_key_pair" "tf" {
  key_name   = "${var.key_name}"
  public_key = "${file(var.public_key_path)}"

}

data "template_file" "user_data_web" {
  template = "${file("${path.module}/user-data-web.sh")}"

vars {}
}

data "template_file" "user_data_db" {
   template = "${file("${path.module}/user-data-db.sh")}"

vars {}
 
}

resource "aws_instance" "web" {
connection {
    user = "ubuntu"
}

    instance_type = "t2.micro"
    ami = "ami-0a00ce72"
  # The name of our SSH keypair we created above.
    key_name = "${aws_key_pair.tf.id}"

  # Our Security group to allow HTTP and SSH access
    vpc_security_group_ids = ["${aws_security_group.takehome.id}"]

  # We're going to launch into the same subnet as our ELB. In a production
  # environment it's more common to have a separate private subnet for
  # backend instances.
    subnet_id = "${aws_subnet.public.id}"
    user_data       = "${data.template_file.user_data_web.rendered}"
    provisioner "file" {
        source = "index.html"
        destination = "/tmp/index.html"
    }
}

output "public IP for nginx" {
     value = "${aws_instance.web.public_ip}"
 
}

resource "aws_instance" "postgres" {
connection {
     user = "ubuntu"
}

    instance_type = "t2.micro"

    ami = "ami-0a00ce72"
   # The name of our SSH keypair we created above.
    key_name = "${aws_key_pair.tf.id}"

   # Our Security group to allow HTTP and SSH access
    vpc_security_group_ids = ["${aws_security_group.backend.id}"]

   subnet_id = "${aws_subnet.public.id}"
    user_data       = "${data.template_file.user_data_db.rendered}"
 
}
output "private IP for postgres" {
      value = "${aws_instance.postgres.private_ip}"

 
}

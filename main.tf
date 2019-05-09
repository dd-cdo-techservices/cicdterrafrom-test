# AWS infrastructure provisioning
# Project: CICD Pipeline Setup
# Use Case# : 1
# CreatedBy : Sumanth

##################################

provider "aws" {
	region = "ap-south-1"
}

# Find the latest available AMI that is tagged with Name = sampleami
data "aws_ami" "ublampami" {
  owners = ["self"]
  filter {
    name   = "state"
    values = ["available"]
  }

  filter {
    name   = "tag:Name"
    values = ["uc-one-lampub"]
  }

  most_recent = true
}

data "aws_ami" "mysqlami" {
  owners = ["self"]
  filter {
    name   = "state"
    values = ["available"]
  }

  filter {
    name   = "tag:Name"
    values = ["uc-one-MySQLUB"]
  }

  most_recent = true
}

# Create a VPC for setting up CICD pipeline infrastructure
# with necessary components.

#VPC creation
resource "aws_vpc" "uconecicdnet" {
	cidr_block       = "50.0.0.0/16"
	enable_dns_support = "true"
	enable_dns_hostnames = "true"  

	tags = {
	  Name = "cicdpipelinenetwork"
	  CreatedBy = "Sumanth"
	  Purpose = "PipelineDemo"
  	}
}

#Internet Gateway creation
resource "aws_internet_gateway" "cicdgw" {
	vpc_id = "${aws_vpc.uconecicdnet.id}"

	tags = {
	  Name = "CICDInternetGateway"
	  CreatedBy = "Sumanth"
          Purpose = "PipelineDemo"
	}
}

#Public subnet creation
resource "aws_subnet" "cicdnetworkpublicsubnet" {
	vpc_id = "${aws_vpc.uconecicdnet.id}"
	cidr_block = "50.0.3.0/24"
	availability_zone = "ap-south-1a"

	tags = {
	  Name = "cicdpublicsubnet"
          CreatedBy = "Sumanth"
          Purpose = "PipelineDemo"
	}
}

#Private subnet creation
resource "aws_subnet" "cicdnetworkprivatesubnet" {
        vpc_id = "${aws_vpc.uconecicdnet.id}"
        cidr_block = "50.0.4.0/24"
        availability_zone = "ap-south-1b"

        tags = {
          Name = "cicdprivatesubnet"
          CreatedBy = "Sumanth"
          Purpose = "PipelineDemo"
        }
}

#Provision Route Table for Public Subnet
resource "aws_route_table" "cicdpublicrt" {
	vpc_id = "${aws_vpc.uconecicdnet.id}"
	
	route {
	  cidr_block = "0.0.0.0/0"
    	  gateway_id = "${aws_internet_gateway.cicdgw.id}"
	}

	tags = {
          Name = "cicdpublicsubnetrt"
          CreatedBy = "Sumanth"
          Purpose = "PipelineDemo"
        }
}

#Associate Routing Table with Public Subnet
resource "aws_route_table_association" "cicdrtassociate" {
	subnet_id = "${aws_subnet.cicdnetworkpublicsubnet.id}"
	route_table_id = "${aws_route_table.cicdpublicrt.id}"
}

#Security group creation for wordpress server
resource "aws_security_group" "cicd_sg" {
	name        = "wordpress_sg"
	description = "Allow HTTP inbound traffic"
	vpc_id      = "${aws_vpc.uconecicdnet.id}"

	ingress {
	  from_port   = 80
    	  to_port     = 80
    	  protocol    = "tcp"
    	  cidr_blocks = ["0.0.0.0/0"]
  	}
	
	ingress {
	  from_port   = 22
    	  to_port     = 22
    	  protocol    = "tcp"
    	  cidr_blocks = ["13.234.217.54/32"]
  	}

  	egress {
    	  from_port       = 0
    	  to_port         = 0
    	  protocol        = "-1"
    	  cidr_blocks     = ["0.0.0.0/0"]
 	}

	tags = {
   	  Name = "cicdsg"
          CreatedBy = "Sumanth"
          Purpose = "PipelineDemo"
        }
}


#Security group creation for MySQL server
resource "aws_security_group" "cicd_sg_1" {
	name        = "mysql_sg"
	description = "Allow HTTP inbound traffic"
	vpc_id      = "${aws_vpc.uconecicdnet.id}"

	ingress {
	  from_port   = 3306
    	  to_port     = 3306
    	  protocol    = "tcp"
    	  cidr_blocks = ["0.0.0.0/0"]
  	}
	
	ingress {
	  from_port   = 22
    	  to_port     = 22
    	  protocol    = "tcp"
    	  cidr_blocks = ["13.234.217.54/32"]
  	}

  	egress {
    	  from_port       = 0
    	  to_port         = 0
    	  protocol        = "-1"
    	  cidr_blocks     = ["0.0.0.0/0"]
 	}

	tags = {
   	  Name = "cicdsg"
          CreatedBy = "Sumanth"
          Purpose = "PipelineDemo"
        }
}


# Provision an Apache2-PHP EC2 instance within the newly created VPC
resource "aws_instance" "wordpress_instance" {
	ami	= "${data.aws_ami.ublampami.id}"
	instance_type	= "t2.micro"
	associate_public_ip_address = "true"
	subnet_id = "${aws_subnet.cicdnetworkpublicsubnet.id}"
	depends_on = ["aws_internet_gateway.cicdgw"]
	vpc_security_group_ids = ["${aws_security_group.cicd_sg.id}"]

	tags = {
    	  Name = "wordpress_server"
    	  CreatedBy = "Sumanth"
    	  Purpose = "PipelineDemo"
	}
}

# Provision an MySQL EC2 instance within the newly created VPC
resource "aws_instance" "mysql_instance" {
	ami	= "${data.aws_ami.mysqlami.id}"
	instance_type	= "t2.micro"
	associate_public_ip_address = "true"
	subnet_id = "${aws_subnet.cicdnetworkprivatesubnet.id}"
	vpc_security_group_ids = ["${aws_security_group.cicd_sg_1.id}"]

	tags = {
    	  Name = "mysql_server"
    	  CreatedBy = "Sumanth"
    	  Purpose = "PipelineDemo"
	}
}

# Provision Classic Load Balancer
resource "aws_elb" "cicdclassicelb" {
  name          = "cicdpipelineelb"
  subnets = ["${aws_subnet.cicdnetworkpublicsubnet.id}"]

  listener {
    instance_port     = 80
    instance_protocol = "http"
    lb_port           = 80
    lb_protocol       = "http"
  }

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    target              = "TCP:80"
    interval            = 30
  }

  security_groups	= ["${aws_security_group.cicd_sg.id}"]
  instances                   = ["${aws_instance.wordpress_instance.id}"]
  cross_zone_load_balancing   = true
  idle_timeout                = 400
  connection_draining         = true
  connection_draining_timeout = 400

  tags = {
    Name = "cicdclassicelb"
    CreatedBy = "Sumanth"
    Purpose = "PipelineDemo"
  }
}

#Display the output of public dns of ELB
output "aws_elb_dns_name" {
	value = "${aws_elb.cicdclassicelb.dns_name}"
}

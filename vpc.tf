provider "aws" {
    region = "ap-south-1"
    profile = "vineet"
    access_key="AKIAVUGHJUYXZLPEKIGN"
    secret_key="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"
}

#VPC
resource "aws_vpc" "taskvpc" {
    cidr_block = "192.168.0.0/16"
    instance_tenancy = "default"
    enable_dns_hostnames = "true" 
tags = {
    Name = "taskvpc"
}
}

#PublicSubnet
resource "aws_subnet" "task_public_subnet" {
    vpc_id = aws_vpc.taskvpc.id
    cidr_block = "192.168.0.0/24"
    availability_zone = "ap-south-1a"
    map_public_ip_on_launch = "true"
    depends_on = [
        aws_vpc.taskvpc,
    ]
    tags = {
        Name = "task_public_subnet"
    }
}

#PrivateSubnet
resource "aws_subnet" "task_private" {
    vpc_id = aws_vpc.taskvpc.id
    cidr_block = "192.168.1.0/24"
    availability_zone = "ap-south-1b"
    depends_on = [
        aws_vpc.taskvpc,
    ]
    tags = {
        Name = "task_private_subnet"
    }
}

#InternetGatewayForVPC
resource "aws_internet_gateway" "task_ig" {
    vpc_id = aws_vpc.taskvpc.id
    depends_on = [
        aws_vpc.taskvpc,
    ]
    tags = {
        Name = "task_ig"
    }
}

#RoutingTableForPublicSubnet
resource "aws_route_table" "task_rt" {
    vpc_id=aws_vpc.taskvpc.id

    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.task_ig.id
    }

    depends_on = [
        aws_vpc.taskvpc,
    ]
    tags = {
        Name = "task_rt"
    }
}

#AssociatingRouteTableWithPublicSubnet
resource "aws_route_table_association" "task_assoc" {
    subnet_id = aws_subnet.task_public_subnet.id
    route_table_id = aws_route_table.task_rt.id
    depends_on = [
        aws_subnet.task_public_subnet,
    ]
}

#SecurityGroupForWordPress
resource "aws_security_group" "wordpress_sg" {
    name = "wordpress_sg"
    description = "allow ssh and http to wordpress instance"
    vpc_id = aws_vpc.taskvpc.id

    ingress {
        description = "for ssh"
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    
    ingress {
        description = "for http"
        from_port = 80
        to_port = 80
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
    depends_on = [
        aws_vpc.taskvpc,
        ]
    tags = {
            Name = "wordpress_sg"
        }
}

#SecurityGroupForMySQL
resource "aws_security_group" "mysql_sg"{
    name = "mysql_sg"
    description = "allow wordpress to access mysql instance"
    vpc_id = aws_vpc.taskvpc.id

    ingress {
        description = "to allow wordpress instance on mysql port"
        from_port = 3306
        to_port = 3306
        protocol = "tcp"
        security_groups = [aws_security_group.wordpress_sg.id]
    }
    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks=["0.0.0.0/0"]
    }
    depends_on = [
        aws_vpc.taskvpc,
        aws_security_group.wordpress_sg,
    ]
    tags = {
        Name = "mysql_sg"
    }
}

#WordPress Instance

resource "aws_instance" "wordpress_instance" {
  ami           = "ami-08675056b989a552a"
  instance_type = "t2.micro"
  key_name = "key1"
  vpc_security_group_ids = [ aws_security_group.wordpress_sg.id ]
  subnet_id = aws_subnet.task_public_subnet.id
  depends_on = [ aws_subnet.task_public_subnet ]

  tags = {
    Name = "WordPress"
  }
}

#MySQL Instance

resource "aws_instance" "mysql_instance" {
  ami           = "ami-028e055cfe9eec3c3"
  instance_type = "t2.micro"
  vpc_security_group_ids = [ aws_security_group.mysql_sg.id ]
  subnet_id = aws_subnet.task_private.id
  depends_on = [ aws_subnet.task_private ]

  tags = {
    Name = "MySQL"
  }
}
resource "aws_vpc" "main"{
    cidr_block          = "10.0.0.0/16"
    enable_dns_support  = true
    enable_dns_hostnames = true
    
    tags = {
        Project     = "motorsport"
        Environment = "dev"
    }
}

resource "aws_subnet" "public" {
    vpc_id                  = aws_vpc.main.id
    cidr_block              = "10.0.1.0/24"
    availability_zone       = "us-east-2a"
    map_public_ip_on_launch = true

    tags = {
        Project     = "motorsport"
        Environment = "dev"
    }
}

resource "aws_subnet" "private" {
    vpc_id                  = aws_vpc.main.id
    cidr_block              = "10.0.2.0/24"
    availability_zone       = "us-east-2a"

    tags = {
        Project     = "motorsport"
        Environment = "dev"
    }
}

resource "aws_internet_gateway" "main" {
    vpc_id = aws_vpc.main.id

    tags = {
        Project     = "motorsport"
        Environment = "dev"
    }
}

resource "aws_route_table" "public" {
    vpc_id = aws_vpc.main.id
    
    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.main.id
    }

    tags = {
        Project     = "motorsport"
        Environment = "dev"
    }
}

resource "aws_route_table_association" "public" {
    subnet_id      = aws_subnet.public.id
    route_table_id = aws_route_table.public.id
}

resource "aws_security_group" "ec2" {
    name        = "motorsport-ec2-sg"
    description = "Security group for data generators"
    vpc_id      = aws_vpc.main.id

    ingress {
        description = "SSH from my IP"
        from_port   = 22
        to_port     = 22
        protocol    = "tcp"
        cidr_blocks = ["${var.my_ip}/32"]
    }
    
    egress {
        description = "Allow all outbound"
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }

    tags = {
        Project     = "motorsport"
        Environment = "dev"
    }
}

resource "aws_security_group" "rds" {
    name        = "motorsport-rds-sg"
    description = "Security group for CDC table"
    vpc_id      = aws_vpc.main.id

    ingress {
        description    = "Allow only from EC2 data generators"
        from_port      = 5432
        to_port        = 5432
        protocol       = "tcp"
        security_groups = [aws_security_group.ec2.id]
    }

    egress {
        description = "Allow all outbound"
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
}

resource "aws_subnet" "private_b" {
    vpc_id = aws_vpc.main.id
    cidr_block = "10.0.3.0/24"
    availability_zone = "us-east-2b"

    tags = {
        Project     = "motorsport"
        Environment = "dev"
    }
}

resouce "aws_db_subnet_group" "motorsport" {
    name = "motorsport-rds-subnet-group"
    subnet_ids = [aws_subnet.private.id, aws_subnet.private_b.id]

    tags = {
        Project     = "motorsport"
        Environment = "dev"
    }
}
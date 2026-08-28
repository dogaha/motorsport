resource "aws_key_pair" "main" {
    key_name    = "motorsport-ec2-key"
    public_key  = file("~/.ssh/motorsport-ec2.pub")

    tags = {
        Project = "motorsport"
        environment= "dev"
    }
}

resource "aws_instance" "main" {
    ami                     = "ami-0d1f29d2140159d6d"
    instance_type           = "t3.micro"
    subnet_id               = aws_subnet.public.id
    vpc_security_group_ids  = [aws_security_group.ec2.id]
    key_name                = aws_key_pair.main.key_name
    iam_instance_profile    = aws_iam_instance_profile.ec2.name
    
    tags = {
        Project = "motorsport"
        environment= "dev"
    }
}
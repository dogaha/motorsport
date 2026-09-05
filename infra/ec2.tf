resource "aws_key_pair" "main" {
    key_name    = "motorsport-ec2-key"
    public_key  = file("~/.ssh/motorsport-ec2.pub")

    tags = {
        Project = "motorsport"
        environment= "dev"
    }
}

resource "aws_instance" "main" {
    ami                         = "ami-0e508bdf5a1337e6b"
    instance_type               = "m7i-flex.large"
    subnet_id                   = aws_subnet.public.id
    vpc_security_group_ids      = [aws_security_group.ec2.id]
    key_name                    = aws_key_pair.main.key_name
    iam_instance_profile        = aws_iam_instance_profile.ec2.name
    user_data_replace_on_change = true
    
    user_data = <<-EOF
        #!/bin/bash
        dnf update -y
        dnf install -y docker
        systemctl enable docker
        systemctl start docker
        usermod -aG docker ec2-user
    EOF

    tags = {
        Project = "motorsport"
        environment= "dev"
    }
}
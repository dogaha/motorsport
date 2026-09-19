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
    depends_on = [aws_db_instance.motorsport]

    user_data_replace_on_change = true
    metadata_options {
       http_put_response_hop_limit = 2
       http_tokens                 = "required"
    }

    user_data = <<-EOF
        #!/bin/bash
        set -euxo pipefail

        dnf update -y
        dnf install -y docker git
        systemctl enable --now docker
        usermod -aG docker ec2-user

        mkdir -p /usr/local/lib/docker/cli-plugins
        curl -SL https://github.com/docker/compose/releases/latest/download/docker-compose-linux-x86_64 -o /usr/local/lib/docker/cli-plugins/docker-compose
        curl -SL https://github.com/docker/buildx/releases/download/v0.37.1/buildx-v0.37.1.linux-amd64 -o /usr/local/lib/docker/cli-plugins/docker-buildx
        chmod +x /usr/local/lib/docker/cli-plugins/*

        git clone https://github.com/dogaha/motorsport /opt/motorsport
        cd /opt/motorsport
        docker compose up -d --build
    EOF

    tags = {
        Project = "motorsport"
        environment= "dev"
    }
}
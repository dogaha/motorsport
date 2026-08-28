resource "aws_key_pair" "main" {
    key_name    = "motorsport-ec2-key"
    public_key  = file("~/.ssh/motorsport-ec2.pub")

    tags = {
        Project = "motorsport"
        environment= "dev"
    }
}
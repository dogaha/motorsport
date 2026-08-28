resource "aws_iam_role" "ec2" {
    name = "motorsport-ec2-role"

    assume_role_policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
            {
                Action = "sts:AssumeRole"
                Effect = "Allow"
                Principal = {
                    Service = "ec2.amazonaws.com"
                }
            }
        ]
    })

    tags = {
        Project     = "motorsport"
        Environment = "dev"
    }
}

resource "aws_iam_role_policy" "ec2_s3" {
    name = "motorsport-ec2-s3-access"
    role = aws_iam_role.ec2.id

    policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
            {
                Effect = "Allow"
                Action = [
                    "s3:GetObject",
                    "s3:PutObject",
                    "s3:ListBucket"
                ]
                Resource = [
                    "arn:aws:s3:::motorsport-data-lake",
                    "arn:aws:s3:::motorsport-data-lake/*"
                ]
            }
        ]
    })
}
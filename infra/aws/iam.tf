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

resource "aws_iam_role_policy" "ec2_secret" {
  name = "motorsport-ec2-secrets-access"
  role = aws_iam_role.ec2.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue"
        ]
        Resource = [
          aws_secretsmanager_secret.rds_credentials.arn,
          "arn:aws:secretsmanager:us-east-2:038774852543:secret:motorsport-confluent-*"
        ]
      }
    ]
  })
}

resource "aws_iam_instance_profile" "ec2" {
  name = "motorsport-ec2-profile"
  role = aws_iam_role.ec2.name

  tags = {
    Project     = "motorsport"
    Environment = "dev"
  }
}


variable "databricks_uc_master_role_arn" {
  type = string
}

variable "databricks_uc_external_id" {
  type = string
}

resource "aws_iam_role" "databricks_uc" {
  name = "motorsport-databricks-uc"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        AWS = [
          var.databricks_uc_master_role_arn,
          #"arn:aws:iam::038774852543:role/motorsport-databricks-uc",
        ]
      }
      Action = "sts:AssumeRole"
      Condition = {
        StringEquals = { "sts:ExternalId" = var.databricks_uc_external_id }
      }
    }]
  })
}

resource "aws_iam_role_policy" "databricks_uc_s3" {
  name = "motorsport-databricks-uc-s3"
  role = aws_iam_role.databricks_uc.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["s3:GetObject", "s3:PutObject", "s3:DeleteObject"]
        Resource = "arn:aws:s3:::motorsport-data-lake/*"
      },
      {
        Effect   = "Allow"
        Action   = ["s3:ListBucket", "s3:GetBucketLocation"]
        Resource = "arn:aws:s3:::motorsport-data-lake"
      }
    ]
  })
}
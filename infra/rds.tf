resource "random_password" "rds_master" {
    length              = 32
    special             = true
    override_special    = "!#$%&*()-_=+[]{}<>:?"
}

resource "aws_secretsmanager_secret" "rds_credentials" {
    name        = "motorsport-rds-credentials"
    description = "master credentials for motorsport RDS Postgres instance"
    
    tags = {
        Project     = "motorsport"
        Environment = "dev"
    }
}

resource "aws_secretsmanager_secret_version" "rds_credentials" {
    secret_id = aws_secretsmanager_secret.rds_credentials.id
    secret_string = jsonencode({
        username    = "motortsport_master"
        password    = random_password.rds_master.result
        engine      = "postges"
        host        = aws_db_instance.motorsport.address
        port        = aws_db_instance.motorsport.port
        dbname      = "motorsport_database"
    })
}

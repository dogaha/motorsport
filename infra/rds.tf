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

resource "aws_db_parameter_group" "motorsport" {
    name = "motorsport-postgres17"
    family = "postgres17"

    tags = {
        Project     = "motorsport"
        Environment = "dev"
    }
}

resouce "aws_db_instance" "motorsport" {
    identifier = "motorsport-postges"
    engine = "postgres"
    engine_version = "17.11"

    instance_class = "db.t4g.micro"
    allocated_storrage = 20
    storage_type = "gp3"

    db_name = "motorsport_database"
    username = "motorsport_master"
    password = random_password.rds_master.result

    db_subnet_group_name = aws_db_subnet_group.motorsport.name
    vpc_security_group_ids = [aws_security_group.rds.id]
    parameter_group_name = aws_db_parameter_group.motorsport.name
}
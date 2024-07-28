output "ec2_public_ip" {

  value = aws_instance.postgres_ec2_instance[0].public_ip
}

output "database_endpoint" {
  value = aws_db_instance.postgres_db.address
}
output "database_port" {
  value = aws_db_instance.postgres_db.port
}
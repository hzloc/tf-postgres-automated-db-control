output "ec2_public_ip" {

  value = aws_instance.postgres_ec2_instance[0].public_ip
}

output "database_endpoint" {
  value = aws_db_instance.postgres_db.address
}
output "database_port" {
  value = aws_db_instance.postgres_db.port
}

output "ecr_repository_name" {
  value = aws_ecr_repository.db_migration_repository.name
}

output "created_subnet_group_name" {
  value = aws_db_subnet_group.postgres_sg.name
}

output "lambda_invoke_url" {
  value = aws_lambda_function.db_migration_lambda.invoke_arn
}

output "ecr_rep_url" {
  value = aws_ecr_repository.db_migration_repository.repository_url
}

output "lambda_function_name" {
  value = aws_lambda_function.db_migration_lambda.function_name
}

output "latest_image_uri" {
  value = "${aws_ecr_repository.db_migration_repository.repository_url}:${data.aws_ecr_image.service_image.image_tag}"
}
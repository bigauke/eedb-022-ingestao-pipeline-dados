output "database_name" {
  description = "Nome do Banco de Dados DW"
  value       = var.db_name
}

output "schemas_created" {
  description = "Schemas criados declarativamente pelo Terraform"
  value       = [postgresql_schema.staging.name, postgresql_schema.dw.name]
}

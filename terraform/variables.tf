variable "db_host" {
  description = "Host do banco de dados PostgreSQL"
  type        = string
  default     = "localhost"
}

variable "db_port" {
  description = "Porta do PostgreSQL"
  type        = number
  default     = 5432
}

variable "db_name" {
  description = "Nome do banco de dados DW"
  type        = string
  default     = "eedb_dw"
}

variable "db_user" {
  description = "Usuário do banco de dados"
  type        = string
  default     = "postgres"
}

variable "db_password" {
  description = "Senha do banco de dados"
  type        = string
  sensitive   = true
  default     = "postgres"
}

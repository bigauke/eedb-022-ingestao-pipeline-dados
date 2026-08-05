terraform {
  required_version = ">= 1.0.0"
  required_providers {
    postgresql = {
      source  = "cyrilgdn/postgresql"
      version = "~> 1.22.0"
    }
  }
}

provider "postgresql" {
  host            = var.db_host
  port            = var.db_port
  database        = var.db_name
  username        = var.db_user
  password        = var.db_password
  sslmode         = "disable"
  connect_timeout = 15
}

# Declarar Schema Staging
resource "postgresql_schema" "staging" {
  name  = "staging"
  owner = var.db_user
}

# Declarar Schema Data Warehouse
resource "postgresql_schema" "dw" {
  name  = "dw"
  owner = var.db_user
}

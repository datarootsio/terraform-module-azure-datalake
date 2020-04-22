variable "data_lake_name" {
  description = "Name of the data lake (has to be globally unique)"
  type        = string
}

variable "region" {
  description = "Region in which to create the resources"
  type        = string
}

variable "service_principal_end_date" {
  description = "End date of when the service principal is valid, formatted as a RFC3339 date string (e.g. 2018-01-01T01:02:03Z). Changing this field forces a new resource to be created."
  type        = string
}

variable "storage_replication" {
  description = "Type of replication for the storage accounts. See https://www.terraform.io/docs/providers/azurerm/r/storage_account.html#account_replication_type"
  type        = string
}

variable "data_warehouse_dtu" {
  description = "Service objective (DTU) for the created data warehouse (e.g. DW100c)"
  type        = string
  default     = "DW100c"
}

variable "cosmosdb_consistency_level" {
  description = "Default consistency level for the CosmosDB account"
  type        = string
  default     = "Session"
}

variable "cosmosdb_db_throughput" {
  description = "Throughput for the database inside CosmosDB"
  type        = number
  default     = 400
}
variable "databricks_sku" {
  description = "SKU of the Databricks workspace (e.g. 'standard' or 'premium')"
  type        = string
  default     = "standard"
}

variable "data_lake_filesystems" {
  type        = list
  description = "A list of filesystems to create inside the storage account"
  default     = ["default"]
}
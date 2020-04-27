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

variable "data_lake_fs_raw" {
  type        = string
  description = "Name of the data lake filesystem with raw data"
  default     = "raw"
}

variable "data_lake_fs_cleansed" {
  type        = string
  description = "Name of the data lake filesystem with cleansed data"
  default     = "cleansed"
}

variable "data_lake_fs_transformed" {
  type        = string
  description = "Name of the data lake filesystem with transformed data"
  default     = "transformed"
}

variable "data_lake_filesystems" {
  type        = list
  description = "A list of filesystems to create inside the storage account besides the 3 default ones (raw, cleansed, transformed)"
  default     = []
}

variable "sql_server_admin_username" {
  type        = string
  description = "Username of the administrator of the SQL server"
}

variable "sql_server_admin_password" {
  type        = string
  description = "Password of the administrator of the SQL server"
}

variable "databricks_cluster_version" {
  type        = string
  description = "Runtime version of the Databricks cluster"
}

variable "databricks_cluster_node_type" {
  type        = string
  description = "Node type of the Databricks cluster machines"
}

locals {
  # Common tags to be assigned to all resources
  common_tags = {
    DataLake = var.data_lake_name
  }

  data_lake_fs_merged = distinct(concat([var.data_lake_fs_raw, var.data_lake_fs_cleansed, var.data_lake_fs_transformed], var.data_lake_filesystems))
  data_lake_fs_names  = [for s in local.data_lake_fs_merged : "fs${s}${var.data_lake_name}"]
}

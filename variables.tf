# Naming & components

variable "data_lake_name" {
  description = "Name of the data lake (has to be globally unique)"
  type        = string
}

variable "region" {
  description = "Region in which to create the resources"
  type        = string
}

variable "provision_sample_data" {
  description = "Boolean to indicate if a sample data pipeline should be deployed. Note that enable_synapse also has to be true for this (default: true)."
  type        = bool
  default     = true
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

variable "databricks_cluster_version" {
  type        = string
  description = "Runtime version of the Databricks cluster"
}

variable "provision_synapse" {
  type        = bool
  description = "Set this to false to disable the creation of the Synapse Analytics instance. Without this, the sample data will not be created."
  default     = true
}

# Pricing, performance and replication

variable "storage_replication" {
  description = "Type of replication for the storage accounts. See https://www.terraform.io/docs/providers/azurerm/r/storage_account.html#account_replication_type"
  type        = string
}

variable "data_warehouse_dtu" {
  description = "Service objective (DTU) for the created data warehouse (e.g. DW100c)"
  type        = string
  default     = null
}

variable "cosmosdb_consistency_level" {
  description = "Default consistency level for the CosmosDB account"
  type        = string
}

variable "cosmosdb_db_throughput" {
  description = "Throughput for the database inside CosmosDB"
  type        = number
}

variable "databricks_sku" {
  description = "SKU of the Databricks workspace (e.g. 'standard' or 'premium')"
  type        = string
}

variable "databricks_cluster_node_type" {
  type        = string
  description = "Node type of the Databricks cluster machines"
}

# Security

variable "use_existing_service_principal" {
  type        = bool
  description = "Should Terraform create the SP or use an existing one, provided by variables ?"
  default     = false
}

variable "application_id" {
  type        = string
  description = "Existing application ID"
  default     = ""
}

variable "service_principal_id" {
  type        = string
  description = "Existing service principal ID"
  default     = ""
}

variable "service_principal_secret" {
  type        = string
  description = "Existing service principal secret"
  default     = ""
}

variable "service_principal_end_date" {
  description = "End date of when the service principal is valid, formatted as a RFC3339 date string (e.g. 2018-01-01T01:02:03Z). Changing this field forces a new resource to be created."
  type        = string
}

variable "databricks_token_lifetime" {
  description = "Lifetime (in seconds) of the Databricks access token that will be created for communication with other services in the data lake."
  type        = number
}

variable "sql_server_admin_username" {
  type        = string
  description = "Username of the administrator of the SQL server"
  default     = null
}

variable "sql_server_admin_password" {
  type        = string
  description = "Password of the administrator of the SQL server"
  default     = null
}

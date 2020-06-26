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

variable "data_lake_fs_curated" {
  type        = string
  description = "Name of the data lake filesystem with curated data"
  default     = "curated"
}

variable "data_lake_filesystems" {
  type        = list
  description = "A list of filesystems to create inside the storage account besides the 3 default ones (raw, cleansed, curated)"
  default     = []
}

variable "databricks_cluster_version" {
  type        = string
  description = "Runtime version of the Databricks cluster"
  default     = "7.0.x-scala2.12"
}

variable "provision_synapse" {
  type        = bool
  description = "Set this to false to disable the creation of the Synapse Analytics instance. Without this, the sample data will not be created."
  default     = true
}

variable "extra_tags" {
  description = "Extra tags that you would like to add to all created resources."
  type        = map
  default     = {}
}

variable "provision_data_factory_links" {
  type        = bool
  default     = true
  description = "Set this to false to disable the creation of linked services inside Data Factory. Setting this to false also disables the sample data."
}

variable "databricks_libraries" {
  type        = list
  default     = []
  description = "Extra libraries to install on the Databricks cluster"
}

variable "databricks_log_path" {
  type        = string
  default     = ""
  description = "Optional dbfs path where the Databricks cluster should store logs. The path should start with `dbfs:/`"
}

variable "provision_databricks" {
  type        = bool
  default     = true
  description = "Optionally disable provisioning of all Databricks related resources"
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

variable "databricks_cluster_driver_node_type" {
  type        = string
  description = "Node type of the Databricks driver if different from the workers"
  default     = ""
}

variable "databricks_cosmosdb_spark_version" {
  type        = string
  description = "Version of com.microsoft.azure:azure-cosmosdb-spark_2.4.0_2.11 to install to the Databricks cluster"
  default     = "3.0.5"
}

variable "databricks_autotermination_minutes" {
  type        = number
  description = "After this amount of minutes, the cluster will terminate"
  default     = 120
}

variable "databricks_min_workers" {
  type        = number
  description = "Minimum amount of workers in an active cluster"
  default     = 2
}

variable "databricks_max_workers" {
  type        = number
  description = "Maximum amount of workers in an active cluster"
  default     = 4
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

variable "key_vault_id" {
  type        = string
  default     = ""
  description = "ID of the optional Key Vault. The module will store all relevant secrets inside this Key Vault and output the keys."
}

variable "use_key_vault" {
  type        = bool
  default     = false
  description = "Set this to true to enable the usage of your existing Key Vault"
}

# Data Factory VSTS

variable "data_factory_vsts_account_name" {
  type        = string
  default     = ""
  description = "Optional account name for the VSTS back-end for the created Azure Data Factory. You need to fill in all other data_factory_vsts_ variables if you use this one."
}

variable "data_factory_vsts_branch_name" {
  type        = string
  default     = ""
  description = "Optional branch name for the VSTS back-end for the created Azure Data Factory. You need to fill in all other data_factory_vsts_ variables if you use this one."
}

variable "data_factory_vsts_project_name" {
  type        = string
  default     = ""
  description = "Optional project name for the VSTS back-end for the created Azure Data Factory. You need to fill in all other data_factory_vsts_ variables if you use this one."
}

variable "data_factory_vsts_repository_name" {
  type        = string
  default     = ""
  description = "Optional repository name for the VSTS back-end for the created Azure Data Factory. You need to fill in all other data_factory_vsts_ variables if you use this one."
}

variable "data_factory_vsts_root_folder" {
  type        = string
  default     = ""
  description = "Optional root folder for the VSTS back-end for the created Azure Data Factory. You need to fill in all other data_factory_vsts_ variables if you use this one."
}

variable "data_factory_vsts_tenant_id" {
  type        = string
  default     = null
  description = "Optional tenant ID for the VSTS back-end for the created Azure Data Factory. You need to fill in all other data_factory_vsts_ variables if you use this one."
}

# Data Factory GitHub
variable "data_factory_github_account_name" {
  type        = string
  default     = ""
  description = "Optional account name for the GitHub back-end for the created Azure Data Factory. You need to fill in all other data_factory_github_ variables if you use this one."
}

variable "data_factory_github_branch_name" {
  type        = string
  default     = ""
  description = "Optional branch name for the GitHub back-end for the created Azure Data Factory. You need to fill in all other data_factory_github_ variables if you use this one."
}

variable "data_factory_github_git_url" {
  type        = string
  default     = ""
  description = "Optional Git URL (either https://github.mycompany.com or https://github.com) for the GitHub back-end for the created Azure Data Factory. You need to fill in all other data_factory_github_ variables if you use this one."
}

variable "data_factory_github_repository_name" {
  type        = string
  default     = ""
  description = "Optional repository name for the GitHub back-end for the created Azure Data Factory. You need to fill in all other data_factory_github_ variables if you use this one."
}

variable "data_factory_github_root_folder" {
  type        = string
  default     = ""
  description = "Optional root folder for the GitHub back-end for the created Azure Data Factory. You need to fill in all other data_factory_github_ variables if you use this one."
}

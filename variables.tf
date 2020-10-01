variable "data_lake_name" {
  description = "Name of the data lake (has to be globally unique)"
  type        = string
}

variable "region" {
  description = "Region in which to create the resources"
  type        = string
}

variable "data_lake_filesystems" {
  type        = list(string)
  description = "A list of filesystems to create inside the storage account"
  default     = ["raw", "clean", "curated", "integration", "aggregation"]
}

variable "databricks_cluster_version" {
  type        = string
  description = "Runtime version of the Databricks cluster"
  default     = "7.2.x-scala2.12"
}

variable "provision_synapse" {
  type        = bool
  description = "Set this to false to disable the creation of the Synapse Analytics instance."
  default     = true
}

variable "extra_tags" {
  description = "Extra tags that you would like to add to all created resources."
  type        = map(string)
  default     = {}
}

variable "provision_data_factory_links" {
  type        = bool
  default     = true
  description = "Set this to false to disable the creation of linked services inside Data Factory."
}

variable "databricks_log_path" {
  type        = string
  default     = ""
  description = "Optional dbfs path where the Databricks cluster should store logs. The path should start with `dbfs:/`"
}

variable "use_log_analytics" {
  type        = bool
  default     = false
  description = "Set this to true to store logs in Log Analytics"
}

variable "log_analytics_workspace_id" {
  type        = string
  default     = ""
  description = "Optional Log Analytics Workspace ID where logs are stored"
}

variable "cosmosdb_partition_key" {
  type        = string
  default     = "/sourceTimestamp"
  description = "Set the partition key for the Cosmos DB metadata collection"
}

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

variable "databricks_sku" {
  description = "SKU of the Databricks workspace (e.g. 'standard' or 'premium')"
  type        = string
  default     = "standard"
}

variable "databricks_cluster_node_type" {
  type        = string
  description = "Node type of the Databricks cluster machines"
  default     = "Standard_F4s"
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

variable "service_principal_client_id" {
  type        = string
  description = "Client ID of the existing service principal that will be used for communication between services"
}

variable "service_principal_object_id" {
  type        = string
  description = "Object ID of the existing service principal that will be used for communication between services"
}

variable "service_principal_client_secret" {
  type        = string
  description = "Client secret of the existing service principal that will be used for communication between services"
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

variable "key_vault_depends_on" {
  default     = null
  description = "Optionally set to a dependency for the Key Vault secrets (e.g. access policy)"
}

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

variable "extra_storage_contributor_ids" {
  description = "Extra contributors to the storage account"
  type        = list(string)
  default     = []
}

variable "dl_acl" {
  description = "Optional set of ACL to set on the filesystem roots inside the data lake. This is applied before dl_directories. The value is a map where the key is the name of the filesytem and the value is the ACL to set."
  type        = map(string)
  default     = {}
}

variable "dl_directories" {
  description = "Optional root directories to be created inside the data lake. The value is a map where the keys are the names of the filesystems. The values are maps as well. In these nested maps, the keys are the names of the directories and the values are the ACL to set. Leave this empty to not set any ACL explicitly."
  type        = map(map(string))
  default     = {}
}

variable "databricks_workspace_name" {
  description = "Due to changes in how Terraform modules can use provider configurations, the module is not able to provision a Databricks workspace. Please provide the name of a Databricks workspace here to setup all Databricks related features. Also make sure to correctly configure the Terraform Databricks provider."
  type        = string
  default     = ""
}

variable "databricks_workspace_resource_group_name" {
  description = "Due to changes in how Terraform modules can use provider configurations, the module is not able to provision a Databricks workspace. Please provide the name the resource group of a Databricks workspace here to setup all Databricks related features. By default it will use the resource_group_name variable. Also make sure to correctly configure the Terraform Databricks provider."
  type        = string
  default     = ""
}

variable "resource_group_name" {
  description = "Name of the resource group where the resources should be created"
  type        = string
}

# Configuration options

   * [Configuration options](#configuration-options)
      * [Required arguments](#required-arguments)
         * [data_lake_name](#data_lake_name)
         * [region](#region)
         * [storage_replication](#storage_replication)
         * [databricks_cluster_version](#databricks_cluster_version)
         * [databricks_sku](#databricks_sku)
         * [databricks_cluster_node_type](#databricks_cluster_node_type)
         * [databricks_token_lifetime](#databricks_token_lifetime)
         * [cosmosdb_consistency_level](#cosmosdb_consistency_level)
         * [cosmosdb_db_throughput](#cosmosdb_db_throughput)
         * [data_warehouse_dtu](#data_warehouse_dtu)
         * [sql_server_admin_username](#sql_server_admin_username)
         * [sql_server_admin_password](#sql_server_admin_password)
         * [service_principal_end_date](#service_principal_end_date)
      * [Optional arguments](#optional-arguments)
         * [application_id](#application_id)
         * [service_principal_id](#service_principal_id)
         * [service_principal_secret](#service_principal_secret)
         * [provision_sample_data](#provision_sample_data)
         * [provision_synapse](#provision_synapse)
         * [data_lake_fs_raw](#data_lake_fs_raw)
         * [data_lake_fs_cleansed](#data_lake_fs_cleansed)
         * [data_lake_fs_transformed](#data_lake_fs_transformed)
         * [data_lake_filesystems](#data_lake_filesystems)


## Required arguments

### `data_lake_name`

The name of the data lake. This name will be used in every resource so that you can clearly distinguish which resources were created by this module.

Modifying this value after deployment will result in destroying and deploying the complete data lake.

Type: string\
Example: `"example name"`

### `region`

The primary Azure region in which to deploy the data lake. Further configuration options allow to use secondary regions for fail-over and replication purposes.

Modifying this value after deployment will result in destroying and deploying the complete data lake.

Type: string\
Example: `"eastus2"`

### `storage_replication`

Replication strategy to be used for the data lake storage.\
[Available options](https://docs.microsoft.com/en-us/azure/storage/common/storage-redundancy)

Type: string\
Example: `"ZRS"`

### `databricks_cluster_version`

Version of the Databricks runtime, required for the Databricks cluster.\
[Version syntax](https://docs.databricks.com/dev-tools/api/latest/index.html#programmatic-version)\
[Supported versions](https://docs.databricks.com/release-notes/runtime/releases.html#supported-list)

Type: string\
Example: `"6.5.x-scala2.11"`

### `databricks_sku`

The Azure SKU for the Databricks workspace.\
[Available SKUs](https://azure.microsoft.com/en-us/pricing/details/databricks/) (currently "standard" or "premium")

Type: string\
Example: `"standard"`

### `databricks_cluster_node_type`

The Azure SKU for the Databricks driver and workers.

Type: string\
Example: `"Standard_DS3_v2"`

### `databricks_token_lifetime`

Lifetime (in seconds) of the Databricks access token that will be created for communication with other services in the data lake.

Type: number\
Example: `315360000` (10 years)

### `cosmosdb_consistency_level`

Default consistency level for the CosmosDB account.\
[Available consistency levels](https://docs.microsoft.com/en-us/azure/cosmos-db/consistency-levels)

Type: string\
Example: `"Session"`

### `cosmosdb_db_throughput`

Provisioned request units for the CosmosDB account.\
[Request units](https://docs.microsoft.com/en-us/azure/cosmos-db/request-units)

Type: number\
Example: `400`

### `data_warehouse_dtu`

The provisioned Data Warehouse Units for the Azure Synapse Analytics instance. We recommend to scale this as you go.\
[Data Warehouse Units](https://docs.microsoft.com/en-us/azure/synapse-analytics/sql-data-warehouse/what-is-a-data-warehouse-unit-dwu-cdwu)

Required unless you disable the Synapse Analytics Instance with `provision_synapse` set to `false`\
Type: string\
Example: `"DW100c"`

### `sql_server_admin_username`

The admin username of the SQL server that hosts the Synapse Analytics instance.

Required unless you disable the Synapse Analytics Instance with `provision_synapse` set to `false`\
Type: string\
Example: `"theboss"`

### `sql_server_admin_password`

The password of the admin account of the SQL server that hosts the Synapse Analytics instance.

Required unless you disable the Synapse Analytics Instance with `provision_synapse` set to `false`\
Type: string\
Example: `"ThisIsA$ecret1"`

### `service_principal_end_date`

This module uses a service principal to allow communication between the different Azure services. The service principal will no longer be valid after this time.

Type: string\
Example: `"2030-01-01T00:00:00Z"`

## Optional arguments

### `provision_sample_data`

Whether to provision the sample data pipeline.

Type: bool\
Example: `false`\
Default: `true`

### `provision_synapse`

Whether to provision the Azure Synapse Analytics instance. Note that this has to be `true` for the sample data pipeline to be provisioned.

Type: bool\
Example: `false`\
Default: `true`

### `extra_tags`

Extra tags to add to all created resources.

Type: map\
Example: `{"somekey" = "somevalue"}`\
Default: `{}`

### `data_lake_fs_raw`

Name of the data lake filesystem that will contain the raw data. The name of the data lake itself will be appended.

Type: string\
Example: `"raw"`\
Default: `"raw"`

### `data_lake_fs_cleansed`

Name of the data lake filesystem that will contain the cleansed data. The name of the data lake itself will be appended.

Type: string\
Example: `"clean"`\
Default: `"clean"`

### `data_lake_fs_transformed`

Name of the data lake filesystem that will contain the transformed data. The name of the data lake itself will be appended.

Type: string\
Example: `"transformed"`\
Default: `"transformed"`

### `data_lake_filesystems`

A list of additional filesystems to be created in the data lake storage. The module will also make sure that credentials and secrets are deployed in a secure manner to other components to facilitate communication between the services.

Type: list\
Example: `["gdprcompliant", "presentation"]`\
Default: `[]`

## Existing Key Vault

You can optionally store all created keys and secrets to use the module components in an existing Azure Key Vault. We will also grant the necessary permissions to the Data Factory and the Service Principal to access the Key Vault. Please make sure that the account executing the Terraform has access to manage the Key Vault. The keys that have been created will be outputted.

### `key_vault_resource_group`

Name of the resource group in which the optional Key Vault has been created.
Type: string\
Example: `"rgkeyvault"`

### `key_vault_name`

Name of the optional Key Vault.
Type: string\
Example: `"keyvault"`

## Existing service principal

You can optionally use an existing service principal to allow communication between the different Azure services. If you don't provide one, one will be created for you.

### `use_existing_service_principal`

If you want to provide an existing one, set this to `true`.
Type: bool\
Example: `false`

### `application_id`

Application ID of the optional service principal.
Type: string\
Example: `"09bd45b3-c884-4454-a3ca-459f1a8e581a"`

### `service_principal_id`

Object ID of the optional service principal.
Type: string\
Example: `"09bd45b3-c884-4454-a3ca-459f1a8e581a"`

### `service_principal_password`

Client secret of the optional service principal.
Type: string\
Example: `"ThisIsA$ecret1"`

## Optional Data Factory Git back-ends

Use one of the sets of arguments below to configure a Git back-end for the created Azure Data Factory.

### Azure DevOps (Visual Studio Team Services)

#### `data_factory_vsts_account_name`

Optional account name for the VSTS back-end for the created Azure Data Factory. You need to fill in all other `data_factory_vsts_` variables if you use this one.

Type: string\
Example: `""`

#### `data_factory_vsts_branch_name`

Optional branch name for the VSTS back-end for the created Azure Data Factory. You need to fill in all other `data_factory_vsts_` variables if you use this one.

Type: string\
Example: `""`

#### `data_factory_vsts_project_name`

Optional project name for the VSTS back-end for the created Azure Data Factory. You need to fill in all other `data_factory_vsts_` variables if you use this one.

Type: string\
Example: `""`

#### `data_factory_vsts_repository_name`

Optional repository name for the VSTS back-end for the created Azure Data Factory. You need to fill in all other `data_factory_vsts_` variables if you use this one.

Type: string\
Example: `""`

#### `data_factory_vsts_root_folder`

Optional root folder for the VSTS back-end for the created Azure Data Factory. You need to fill in all other `data_factory_vsts_` variables if you use this one.

Type: string\
Example: `""`

#### `data_factory_vsts_tenant_id`

Optional tenant ID for the VSTS back-end for the created Azure Data Factory. You need to fill in all other `data_factory_vsts_` variables if you use this one.

Type: string\
Example: `""`

### GitHub

#### `data_factory_github_account_name`

Optional account name for the GitHub back-end for the created Azure Data Factory. You need to fill in all other `data_factory_github_` variables if you use this one.

Type: string\
Example: `""`

#### `data_factory_github_branch_name`

Optional branch name for the GitHub back-end for the created Azure Data Factory. You need to fill in all other `data_factory_github_` variables if you use this one.

Type: string\
Example: `""`

#### `data_factory_github_git_url`

Optional Git URL (either `https://github.mycompany.com` or `https://github.com`) for the GitHub back-end for the created Azure Data Factory. You need to fill in all other `data_factory_github_` variables if you use this one.

Type: string\
Example: `"https://github.com"`

#### `data_factory_github_repository_name`

Optional repository name for the GitHub back-end for the created Azure Data Factory. You need to fill in all other `data_factory_github_` variables if you use this one.

Type: string\
Example: `"myrepo"`

#### `data_factory_github_root_folder`

Optional root folder for the GitHub back-end for the created Azure Data Factory. You need to fill in all other `data_factory_github_` variables if you use this one.

Type: string\
Example: `"."`

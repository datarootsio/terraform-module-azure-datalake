# Configuration options

* [Required arguments](#required-arguments)
   * [data_lake_name](#data_lake_name)
   * [region](#region)
   * [storage_replication](#storage_replication)
   * [databricks_cluster_version](#databricks_cluster_version)
   * [databricks_sku](#databricks_sku)
   * [databricks_cluster_node_type](#databricks_cluster_node_type)
   * [cosmosdb_consistency_level](#cosmosdb_consistency_level)
   * [cosmosdb_db_throughput](#cosmosdb_db_throughput)
   * [data_warehouse_dtu](#data_warehouse_dtu)
   * [sql_server_admin_username](#sql_server_admin_username)
   * [sql_server_admin_password](#sql_server_admin_password)
   * [service_principal_end_date](#service_principal_end_date)
* [Optional arguments](#optional-arguments)


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

Please see [the Terraform registry page](https://registry.terraform.io/modules/datarootsio/azure-datalake/module/?tab=inputs)

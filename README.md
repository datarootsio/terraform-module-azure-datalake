# Terraform module Azure Data Lake

This is a module for Terraform that deploys a complete and opinionated data lake network on Microsoft Azure.

[![maintained by dataroots](https://img.shields.io/badge/maintained%20by-dataroots-%2300b189)](https://dataroots.io)
[![Terraform 0.12](https://img.shields.io/badge/terraform-0.12-%23623CE4)](https://www.terraform.io)
[![Terraform Registry](https://img.shields.io/badge/terraform-registry-%23623CE4)](https://registry.terraform.io/modules/datarootsio/azure-datalake/module/)
[![tests](https://github.com/datarootsio/terraform-module-azure-datalake/workflows/tests/badge.svg?branch=master)](https://github.com/datarootsio/terraform-module-azure-datalake/actions)
[![Go Report Card](https://goreportcard.com/badge/github.com/datarootsio/terraform-module-azure-datalake)](https://goreportcard.com/report/github.com/datarootsio/terraform-module-azure-datalake)

## Components

* Azure Data Factory for data ingestion from various sources
* 3 or more Azure Data Lake Storage gen2 containers to store raw, clean and transformed data
* Azure Databricks to clean and transform the data
* Azure Synapse Analytics to store presentation data
* Azure CosmosDB to store metadata
* Credentials and access management configured ready to go
* Sample data pipeline (optional)

This design is based on one of Microsoft's architecture patterns for an [advanced analytics](https://docs.microsoft.com/en-us/azure/architecture/solution-ideas/articles/advanced-analytics-on-big-data) solution.

![Microsoft Advanced Analytics pattern](https://docs.microsoft.com/en-us/azure/architecture/solution-ideas/media/advanced-analytics-on-big-data.png)

It includes some additional changes that [dataroots](https://dataroots.io) is recommending.

* Multiple storage containers to store every version of the data (raw, cleansed, transformed)
* Cosmos DB is used to store the metadata of the data as a Data Catalog
* Azure Analysis Services is not used for now as some services might be replaced when [Azure Synapse Analytics Workspace](https://docs.microsoft.com/en-us/azure/synapse-analytics/overview-what-is) becomes GA

## Usage

```hcl
module "azuredatalake" {
  source = "./azure-datalake/"

  data_lake_name = "example name"
  region         = "eastus2"

  storage_replication          = "ZRS"
  service_principal_end_date   = "2030-01-01T00:00:00Z"
  databricks_cluster_node_type = "Standard_DS3_v2"
  databricks_cluster_version   = "6.5.x-scala2.11"
  databricks_sku               = "standard"
  data_warehouse_dtu           = "DW100c"
  cosmosdb_consistency_level   = "Session"
  cosmosdb_db_throughput       = 400
  sql_server_admin_username    = "theboss"
  sql_server_admin_password    = "ThisIsA$ecret1"
}
```

## Requirements

The following providers have to be configured:
* [AzureRM](https://www.terraform.io/docs/providers/azurerm/index.html)
* [AzureAD](https://www.terraform.io/docs/providers/azuread/index.html)

The module is using the [Databricks Terraform provider](https://github.com/databrickslabs/databricks-terraform). This provider is not in the registry yet and would have to be installed manually. This can be done with the command below:

```sh
curl https://raw.githubusercontent.com/databrickslabs/databricks-terraform/master/godownloader-databricks-provider.sh | bash -s -- -b $HOME/.terraform.d/plugins
```

## Sample pipeline

The sample pipeline uses generated sales data. In the cleansing phase, personal information is removed and missing values are dealt with. In the transformation phase some aggregated values are calculated to show how each department and country is performing.

![Sample pipeline](assets/pipeline.png)

Finally, the data is presented in a Power BI dashboard. The dashboard cannot be deployed through Terraform, but you can find it [in the assets folder](assets/dashboard.pbix). You can follow [this guide](POWERBI.md) on how to open the report and connect it to the data lake.

![Power BI screenshot](assets/powerbi_screenshot.png)

## Configuration

The Azure tenant and subscription can be configured through the providers mentioned above.

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

### `provision_sample_data`

Whether to provision the sample data pipeline.

Type: bool\
Example: `false`\
Default: `true`

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

Type: string\
Example: `"DW100c"`

### `sql_server_admin_username`

The admin username of the SQL server that hosts the Synapse Analytics instance.

Type: string\
Example: `"theboss"`

### `sql_server_admin_password`

The password of the admin account of the SQL server that hosts the Synapse Analytics instance.

Type: string\
Example: `"ThisIsA$ecret1"`

### `service_principal_end_date`

This module uses a service principal to allow communication between the different Azure services. The service principal will no longer be valid after this time.

Type: string\
Example: `"2030-01-01T00:00:00Z"`

## License

MIT license. Please see [LICENSE](LICENSE.md) for details.

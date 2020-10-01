# Terraform module Azure Data Lake

This is a module for Terraform that deploys a complete and opinionated data lake network on Microsoft Azure.

[![maintained by dataroots](https://img.shields.io/badge/maintained%20by-dataroots-%2300b189)](https://dataroots.io)
[![Terraform 0.13](https://img.shields.io/badge/terraform-0.13-%23623CE4)](https://www.terraform.io)
[![Terraform Registry](https://img.shields.io/badge/terraform-registry-%23623CE4)](https://registry.terraform.io/modules/datarootsio/azure-datalake/module/)
[![tests](https://github.com/datarootsio/terraform-module-azure-datalake/workflows/tests/badge.svg?branch=master)](https://github.com/datarootsio/terraform-module-azure-datalake/actions)
[![Go Report Card](https://goreportcard.com/badge/github.com/datarootsio/terraform-module-azure-datalake)](https://goreportcard.com/report/github.com/datarootsio/terraform-module-azure-datalake)

## Components

* Azure Data Factory for data ingestion from various sources
* Azure Data Lake Storage gen2 containers to store data for the data lake layers
* Azure Databricks to clean and transform the data
* Azure Synapse Analytics to store presentation data
* Azure CosmosDB to store metadata
* Credentials and access management configured ready to go

This design is based on one of Microsoft's architecture patterns for an [advanced analytics](https://docs.microsoft.com/en-us/azure/architecture/solution-ideas/articles/advanced-analytics-on-big-data) solution.

![Microsoft Advanced Analytics pattern](https://docs.microsoft.com/en-us/azure/architecture/solution-ideas/media/advanced-analytics-on-big-data.png)

It includes some additional changes that [dataroots](https://dataroots.io) is recommending.

* Multiple storage containers to store every version of the data
* Cosmos DB is used to store the metadata of the data as a Data Catalog
* Azure Analysis Services is not used for now as some services might be replaced when [Azure Synapse Analytics Workspace](https://docs.microsoft.com/en-us/azure/synapse-analytics/overview-what-is) becomes GA

## Usage

```hcl
module "azuredatalake" {
  source  = "datarootsio/azure-datalake/module"
  version = "~> 0.1" 

  data_lake_name = "example name"
  region         = "eastus2"

  storage_replication          = "ZRS"
  service_principal_end_date   = "2030-01-01T00:00:00Z"
  cosmosdb_consistency_level   = "Session"
}
```

## Requirements

### Supported environments

This module works on macOS and Linux. Windows is not supported as the module uses some Bash scripts to get around Terraform limitations.
### Azure provider configuration

The following providers have to be configured:

* [AzureRM](https://www.terraform.io/docs/providers/azurerm/index.html)
* [AzureAD](https://registry.terraform.io/providers/hashicorp/azuread/latest/docs)
* [Databricks](https://registry.terraform.io/providers/databrickslabs/databricks/latest/docs)

You can either log in through the Azure CLI, or set environment variables as documented in the links above.

### Azure CLI

The module uses some workarounds for features that are not yet available in the Azure providers. Therefore, you need to be logged in to the Azure CLI as well. You can use both a user account, as well as service principal authentication.

### jq

The module uses jq to extract Databricks parameters during the deployment. Therefore, you need to have [jq](https://stedolan.github.io/jq/download/) installed.

## Contributing

Contributions to this repository are very welcome! Found a bug or do you have a suggestion? Please open an issue. Do you know how to fix it? Pull requests are welcome as well! To get you started faster, a Makefile is provided.

Make sure to install [Terraform](https://learn.hashicorp.com/terraform/getting-started/install.html), [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli?), [Go](https://golang.org/doc/install) (for automated testing) and Make (optional, if you want to use the Makefile) on your computer. Install [tflint](https://github.com/terraform-linters/tflint) to be able to run the linting.

* Setup tools & dependencies: `make tools`
* Format your code: `make fmt`
* Linting: `make lint`
* Run tests: `make test` (or `go test -timeout 2h ./...` without Make)

To run the automated tests, the environment variable `ARM_SUBSCRIPTION_ID` has to be set to your Azure subscription ID.

## License

MIT license. Please see [LICENSE](LICENSE.md) for details.

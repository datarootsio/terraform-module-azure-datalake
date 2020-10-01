resource "azurerm_cosmosdb_account" "cmdb" {
  name                = "cmdb${var.data_lake_name}"
  resource_group_name = var.resource_group_name
  location            = var.region
  tags                = local.common_tags
  offer_type          = "Standard"
  kind                = "GlobalDocumentDB"

  consistency_policy {
    consistency_level = var.cosmosdb_consistency_level
  }

  geo_location {
    location          = var.region
    failover_priority = 0
  }
}

resource "azurerm_cosmosdb_sql_database" "cmdb_db" {
  name                = "metadatadb"
  resource_group_name = var.resource_group_name
  account_name        = azurerm_cosmosdb_account.cmdb.name

  autoscale_settings {
    max_throughput = 4000
  }
}

resource "azurerm_cosmosdb_sql_container" "metadata" {
  name                = "metadata"
  resource_group_name = var.resource_group_name
  account_name        = azurerm_cosmosdb_account.cmdb.name
  database_name       = azurerm_cosmosdb_sql_database.cmdb_db.name
  partition_key_path  = var.cosmosdb_partition_key
}

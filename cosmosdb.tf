resource "azurerm_cosmosdb_account" "cmdb" {
  name                = "cmdb${var.data_lake_name}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = var.region
  tags                = azurerm_resource_group.rg.tags
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
  name                = "db${var.data_lake_name}"
  resource_group_name = azurerm_resource_group.rg.name
  account_name        = azurerm_cosmosdb_account.cmdb.name
  throughput          = var.cosmosdb_db_throughput
}
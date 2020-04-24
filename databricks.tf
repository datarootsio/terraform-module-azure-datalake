resource "azurerm_databricks_workspace" "dbks" {
  name                        = "dbks${var.data_lake_name}"
  resource_group_name         = azurerm_resource_group.rg.name
  managed_resource_group_name = "rgdbks${var.data_lake_name}"
  location                    = var.region
  sku                         = var.databricks_sku
  tags                        = azurerm_resource_group.rg.tags
}

provider "databricks" {
  host = format("https://%s.azuredatabricks.net", azurerm_databricks_workspace.dbks.location)

  azure {
    workspace_id = azurerm_databricks_workspace.dbks.id
  }
}

resource "databricks_cluster" "dbkscluster" {
  cluster_name  = "cluster${var.data_lake_name}"
  spark_version = var.databricks_cluster_version
  node_type_id  = var.databricks_cluster_node_type

  autoscale {
    min_workers = 2
    max_workers = 4
  }

  autotermination_minutes = 30
}
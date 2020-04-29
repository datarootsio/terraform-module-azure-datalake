resource "azurerm_databricks_workspace" "dbks" {
  name                        = "dbks${var.data_lake_name}"
  resource_group_name         = azurerm_resource_group.rg.name
  managed_resource_group_name = "rgdbks${var.data_lake_name}"
  location                    = var.region
  sku                         = var.databricks_sku
  tags                        = local.common_tags
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

resource "databricks_secret_scope" "adls" {
  scope                    = "adls"
  initial_manage_principal = "users"
}

resource "databricks_secret" "adls_tenant_id" {
  scope        = databricks_secret_scope.adls.scope
  key          = "tenant_id"
  string_value = data.azurerm_client_config.current.tenant_id
}

resource "databricks_secret" "adls_application_id" {
  scope        = databricks_secret_scope.adls.scope
  key          = "application_id"
  string_value = azuread_application.aadapp.application_id
}

resource "databricks_secret" "adls_client_secret" {
  scope        = databricks_secret_scope.adls.scope
  key          = "client_secret"
  string_value = random_password.aadapp_secret.result
}

resource "databricks_secret_scope" "cmdb" {
  scope                    = "cosmosdb"
  initial_manage_principal = "users"
}

resource "databricks_secret" "cmdb_master_key" {
  scope        = databricks_secret_scope.cmdb.scope
  key          = "master_key"
  string_value = azurerm_cosmosdb_account.cmdb.primary_master_key
}

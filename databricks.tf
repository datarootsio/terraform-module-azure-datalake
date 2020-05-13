resource "azurerm_databricks_workspace" "dbks" {
  name                        = "dbks${var.data_lake_name}"
  resource_group_name         = azurerm_resource_group.rg.name
  managed_resource_group_name = "rgdbks${var.data_lake_name}"
  location                    = var.region
  sku                         = var.databricks_sku
  tags                        = local.common_tags
}

provider "databricks" {
  azure_auth = {
    managed_resource_group = azurerm_databricks_workspace.dbks.managed_resource_group_name
    azure_region           = azurerm_databricks_workspace.dbks.location
    workspace_name         = azurerm_databricks_workspace.dbks.name
    resource_group         = azurerm_databricks_workspace.dbks.resource_group_name
    client_id              = azuread_application.aadapp.application_id
    client_secret          = azuread_service_principal_password.sppw.value
    tenant_id              = data.azurerm_client_config.current.tenant_id
    subscription_id        = data.azurerm_client_config.current.subscription_id
  }
}

resource "databricks_cluster" "cluster" {
  spark_version           = var.databricks_cluster_version
  cluster_name            = "cluster${var.data_lake_name}"
  node_type_id            = var.databricks_cluster_node_type
  autotermination_minutes = 120
  autoscale {
    min_workers = 2
    max_workers = 4
  }
}

resource "databricks_secret_scope" "adls" {
  name                     = "adls"
  initial_manage_principal = "users"
}

resource "databricks_secret" "client_secret" {
  key          = "client_secret"
  string_value = azuread_service_principal_password.sppw.value
  scope        = databricks_secret_scope.adls.name
}

resource "databricks_secret_scope" "temp_storage" {
  name                     = "temp_storage"
  initial_manage_principal = "users"
}

resource "databricks_secret" "access_key" {
  key          = "access_key"
  string_value = azurerm_storage_account.dbkstemp.primary_access_key
  scope        = databricks_secret_scope.temp_storage.name
}

resource "databricks_secret_scope" "cosmosdb" {
  name                     = "cosmosdb"
  initial_manage_principal = "users"
}

resource "databricks_secret" "cmdb_master" {
  key          = "master_key"
  string_value = azurerm_cosmosdb_account.cmdb.primary_master_key
  scope        = databricks_secret_scope.cosmosdb.name
}

resource "databricks_secret_scope" "synapse" {
  name                     = "synapse"
  initial_manage_principal = "users"
}

resource "databricks_secret" "synapse" {
  key          = "connection_string"
  string_value = "jdbc:sqlserver://${azurerm_sql_server.synapse_srv.fully_qualified_domain_name}:1433;database=${azurerm_sql_database.synapse.name};user=${local.databricks_loader_user}@${azurerm_sql_server.synapse_srv.name};password=${random_password.sql_databricks_loader.result};encrypt=true;trustServerCertificate=false;hostNameInCertificate=*.database.windows.net;loginTimeout=30;"
  scope        = databricks_secret_scope.synapse.name
}

resource "databricks_azure_adls_gen2_mount" "raw" {
  cluster_id           = databricks_cluster.cluster.id
  container_name       = local.data_lake_fs_raw_name
  storage_account_name = azurerm_storage_account.adls.name
  mount_name           = "raw"
  tenant_id            = data.azurerm_client_config.current.tenant_id
  client_id            = azuread_application.aadapp.application_id
  client_secret_scope  = databricks_secret.client_secret.scope
  client_secret_key    = databricks_secret.client_secret.key
  depends_on           = [azurerm_storage_data_lake_gen2_filesystem.dlfs, azurerm_role_assignment.spsa_sa_adls]
}

resource "databricks_azure_adls_gen2_mount" "clean" {
  cluster_id           = databricks_cluster.cluster.id
  container_name       = local.data_lake_fs_clean_name
  storage_account_name = azurerm_storage_account.adls.name
  mount_name           = "clean"
  tenant_id            = data.azurerm_client_config.current.tenant_id
  client_id            = azuread_application.aadapp.application_id
  client_secret_scope  = databricks_secret.client_secret.scope
  client_secret_key    = databricks_secret.client_secret.key
  depends_on           = [azurerm_storage_data_lake_gen2_filesystem.dlfs, azurerm_role_assignment.spsa_sa_adls]
}

resource "databricks_azure_adls_gen2_mount" "transformed" {
  cluster_id           = databricks_cluster.cluster.id
  container_name       = local.data_lake_fs_transformed_name
  storage_account_name = azurerm_storage_account.adls.name
  mount_name           = "transformed"
  tenant_id            = data.azurerm_client_config.current.tenant_id
  client_id            = azuread_application.aadapp.application_id
  client_secret_scope  = databricks_secret.client_secret.scope
  client_secret_key    = databricks_secret.client_secret.key
  depends_on           = [azurerm_storage_data_lake_gen2_filesystem.dlfs, azurerm_role_assignment.spsa_sa_adls]
}

resource "databricks_token" "token" {
  comment          = "Terraform Databricks service communication"
  lifetime_seconds = var.databricks_token_lifetime
}

resource "databricks_notebook" "spark_setup" {
  content    = base64encode(templatefile("${path.module}/files/spark_setup.scala", { blob_host = azurerm_storage_account.dbkstemp.primary_blob_host }))
  language   = "SCALA"
  path       = "/Shared/spark_setup.scala"
  overwrite  = false
  mkdirs     = true
  format     = "SOURCE"
  depends_on = [databricks_secret.access_key]

  provisioner "local-exec" {
    command     = "${path.module}/files/spark_setup.sh"
    interpreter = ["sh"]

    environment = {
      DATABRICKS_HOST  = format("https://%s.azuredatabricks.net", azurerm_databricks_workspace.dbks.location)
      DATABRICKS_TOKEN = databricks_token.token.token_value
      CLUSTER_ID       = databricks_cluster.cluster.id
      NOTEBOOK_PATH    = databricks_notebook.spark_setup.path
    }
  }
}

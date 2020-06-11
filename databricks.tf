resource "azurerm_databricks_workspace" "dbks" {
  name                        = "dbks${var.data_lake_name}"
  resource_group_name         = azurerm_resource_group.rg.name
  managed_resource_group_name = "rgdbks${var.data_lake_name}"
  location                    = var.region
  sku                         = var.databricks_sku
  tags                        = local.common_tags
}

resource "azurerm_role_assignment" "spdbks" {
  scope                = azurerm_databricks_workspace.dbks.id
  role_definition_name = "Owner"
  principal_id         = local.service_principal_id
}

provider "databricks" {
  azure_auth = {
    managed_resource_group = azurerm_databricks_workspace.dbks.managed_resource_group_name
    azure_region           = azurerm_databricks_workspace.dbks.location
    workspace_name         = azurerm_databricks_workspace.dbks.name
    resource_group         = azurerm_databricks_workspace.dbks.resource_group_name
    client_id              = local.application_id
    client_secret          = local.service_principal_secret
    tenant_id              = data.azurerm_client_config.current.tenant_id
    subscription_id        = data.azurerm_client_config.current.subscription_id
  }
}

resource "databricks_cluster" "cluster" {
  depends_on              = [azurerm_role_assignment.spdbks]
  spark_version           = var.databricks_cluster_version
  cluster_name            = "cluster${var.data_lake_name}"
  node_type_id            = var.databricks_cluster_node_type
  autotermination_minutes = 120

  autoscale {
    min_workers = 2
    max_workers = 4
  }

  library_maven {
    coordinates = "com.microsoft.azure:azure-cosmosdb-spark_2.4.0_2.11:${var.databricks_cosmosdb_spark_version}"
  }
}

resource "databricks_secret_scope" "adls" {
  depends_on               = [azurerm_role_assignment.spdbks]
  name                     = "adls"
  initial_manage_principal = "users"
}

resource "databricks_secret" "client_secret" {
  depends_on   = [azurerm_role_assignment.spdbks]
  key          = "client_secret"
  string_value = local.service_principal_secret
  scope        = databricks_secret_scope.adls.name
}

resource "databricks_secret_scope" "temp_storage" {
  depends_on               = [azurerm_role_assignment.spdbks]
  name                     = "temp_storage"
  initial_manage_principal = "users"
}

resource "databricks_secret" "access_key" {
  depends_on   = [azurerm_role_assignment.spdbks]
  key          = "access_key"
  string_value = azurerm_storage_account.dbkstemp.primary_access_key
  scope        = databricks_secret_scope.temp_storage.name
}

resource "databricks_secret_scope" "cosmosdb" {
  depends_on               = [azurerm_role_assignment.spdbks]
  name                     = "cosmosdb"
  initial_manage_principal = "users"
}

resource "databricks_secret" "cmdb_master" {
  depends_on   = [azurerm_role_assignment.spdbks]
  key          = "master_key"
  string_value = azurerm_cosmosdb_account.cmdb.primary_master_key
  scope        = databricks_secret_scope.cosmosdb.name
}

resource "databricks_secret_scope" "synapse" {
  count                    = local.create_synapse
  depends_on               = [azurerm_role_assignment.spdbks]
  name                     = "synapse"
  initial_manage_principal = "users"
}

resource "databricks_secret" "synapse_username" {
  count        = local.create_synapse
  depends_on   = [azurerm_role_assignment.spdbks]
  key          = "username"
  string_value = "${local.databricks_loader_user}@${azurerm_sql_server.synapse_srv[count.index].name}"
  scope        = databricks_secret_scope.synapse[count.index].name
}

resource "databricks_secret" "synapse_password" {
  count        = local.create_synapse
  key          = "password"
  string_value = random_password.sql_databricks_loader[count.index].result
  scope        = databricks_secret_scope.synapse[count.index].name
}

resource "databricks_azure_adls_gen2_mount" "raw" {
  cluster_id             = databricks_cluster.cluster.id
  container_name         = local.data_lake_fs_raw_name
  storage_account_name   = azurerm_storage_account.adls.name
  mount_name             = "raw"
  tenant_id              = data.azurerm_client_config.current.tenant_id
  client_id              = local.application_id
  client_secret_scope    = databricks_secret.client_secret.scope
  client_secret_key      = databricks_secret.client_secret.key
  initialize_file_system = true
  depends_on             = [azurerm_storage_data_lake_gen2_filesystem.dlfs, azurerm_role_assignment.spsa_sa_adls, azurerm_role_assignment.spdbks]
}

resource "databricks_azure_adls_gen2_mount" "clean" {
  cluster_id             = databricks_cluster.cluster.id
  container_name         = local.data_lake_fs_clean_name
  storage_account_name   = azurerm_storage_account.adls.name
  mount_name             = "clean"
  tenant_id              = data.azurerm_client_config.current.tenant_id
  client_id              = local.application_id
  client_secret_scope    = databricks_secret.client_secret.scope
  client_secret_key      = databricks_secret.client_secret.key
  initialize_file_system = true
  depends_on             = [azurerm_storage_data_lake_gen2_filesystem.dlfs, azurerm_role_assignment.spsa_sa_adls, azurerm_role_assignment.spdbks]
}

resource "databricks_azure_adls_gen2_mount" "curated" {
  cluster_id             = databricks_cluster.cluster.id
  container_name         = local.data_lake_fs_curated_name
  storage_account_name   = azurerm_storage_account.adls.name
  mount_name             = "curated"
  tenant_id              = data.azurerm_client_config.current.tenant_id
  client_id              = local.application_id
  client_secret_scope    = databricks_secret.client_secret.scope
  client_secret_key      = databricks_secret.client_secret.key
  initialize_file_system = true
  depends_on             = [azurerm_storage_data_lake_gen2_filesystem.dlfs, azurerm_role_assignment.spsa_sa_adls, azurerm_role_assignment.spdbks]
}

resource "databricks_token" "token" {
  depends_on       = [azurerm_role_assignment.spdbks]
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
  depends_on = [databricks_secret.access_key, azurerm_role_assignment.spdbks]

  provisioner "local-exec" {
    command = "${path.module}/files/spark_setup.sh"

    environment = {
      DATABRICKS_HOST  = format("https://%s", azurerm_databricks_workspace.dbks.workspace_url)
      DATABRICKS_TOKEN = databricks_token.token.token_value
      CLUSTER_ID       = databricks_cluster.cluster.id
      NOTEBOOK_PATH    = self.path
    }
  }
}

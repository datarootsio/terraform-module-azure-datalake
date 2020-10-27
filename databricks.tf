data "azurerm_databricks_workspace" "dbks" {
  count               = local.create_databricks_count
  name                = var.databricks_workspace_name
  resource_group_name = var.databricks_workspace_resource_group_name != "" ? var.databricks_workspace_resource_group_name : var.resource_group_name
}

resource "azurerm_role_assignment" "spdbks" {
  count                = local.create_databricks_count
  scope                = data.azurerm_databricks_workspace.dbks[count.index].id
  role_definition_name = "Owner"
  principal_id         = var.service_principal_object_id
}

resource "databricks_instance_pool" "pool" {
  count                                 = local.create_databricks_count
  instance_pool_name                    = "dl-pool"
  min_idle_instances                    = 0
  max_capacity                          = 10
  node_type_id                          = var.databricks_cluster_node_type
  idle_instance_autotermination_minutes = 10
  enable_elastic_disk                   = true
  preloaded_spark_versions              = [var.databricks_cluster_version]
}

resource "databricks_cluster" "cluster" {
  count                   = local.create_databricks_count
  depends_on              = [azurerm_role_assignment.spdbks]
  spark_version           = var.databricks_cluster_version
  cluster_name            = "dl-cluster"
  autotermination_minutes = 20
  instance_pool_id        = databricks_instance_pool.pool[count.index].id

  autoscale {
    min_workers = 1
    max_workers = 4
  }

  dynamic "cluster_log_conf" {
    for_each = var.databricks_log_path == "" ? [] : [var.databricks_log_path]
    content {
      dbfs {
        destination = cluster_log_conf.value
      }
    }
  }
}

resource "databricks_secret_scope" "adls" {
  count                    = local.create_databricks_count
  depends_on               = [azurerm_role_assignment.spdbks]
  name                     = "adls"
  initial_manage_principal = "users"
}

resource "databricks_secret" "client_secret" {
  count        = local.create_databricks_count
  depends_on   = [azurerm_role_assignment.spdbks]
  key          = "client_secret"
  string_value = var.service_principal_client_secret
  scope        = databricks_secret_scope.adls[count.index].name
}

resource "databricks_secret_scope" "cosmosdb" {
  count                    = local.create_databricks_count
  depends_on               = [azurerm_role_assignment.spdbks]
  name                     = "cosmosdb"
  initial_manage_principal = "users"
}

resource "databricks_secret" "cmdb_master" {
  count        = local.create_databricks_count
  depends_on   = [azurerm_role_assignment.spdbks]
  key          = "master_key"
  string_value = azurerm_cosmosdb_account.cmdb.primary_master_key
  scope        = databricks_secret_scope.cosmosdb[count.index].name
}

resource "databricks_azure_adls_gen2_mount" "fs" {
  for_each               = local.create_databricks_bool ? toset(var.data_lake_filesystems) : toset([])
  container_name         = each.key
  storage_account_name   = azurerm_storage_account.adls.name
  mount_name             = each.key
  tenant_id              = data.azurerm_client_config.current.tenant_id
  client_id              = var.service_principal_client_id
  client_secret_scope    = databricks_secret.client_secret[0].scope
  client_secret_key      = databricks_secret.client_secret[0].key
  cluster_id             = databricks_cluster.cluster[0].id
  initialize_file_system = true
  depends_on             = [azurerm_storage_data_lake_gen2_filesystem.dlfs, azurerm_role_assignment.spsa_sa_adls, azurerm_role_assignment.spdbks]
}

resource "databricks_token" "token" {
  count      = local.create_databricks_count
  depends_on = [azurerm_role_assignment.spdbks]
  comment    = "Terraform Databricks service communication"
}

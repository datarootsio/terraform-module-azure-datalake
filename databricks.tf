resource "azurerm_databricks_workspace" "dbks" {
  count                       = local.create_databricks
  name                        = "dbks${var.data_lake_name}"
  resource_group_name         = azurerm_resource_group.rg.name
  managed_resource_group_name = "rgdbks${var.data_lake_name}"
  location                    = var.region
  sku                         = var.databricks_sku
  tags                        = local.common_tags
}

resource "azurerm_role_assignment" "spdbks" {
  count                = local.create_databricks
  scope                = azurerm_databricks_workspace.dbks[count.index].id
  role_definition_name = "Owner"
  principal_id         = local.service_principal_id
}

provider "databricks" {
  azure_workspace_resource_id = var.provision_databricks ? azurerm_databricks_workspace.dbks[0].id : " "
}

resource "databricks_instance_pool" "pool" {
  count                                 = local.create_databricks
  instance_pool_name                    = "dl-pool"
  min_idle_instances                    = 0
  max_capacity                          = 10
  node_type_id                          = var.databricks_cluster_node_type
  idle_instance_autotermination_minutes = 10
  enable_elastic_disk                   = true
  preloaded_spark_versions              = [var.databricks_cluster_version]
}

resource "databricks_cluster" "cluster" {
  count                   = local.create_databricks
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
  count                    = local.create_databricks
  depends_on               = [azurerm_role_assignment.spdbks]
  name                     = "adls"
  initial_manage_principal = "users"
}

resource "databricks_secret" "client_secret" {
  count        = local.create_databricks
  depends_on   = [azurerm_role_assignment.spdbks]
  key          = "client_secret"
  string_value = local.service_principal_secret
  scope        = databricks_secret_scope.adls[count.index].name
}

resource "databricks_secret_scope" "temp_storage" {
  count                    = var.provision_databricks && var.provision_synapse ? 1 : 0
  depends_on               = [azurerm_role_assignment.spdbks]
  name                     = "temp_storage"
  initial_manage_principal = "users"
}

resource "databricks_secret" "access_key" {
  count        = var.provision_databricks && var.provision_synapse ? 1 : 0
  depends_on   = [azurerm_role_assignment.spdbks]
  key          = "access_key"
  string_value = azurerm_storage_account.dbkstemp[count.index].primary_access_key
  scope        = databricks_secret_scope.temp_storage[count.index].name
}

resource "databricks_secret_scope" "cosmosdb" {
  count                    = local.create_databricks
  depends_on               = [azurerm_role_assignment.spdbks]
  name                     = "cosmosdb"
  initial_manage_principal = "users"
}

resource "databricks_secret" "cmdb_master" {
  count        = local.create_databricks
  depends_on   = [azurerm_role_assignment.spdbks]
  key          = "master_key"
  string_value = azurerm_cosmosdb_account.cmdb.primary_master_key
  scope        = databricks_secret_scope.cosmosdb[count.index].name
}

resource "databricks_secret_scope" "synapse" {
  count                    = var.provision_databricks && var.provision_synapse ? 1 : 0
  depends_on               = [azurerm_role_assignment.spdbks]
  name                     = "synapse"
  initial_manage_principal = "users"
}

resource "databricks_secret" "synapse_username" {
  count        = var.provision_databricks && var.provision_synapse ? 1 : 0
  depends_on   = [azurerm_role_assignment.spdbks]
  key          = "username"
  string_value = "${local.databricks_loader_user}@${azurerm_sql_server.synapse_srv[count.index].name}"
  scope        = databricks_secret_scope.synapse[count.index].name
}

resource "databricks_secret" "synapse_password" {
  count        = var.provision_databricks && var.provision_synapse ? 1 : 0
  key          = "password"
  string_value = random_password.sql_databricks_loader[count.index].result
  scope        = databricks_secret_scope.synapse[count.index].name
}

resource "databricks_azure_adls_gen2_mount" "fs" {
  for_each               = var.provision_databricks ? local.data_lake_fs_merged : toset([])
  cluster_id             = databricks_cluster.cluster[0].id
  container_name         = each.key
  storage_account_name   = azurerm_storage_account.adls.name
  mount_name             = each.key
  tenant_id              = data.azurerm_client_config.current.tenant_id
  client_id              = local.application_id
  client_secret_scope    = databricks_secret.client_secret[0].scope
  client_secret_key      = databricks_secret.client_secret[0].key
  initialize_file_system = true
  depends_on             = [azurerm_storage_data_lake_gen2_filesystem.dlfs, azurerm_role_assignment.spsa_sa_adls, azurerm_role_assignment.spdbks]
}

resource "databricks_token" "token" {
  count      = local.create_databricks
  depends_on = [azurerm_role_assignment.spdbks]
  comment    = "Terraform Databricks service communication"
}

resource "databricks_notebook" "spark_setup" {
  count      = var.provision_synapse && var.provision_databricks ? 1 : 0
  content    = base64encode(templatefile("${path.module}/files/spark_setup.scala", { blob_host = azurerm_storage_account.dbkstemp[count.index].primary_blob_host }))
  language   = "SCALA"
  path       = "/Shared/spark_setup.scala"
  overwrite  = false
  mkdirs     = true
  format     = "SOURCE"
  depends_on = [databricks_secret.access_key, azurerm_role_assignment.spdbks]

  provisioner "local-exec" {
    command = "${path.module}/files/spark_setup.sh"

    environment = {
      DATABRICKS_HOST  = format("https://%s", azurerm_databricks_workspace.dbks[count.index].workspace_url)
      DATABRICKS_TOKEN = databricks_token.token[count.index].token_value
      CLUSTER_ID       = databricks_cluster.cluster[count.index].id
      NOTEBOOK_PATH    = self.path
    }
  }
}

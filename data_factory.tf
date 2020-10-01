resource "azurerm_data_factory" "df" {
  name                = "df${var.data_lake_name}"
  location            = var.region
  resource_group_name = var.resource_group_name
  tags                = local.common_tags

  identity {
    type = "SystemAssigned"
  }

  dynamic "vsts_configuration" {
    for_each = local.create_data_factory_git_vsts_set
    content {
      account_name    = var.data_factory_vsts_account_name
      branch_name     = var.data_factory_vsts_branch_name
      project_name    = var.data_factory_vsts_project_name
      repository_name = var.data_factory_vsts_repository_name
      root_folder     = var.data_factory_vsts_root_folder
      tenant_id       = var.data_factory_vsts_tenant_id
    }
  }

  dynamic "github_configuration" {
    for_each = local.create_data_factory_git_github_set
    content {
      account_name    = var.data_factory_github_account_name
      branch_name     = var.data_factory_github_branch_name
      git_url         = var.data_factory_github_git_url
      repository_name = var.data_factory_github_repository_name
      root_folder     = var.data_factory_github_root_folder
    }
  }
}

resource "azurerm_data_factory_linked_service_data_lake_storage_gen2" "lsadls" {
  name                  = "lsadls"
  resource_group_name   = var.resource_group_name
  data_factory_name     = azurerm_data_factory.df.name
  tenant                = data.azurerm_client_config.current.tenant_id
  url                   = azurerm_storage_account.adls.primary_dfs_endpoint
  service_principal_id  = var.service_principal_client_id
  service_principal_key = var.service_principal_client_secret
  depends_on            = [azurerm_role_assignment.spsa_sa_adls]
  count                 = local.create_data_factory_ls_count
}

resource "azurerm_template_deployment" "lsdbks" {
  count               = local.create_databricks_bool && var.provision_data_factory_links ? 1 : 0
  name                = "lsdbks"
  resource_group_name = var.resource_group_name

  template_body = file("${path.module}/files/lsdbks.json")

  # these key-value pairs are passed into the ARM Template's `parameters` block
  parameters = {
    "factoryName"                 = azurerm_data_factory.df.name
    "accessToken"                 = databricks_token.token[count.index].token_value
    "domain"                      = format("https://%s", data.azurerm_databricks_workspace.dbks[count.index].workspace_url)
    "databricksLinkedServiceName" = data.azurerm_databricks_workspace.dbks[count.index].name
    "clusterId"                   = databricks_cluster.cluster[count.index].id
  }

  deployment_mode = "Incremental"

  provisioner "local-exec" {
    command    = "${path.module}/files/destroy_resource.sh"
    when       = destroy
    on_failure = continue

    environment = {
      RESOURCE_ID = self.outputs["databricksLinkedServiceId"]
    }
  }
}

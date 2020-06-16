resource "azurerm_data_factory" "df" {
  name                = "df${var.data_lake_name}"
  location            = var.region
  resource_group_name = azurerm_resource_group.rg.name
  tags                = local.common_tags

  identity {
    type = "SystemAssigned"
  }

  dynamic "vsts_configuration" {
    for_each = local.create_data_factory_git_vsts
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
    for_each = local.create_data_factory_git_github
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
  name                  = "lsadls${var.data_lake_name}"
  resource_group_name   = azurerm_resource_group.rg.name
  data_factory_name     = azurerm_data_factory.df.name
  tenant                = data.azurerm_client_config.current.tenant_id
  url                   = azurerm_storage_account.adls.primary_dfs_endpoint
  service_principal_id  = local.application_id
  service_principal_key = local.service_principal_secret
  depends_on            = [azurerm_role_assignment.spsa_sa_adls]
  count                 = var.create_data_factory_ls
}

resource "azurerm_template_deployment" "lsdbks" {
  count               = var.create_data_factory_ls
  name                = "lsdbks${var.data_lake_name}"
  resource_group_name = azurerm_resource_group.rg.name

  template_body = file("${path.module}/files/lsdbks.json")

  # these key-value pairs are passed into the ARM Template's `parameters` block
  parameters = {
    "factoryName"                 = azurerm_data_factory.df.name
    "accessToken"                 = databricks_token.token.token_value
    "domain"                      = format("https://%s", azurerm_databricks_workspace.dbks.workspace_url)
    "databricksLinkedServiceName" = azurerm_databricks_workspace.dbks.name
    "clusterId"                   = databricks_cluster.cluster.id
  }

  deployment_mode = "Incremental"

  provisioner "local-exec" {
    command = "${path.module}/files/destroy_resource.sh"
    when    = destroy

    environment = {
      RESOURCE_ID = self.outputs["databricksLinkedServiceId"]
    }
  }
}

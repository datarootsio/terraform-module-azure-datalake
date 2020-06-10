locals {
  # Common tags to be assigned to all resources
  own_tags = {
    DataLake = var.data_lake_name
  }
  common_tags = merge(local.own_tags, var.extra_tags)

  data_lake_fs_merged       = distinct(concat([var.data_lake_fs_raw, var.data_lake_fs_cleansed, var.data_lake_fs_curated], var.data_lake_filesystems))
  data_lake_fs_names        = [for s in local.data_lake_fs_merged : "fs${s}${var.data_lake_name}"]
  data_lake_fs_raw_name     = "fs${var.data_lake_fs_raw}${var.data_lake_name}"
  data_lake_fs_clean_name   = "fs${var.data_lake_fs_cleansed}${var.data_lake_name}"
  data_lake_fs_curated_name = "fs${var.data_lake_fs_curated}${var.data_lake_name}"

  create_sample                  = var.provision_sample_data && var.provision_synapse ? 1 : 0
  create_synapse                 = var.provision_synapse ? 1 : 0
  create_data_factory_git_vsts   = var.data_factory_vsts_account_name == null ? [] : ["_"]
  create_data_factory_git_github = var.data_factory_github_account_name == null ? [] : ["_"]
  use_kv                         = var.use_key_vault ? 1 : 0

  databricks_loader_user = "DatabricksLoader"
  powerbi_viewer_user    = "PowerBiViewer"

  service_principal_id     = var.use_existing_service_principal ? var.service_principal_id : join("", azuread_service_principal.sp.*.object_id)
  service_principal_secret = var.use_existing_service_principal ? var.service_principal_secret : join("", azuread_service_principal_password.sppw.*.value)
  application_id           = var.use_existing_service_principal ? var.application_id : join("", azuread_application.aadapp.*.application_id)
}

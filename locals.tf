locals {
  # Common tags to be assigned to all resources
  common_tags = {
    DataLake = var.data_lake_name
  }

  data_lake_fs_merged           = distinct(concat([var.data_lake_fs_raw, var.data_lake_fs_cleansed, var.data_lake_fs_transformed], var.data_lake_filesystems))
  data_lake_fs_names            = [for s in local.data_lake_fs_merged : "fs${s}${var.data_lake_name}"]
  data_lake_fs_raw_name         = "fs${var.data_lake_fs_raw}${var.data_lake_name}"
  data_lake_fs_clean_name       = "fs${var.data_lake_fs_cleansed}${var.data_lake_name}"
  data_lake_fs_transformed_name = "fs${var.data_lake_fs_transformed}${var.data_lake_name}"

  create_sample         = var.provision_sample_data && var.provision_synapse ? 1 : 0
  create_synapse        = var.provision_synapse ? 1 : 0

  databricks_loader_user = "DatabricksLoader"
  powerbi_viewer_user    = "PowerBiViewer"
}

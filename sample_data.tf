resource "azurerm_template_deployment" "dfpipeline" {
  name                = "armdfpipeline"
  count               = local.create_sample
  resource_group_name = azurerm_resource_group.rg.name

  template_body = file("${path.module}/files/sample_data/dfpipeline.json")

  # these key-value pairs are passed into the ARM Template's `parameters` block
  parameters = {
    "factoryName"       = azurerm_data_factory.df.name
    "rawAdlsName"       = local.data_lake_fs_raw_name
    "adlsLinkedService" = azurerm_data_factory_linked_service_data_lake_storage_gen2.lsadls.name
  }

  deployment_mode = "Incremental"

  provisioner "local-exec" {
    command     = "${path.module}/files/sample_data/run_pipeline.sh"
    interpreter = ["sh"]

    environment = {
      PIPELINE_ID = self.outputs["pipelineId"]
    }
  }
}

resource "azurerm_data_factory_trigger_schedule" "copy_sample_data_trigger" {
  name                = "copy_sample_data_trigger"
  count               = local.create_sample
  resource_group_name = azurerm_resource_group.rg.name
  data_factory_name   = azurerm_data_factory.df.name
  pipeline_name       = azurerm_template_deployment.dfpipeline[count.index].outputs["pipelineName"]
  interval            = 1
  frequency           = "Day"
  start_time          = "${formatdate("YYYY-MM-DD", timestamp())}T00:00:00Z"

  provisioner "local-exec" {
    command     = "${path.module}/files/sample_data/set_df_trigger.sh"
    interpreter = ["sh"]
    on_failure  = continue

    environment = {
      TRIGGER_ID     = self.id
      TRIGGER_ACTION = "start"
    }
  }

  provisioner "local-exec" {
    command     = "${path.module}/files/sample_data/set_df_trigger.sh"
    interpreter = ["sh"]
    when        = destroy
    on_failure  = continue

    environment = {
      TRIGGER_ID     = self.id
      TRIGGER_ACTION = "stop"
    }
  }
}

resource "databricks_notebook" "clean" {
  content   = filebase64("${path.module}/files/sample_data/clean.scala")
  language  = "SCALA"
  path      = "/Shared/sample/clean.scala"
  overwrite = false
  mkdirs    = true
  format    = "SOURCE"
  count     = local.create_sample
}

resource "databricks_notebook" "transform" {
  content = base64encode(templatefile("${path.module}/files/sample_data/transform.scala", {
    container = azurerm_storage_container.databricks.name,
  storage_account_blob_endpoint = azurerm_storage_account.dbkstemp.primary_blob_host }))

  language  = "SCALA"
  path      = "/Shared/sample/transform.scala"
  overwrite = false
  mkdirs    = true
  format    = "SOURCE"
  count     = local.create_sample
}

resource "databricks_notebook" "presentation" {
  content   = filebase64("${path.module}/files/sample_data/presentation.scala.dbc")
  language  = "SCALA"
  path      = "/Shared/sample/presentation.scala"
  overwrite = false
  mkdirs    = true
  format    = "DBC"
  count     = local.create_sample
}

resource "databricks_job" "clean" {
  existing_cluster_id = databricks_cluster.cluster.id
  notebook_path       = databricks_notebook.clean[count.index].path
  name                = "sample_clean"
  count               = local.create_sample

  schedule {
    quartz_cron_expression = "0 0 1 * * ? *"
    timezone_id            = "UTC"
  }
}

resource "databricks_job" "transform" {
  existing_cluster_id = databricks_cluster.cluster.id
  notebook_path       = databricks_notebook.transform[count.index].path
  name                = "sample_transform"
  count               = local.create_sample

  schedule {
    quartz_cron_expression = "0 0 2 * * ? *"
    timezone_id            = "UTC"
  }
}

resource "databricks_job" "presentation" {
  existing_cluster_id = databricks_cluster.cluster.id
  notebook_path       = databricks_notebook.presentation[count.index].path
  name                = "sample_presentation"
  count               = local.create_sample

  schedule {
    quartz_cron_expression = "0 0 3 * * ? *"
    timezone_id            = "UTC"
  }
}

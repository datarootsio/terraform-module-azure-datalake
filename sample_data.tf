resource "databricks_notebook" "clean" {
  content   = filebase64("${path.module}/files/sample_data/clean.scala")
  language  = "SCALA"
  path      = "/Shared/sample/clean.scala"
  overwrite = false
  mkdirs    = true
  format    = "SOURCE"
  count     = local.create_sample

  depends_on = [databricks_azure_adls_gen2_mount.raw, databricks_azure_adls_gen2_mount.clean, azurerm_role_assignment.spdbks]
}

resource "databricks_notebook" "transform" {
  content = var.provision_synapse ? base64encode(templatefile("${path.module}/files/sample_data/transform.scala", {
    container                     = azurerm_storage_container.databricks.name,
    storage_account_blob_endpoint = azurerm_storage_account.dbkstemp.primary_blob_host,
    server                        = azurerm_sql_server.synapse_srv[count.index].fully_qualified_domain_name,
    database                      = azurerm_sql_database.synapse[count.index].name
  })) : ""

  language  = "SCALA"
  path      = "/Shared/sample/transform.scala"
  overwrite = false
  mkdirs    = true
  format    = "SOURCE"
  count     = local.create_sample

  depends_on = [databricks_notebook.spark_setup, databricks_azure_adls_gen2_mount.clean, databricks_azure_adls_gen2_mount.curated, azurerm_role_assignment.spdbks]
}

resource "databricks_notebook" "presentation" {
  content   = filebase64("${path.module}/files/sample_data/presentation.scala.dbc")
  language  = "SCALA"
  path      = "/Shared/sample/presentation.scala"
  overwrite = false
  mkdirs    = true
  format    = "DBC"
  count     = local.create_sample

  depends_on = [databricks_azure_adls_gen2_mount.curated, azurerm_role_assignment.spdbks]
}

resource "azurerm_template_deployment" "dfpipeline" {
  name                = "armdfpipeline"
  count               = local.create_sample
  resource_group_name = azurerm_resource_group.rg.name
  depends_on          = [azurerm_template_deployment.lsdbks, azurerm_data_factory_linked_service_data_lake_storage_gen2.lsadls]

  template_body = file("${path.module}/files/sample_data/pipeline.json")

  # these key-value pairs are passed into the ARM Template's `parameters` block
  parameters = {
    "factoryName"                 = azurerm_data_factory.df.name
    "rawAdlsName"                 = local.data_lake_fs_raw_name
    "adlsLinkedServiceName"       = azurerm_data_factory_linked_service_data_lake_storage_gen2.lsadls.name
    "cleanNotebookPath"           = databricks_notebook.clean[count.index].path
    "transformNotebookPath"       = databricks_notebook.transform[count.index].path
    "databricksLinkedServiceName" = azurerm_template_deployment.lsdbks.outputs["databricksLinkedServiceName"]
  }

  deployment_mode = "Incremental"

  provisioner "local-exec" {
    command = "${path.module}/files/sample_data/run_pipeline.sh"

    environment = {
      PIPELINE_ID = self.outputs["pipelineId"]
    }
  }

  provisioner "local-exec" {
    command = "${path.module}/files/destroy_resource.sh"
    when    = destroy

    environment = {
      RESOURCE_ID = self.outputs["pipelineId"]
    }
  }

  provisioner "local-exec" {
    command = "${path.module}/files/destroy_resource.sh"
    when    = destroy

    environment = {
      RESOURCE_ID = self.outputs["rawDataSetId"]
    }
  }

  provisioner "local-exec" {
    command = "${path.module}/files/destroy_resource.sh"
    when    = destroy

    environment = {
      RESOURCE_ID = self.outputs["sampleDataDatasetId"]
    }
  }

  provisioner "local-exec" {
    command = "${path.module}/files/destroy_resource.sh"
    when    = destroy

    environment = {
      RESOURCE_ID = self.outputs["sampleDataLinkedServiceId"]
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
    command = "${path.module}/files/sample_data/set_df_trigger.sh"

    environment = {
      TRIGGER_ID     = self.id
      TRIGGER_ACTION = "start"
    }
  }

  provisioner "local-exec" {
    command = "${path.module}/files/sample_data/set_df_trigger.sh"
    when    = destroy

    environment = {
      TRIGGER_ID     = self.id
      TRIGGER_ACTION = "stop"
    }
  }
}

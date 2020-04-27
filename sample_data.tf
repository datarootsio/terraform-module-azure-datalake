resource "azurerm_template_deployment" "dfpipeline" {
  name                = "armdfpipeline"
  resource_group_name = azurerm_resource_group.rg.name

  template_body = <<DEPLOY
{
    "$schema": "https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#",
    "contentVersion": "1.0.0.0",
    "parameters": {
        "factoryName": {
            "type": "string",
            "metadata": "Data Factory name"
        },
        "rawAdlsName": {
            "type": "string",
            "metadata": "Name of the filesystem in the Azure Data Lake Storage for raw data"
        },
        "adlsLinkedService": {
            "type": "string",
            "metadata": "Name of the linked service to the Azure Data Lake Storage"
        }
    },
    "variables": {
        "factoryId": "[concat('Microsoft.DataFactory/factories/', parameters('factoryName'))]"
    },
    "resources": [
        {
            "name": "[concat(parameters('factoryName'), '/sampledataservice')]",
            "type": "Microsoft.DataFactory/factories/linkedServices",
            "apiVersion": "2018-06-01",
            "properties": {
                "type": "HttpServer",
                "typeProperties": {
                    "url": "https://my.api.mockaroo.com",
                    "enableServerCertificateValidation": true,
                    "authenticationType": "Anonymous"
                }
            }
        },
        {
            "name": "[concat(parameters('factoryName'), '/sample_data_set')]",
            "type": "Microsoft.DataFactory/factories/datasets",
            "apiVersion": "2018-06-01",
            "properties": {
                "linkedServiceName": {
                    "referenceName": "sampledataservice",
                    "type": "LinkedServiceReference"
                },
                "type": "Json",
                "typeProperties": {
                    "location": {
                        "type": "HttpServerLocation",
                        "relativeUrl": "/sales.json?key=592257d0"
                    }
                }
            },
            "dependsOn": [
                "[concat(variables('factoryId'), '/linkedServices/sampledataservice')]"
            ]
        },
        {
            "name": "[concat(parameters('factoryName'), '/copy_sample_data')]",
            "type": "Microsoft.DataFactory/factories/pipelines",
            "apiVersion": "2018-06-01",
            "properties": {
                "activities": [
                    {
                        "name": "Copy from sample to data lake storage",
                        "type": "Copy",
                        "policy": {
                            "timeout": "7.00:00:00",
                            "retry": 0,
                            "retryIntervalInSeconds": 30,
                            "secureOutput": false,
                            "secureInput": false
                        },
                        "typeProperties": {
                            "source": {
                                "type": "JsonSource",
                                "storeSettings": {
                                    "type": "HttpReadSettings",
                                    "requestMethod": "GET"
                                }
                            },
                            "sink": {
                                "type": "JsonSink",
                                "storeSettings": {
                                    "type": "AzureBlobFSWriteSettings"
                                },
                                "formatSettings": {
                                    "type": "JsonWriteSettings",
                                    "quoteAllText": true
                                }
                            },
                            "enableStaging": false
                        },
                        "inputs": [
                            {
                                "referenceName": "sample_data_set",
                                "type": "DatasetReference",
                                "parameters": {}
                            }
                        ],
                        "outputs": [
                            {
                                "referenceName": "raw_data",
                                "type": "DatasetReference",
                                "parameters": {}
                            }
                        ]
                    }
                ]
            },
            "dependsOn": [
                "[concat(variables('factoryId'), '/datasets/sample_data_set')]",
                "[concat(variables('factoryId'), '/datasets/raw_data')]"
            ]
        },
        {
            "name": "[concat(parameters('factoryName'), '/raw_data')]",
            "type": "Microsoft.DataFactory/factories/datasets",
            "apiVersion": "2018-06-01",
            "properties": {
                "linkedServiceName": {
                    "referenceName": "[parameters('adlsLinkedService')]",
                    "type": "LinkedServiceReference"
                },
                "type": "Json",
                "typeProperties": {
                    "location": {
                        "type": "AzureBlobFSLocation",
                        "fileName": {
                            "value": "@concat(string(dayOfMonth(utcnow())), '.json')",
                            "type": "Expression"
                        },
                        "folderPath": {
                            "value": "@formatDateTime(utcnow(), 'yyyyMM')",
                            "type": "Expression"
                        },
                        "fileSystem": "[parameters('rawAdlsName')]"
                    }
                }
            }
        }
    ]
}
DEPLOY


  # these key-value pairs are passed into the ARM Template's `parameters` block
  parameters = {
    "factoryName"       = azurerm_data_factory.df.name
    "rawAdlsName"       = local.data_lake_fs_raw_name
    "adlsLinkedService" = azurerm_data_factory_linked_service_data_lake_storage_gen2.lsadls.name
  }

  deployment_mode = "Incremental"
}

resource "azurerm_data_factory_trigger_schedule" "copy_sample_data_trigger" {
  name                = "copy_sample_data_trigger"
  resource_group_name = azurerm_resource_group.rg.name
  data_factory_name   = azurerm_data_factory.df.name
  pipeline_name       = "copy_sample_data"
  interval            = 1
  frequency           = "Day"
  depends_on          = [azurerm_template_deployment.dfpipeline]

  provisioner "local-exec" {
    command     = "${path.module}/files/set_df_trigger.sh"
    interpreter = ["sh"]

    environment = {
      TRIGGER_ID     = self.id
      TRIGGER_ACTION = "start"
    }
  }

  provisioner "local-exec" {
    command     = "${path.module}/files/set_df_trigger.sh"
    interpreter = ["sh"]
    when        = destroy

    environment = {
      TRIGGER_ID     = self.id
      TRIGGER_ACTION = "stop"
    }
  }
}

resource "databricks_workspace_import" "data_cleansing" {
  format   = "SOURCE"
  language = "SCALA"
  path     = "/Shared/data_cleansing.scala"
  content = base64encode(templatefile("${path.module}/files/data_cleansing_notebook.scala",
    {
      adls_account = azurerm_storage_account.dls.name
      adls_raw     = local.data_lake_fs_raw_name
      adls_clean   = local.data_lake_fs_clean_name
  }))
}

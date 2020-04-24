resource "null_resource" "sample_data" {
  provisioner "local-exec" {
    command = "curl -H 'X-API-Key: 592257d0' -o '/tmp/sample_data.json' https://my.api.mockaroo.com/sales.json"
  }
}

resource "azurerm_template_deployment" "dfpipeline" {
  name                = "armdfpipeline"
  resource_group_name = azurerm_resource_group.rg.name

  template_body = <<DEPLOY
{
    "$schema": "http://schema.management.azure.com/schemas/2015-01-01/deploymentTemplate.json#",
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
                "annotations": [],
                "type": "HttpServer",
                "typeProperties": {
                    "url": "https://my.api.mockaroo.com",
                    "enableServerCertificateValidation": true,
                    "authenticationType": "Anonymous"
                }
            },
            "dependsOn": []
        },
        {
            "name": "[concat(parameters('factoryName'), '/sampledataset')]",
            "type": "Microsoft.DataFactory/factories/datasets",
            "apiVersion": "2018-06-01",
            "properties": {
                "linkedServiceName": {
                    "referenceName": "sampledataservice",
                    "type": "LinkedServiceReference"
                },
                "annotations": [],
                "type": "Json",
                "typeProperties": {
                    "location": {
                        "type": "HttpServerLocation",
                        "relativeUrl": "/sales.json?key=592257d0"
                    }
                },
                "schema": {}
            },
            "dependsOn": [
                "[concat(variables('factoryId'), '/linkedServices/sampledataservice')]"
            ]
        },
        {
            "name": "[concat(parameters('factoryName'), '/rawdata')]",
            "type": "Microsoft.DataFactory/factories/datasets",
            "apiVersion": "2018-06-01",
            "properties": {
                "linkedServiceName": {
                    "referenceName": "@parameters('adlsLinkedService')",
                    "type": "LinkedServiceReference"
                },
                "annotations": [],
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
                        "fileSystem": "@parameters('rawAdlsName')"
                    }
                },
                "schema": {}
            }
        }
    ]
}
DEPLOY


  # these key-value pairs are passed into the ARM Template's `parameters` block
  parameters = {
    "factoryName"       = azurerm_data_factory.df.name
    "rawAdlsName"       = "fs${var.data_lake_fs_raw}${var.data_lake_name}"
    "adlsLinkedService" = azurerm_data_factory_linked_service_data_lake_storage_gen2.lsadls.name
  }

  deployment_mode = "Incremental"
}

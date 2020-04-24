resource "null_resource" "sample_data" {
  provisioner "local-exec" {
    command = "curl -H 'X-API-Key: 592257d0' -o '/tmp/sample_data.json' https://my.api.mockaroo.com/sales.json"
  }
}

resource "azurerm_storage_blob" "example" {
  depends_on             = [null_resource.sample_data, azurerm_storage_data_lake_gen2_filesystem.dlfs]
  name                   = "sample_data.json"
  storage_account_name   = azurerm_storage_account.dls.name
  storage_container_name = "fs${var.data_lake_name}${var.data_lake_fs_raw}"
  type                   = "Block"
  source                 = "/tmp/sample_data.json"
}

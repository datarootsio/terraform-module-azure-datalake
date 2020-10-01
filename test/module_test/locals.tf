locals {
  test_id        = var.test_id == "" ? random_string.test_id.result : var.test_id
  region         = "eastus2"
  data_lake_name = "testtfadl${local.test_id}"
}

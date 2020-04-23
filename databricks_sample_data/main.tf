provider "databricks" {
  host  = var.host
  token = var.token
}

resource "databricks_cluster" "example" {
  cluster_name  = "example"
  spark_version = "6.3.x-scala2.11"
  node_type_id  = "Standard_DS3_v2"

  autoscale {
    min_workers = 2
    max_workers = 8
  }

  autotermination_minutes = 120
}
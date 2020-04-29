// Databricks notebook source
val endpoint = "https://login.microsoftonline.com/" + dbutils.secrets.get("adls", "tenant_id") + "/oauth2/token"
val configs = Map(
  "fs.azure.account.auth.type" -> "OAuth",
  "fs.azure.account.oauth.provider.type" -> "org.apache.hadoop.fs.azurebfs.oauth2.ClientCredsTokenProvider",
  "fs.azure.account.oauth2.client.id" -> dbutils.secrets.get("adls", "application_id"),
  "fs.azure.account.oauth2.client.secret" -> dbutils.secrets.get("adls", "client_secret"),
  "fs.azure.account.oauth2.client.endpoint" -> endpoint)

val storageRaw = "abfss://${adls_raw}@${adls_account}.dfs.core.windows.net/"
val storageClean = "abfss://${adls_clean}@${adls_account}.dfs.core.windows.net/"
val storageTransformed = "abfss://${adls_transformed}@${adls_account}.dfs.core.windows.net/"

// COMMAND ----------

dbutils.fs.mount(
  source = storageRaw,
  mountPoint = "/mnt/raw",
  extraConfigs = configs)

// COMMAND ----------

dbutils.fs.mount(
  source = storageClean,
  mountPoint = "/mnt/clean",
  extraConfigs = configs)

// COMMAND ----------

dbutils.fs.mount(
  source = storageTransformed,
  mountPoint = "/mnt/transformed",
  extraConfigs = configs)

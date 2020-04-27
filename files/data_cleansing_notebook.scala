// Databricks notebook source
import org.apache.spark.sql.functions._
import org.apache.spark.sql.types._

// COMMAND ----------

val endpoint = "https://login.microsoftonline.com/" + dbutils.secrets.get("adls", "tenant_id") + "/oauth2/token"
val configs = Map(
  "fs.azure.account.auth.type" -> "OAuth",
  "fs.azure.account.oauth.provider.type" -> "org.apache.hadoop.fs.azurebfs.oauth2.ClientCredsTokenProvider",
  "fs.azure.account.oauth2.client.id" -> dbutils.secrets.get("adls", "application_id"),
  "fs.azure.account.oauth2.client.secret" -> dbutils.secrets.get("adls", "client_secret"),
  "fs.azure.account.oauth2.client.endpoint" -> endpoint)

// COMMAND ----------

val storageRaw = "abfss://${adls_raw}@${adls_account}.dfs.core.windows.net/"
val storageClean = "abfss://${adls_clean}@${adls_account}.dfs.core.windows.net/"

dbutils.fs.mount(
  source = storageRaw,
  mountPoint = "/mnt/raw",
  extraConfigs = configs)

dbutils.fs.mount(
  source = storageClean,
  mountPoint = "/mnt/clean",
  extraConfigs = configs)

// COMMAND ----------

dbutils.fs.ls("/mnt/raw/")

// COMMAND ----------

import java.text.SimpleDateFormat
import java.util.Date

val dateFormat = new SimpleDateFormat("yyyyMM/dd")
val today = new Date
val date = dateFormat.format(today)
val raw = spark.read.json(s"/mnt/raw/$date.json")

// COMMAND ----------

raw.printSchema

// COMMAND ----------

raw.show(5)

// COMMAND ----------

val df = raw.select(
  lit("USD").as("currency"),
  trim($"amount", "$").cast(FloatType).as("amount"),
  $"country_code",
  $"department",
  $"timestamp")

// COMMAND ----------

df.write.mode("append").partitionBy("department").parquet("/mnt/clean/sample_data")

// Databricks notebook source
import org.apache.spark.sql.functions._
import org.apache.spark.sql.types._

// COMMAND ----------

dbutils.fs.ls("/mnt/clean/")

// COMMAND ----------

dbutils.fs.ls("/mnt/curated/")

// COMMAND ----------

val clean = spark.read.parquet(s"/mnt/clean/sample_data")

// COMMAND ----------

clean.printSchema

// COMMAND ----------

clean.count

// COMMAND ----------

clean.show

// COMMAND ----------

val now = current_timestamp
val lastWeek = date_sub(now, 7)
val last30Days = date_sub(now, 30)

// COMMAND ----------

val highestAmountsLastWeek = clean.where($"timestamp" > lastWeek).sort($"amount".desc).limit(50)

// COMMAND ----------

highestAmountsLastWeek.show

// COMMAND ----------

val dfLast30Days = clean.where($"timestamp" > last30Days)

// COMMAND ----------

dfLast30Days.count

// COMMAND ----------

val deptsLast30df = dfLast30Days.groupBy("department")

// COMMAND ----------

val topGrossingDepartmentsLast30Days = deptsLast30df.agg(sum("amount").as("total_amount"), min("currency").as("currency")).withColumn("total_amount", round($"total_amount", 2)).sort($"total_amount".desc)

// COMMAND ----------

topGrossingDepartmentsLast30Days.show

// COMMAND ----------

val topSalesDepartmentsLast30Days = deptsLast30df.agg(count("*").as("total_sales")).sort($"total_sales".desc)

// COMMAND ----------

topSalesDepartmentsLast30Days.show

// COMMAND ----------

val highestAmountPerSaleDepartmentsLast30Days = deptsLast30df.agg(count("*").as("total_sales"), sum("amount").as("total_amount"), min("currency").as("currency")).withColumn("amountSaleRatio", round($"total_amount" / $"total_sales", 2)).withColumn("total_amount", round($"total_amount", 2)).sort($"amountSaleRatio".desc)

// COMMAND ----------

highestAmountPerSaleDepartmentsLast30Days.show

// COMMAND ----------

val topGrossingCountriesLast30Days = dfLast30Days.groupBy("country_code").agg(sum("amount").as("total_amount"), min("currency").as("currency")).withColumn("total_amount", round($"total_amount", 2)).sort($"total_amount".desc)

// COMMAND ----------

topGrossingCountriesLast30Days.show

// COMMAND ----------

val topGrossingDepartmentsCountriesLast30Days = dfLast30Days.groupBy("country_code", "department").agg(sum("amount").as("total_amount"), min("currency").as("currency")).withColumn("total_amount", round($"total_amount", 2)).sort($"total_amount".desc)

// COMMAND ----------

topGrossingDepartmentsCountriesLast30Days.show

// COMMAND ----------

import org.apache.spark.sql.SaveMode

// COMMAND ----------

highestAmountsLastWeek
    .write.mode(SaveMode.Overwrite)
    .parquet("/mnt/curated/highest_amounts_last_week.parquet")

// COMMAND ----------

topGrossingDepartmentsLast30Days
    .write.mode(SaveMode.Overwrite)
    .parquet("/mnt/curated/top_grossing_departments.parquet")

// COMMAND ----------

topSalesDepartmentsLast30Days
    .write.mode(SaveMode.Overwrite)
    .parquet("/mnt/curated/top_sales_departments.parquet")

// COMMAND ----------

highestAmountPerSaleDepartmentsLast30Days
    .write.mode(SaveMode.Overwrite)
    .parquet("/mnt/curated/highest_amount_sales_ratio.parquet")

// COMMAND ----------

topGrossingCountriesLast30Days
    .write.mode(SaveMode.Overwrite)
    .parquet("/mnt/curated/top_grossing_countries.parquet")

// COMMAND ----------

topGrossingDepartmentsCountriesLast30Days
    .write.mode(SaveMode.Overwrite)
    .parquet("/mnt/curated/top_grossing_departments_countries.parquet")

// COMMAND ----------

val connectionString = "jdbc:sqlserver://${server}:1433;database=${database};encrypt=true;trustServerCertificate=false;hostNameInCertificate=*.database.windows.net;loginTimeout=30;"

// COMMAND ----------

highestAmountsLastWeek
    .write.mode(SaveMode.Overwrite)
    .format("com.databricks.spark.sqldw")
    .option("url", connectionString)
    .option("user", dbutils.secrets.get(scope = "synapse", key = "username"))
    .option("password", dbutils.secrets.get(scope = "synapse", key = "password"))
    .option("forwardSparkAzureStorageCredentials", "true")
    .option("tempDir", "wasbs://${container}@${storage_account_blob_endpoint}/highestAmountsLastWeek")
    .option("dbTable", "highestAmountsLastWeek")
    .save()

// COMMAND ----------

topGrossingDepartmentsLast30Days
    .write.mode(SaveMode.Overwrite)
    .format("com.databricks.spark.sqldw")
    .option("url", connectionString)
    .option("user", dbutils.secrets.get(scope = "synapse", key = "username"))
    .option("password", dbutils.secrets.get(scope = "synapse", key = "password"))
    .option("forwardSparkAzureStorageCredentials", "true")
    .option("tempDir", "wasbs://${container}@${storage_account_blob_endpoint}/topGrossingDepartmentsLast30Days")
    .option("dbTable", "topGrossingDepartmentsLast30Days")
    .save()

// COMMAND ----------

topSalesDepartmentsLast30Days
    .write.mode(SaveMode.Overwrite)
    .format("com.databricks.spark.sqldw")
    .option("url", connectionString)
    .option("user", dbutils.secrets.get(scope = "synapse", key = "username"))
    .option("password", dbutils.secrets.get(scope = "synapse", key = "password"))
    .option("forwardSparkAzureStorageCredentials", "true")
    .option("tempDir", "wasbs://${container}@${storage_account_blob_endpoint}/topSalesDepartmentsLast30Days")
    .option("dbTable", "topSalesDepartmentsLast30Days")
    .save()

// COMMAND ----------

highestAmountPerSaleDepartmentsLast30Days
    .write.mode(SaveMode.Overwrite)
    .format("com.databricks.spark.sqldw")
    .option("url", connectionString)
    .option("user", dbutils.secrets.get(scope = "synapse", key = "username"))
    .option("password", dbutils.secrets.get(scope = "synapse", key = "password"))
    .option("forwardSparkAzureStorageCredentials", "true")
    .option("tempDir", "wasbs://${container}@${storage_account_blob_endpoint}/highestAmountPerSaleDepartmentsLast30Days")
    .option("dbTable", "highestAmountPerSaleDepartmentsLast30Days")
    .save()

// COMMAND ----------

topGrossingCountriesLast30Days
    .write.mode(SaveMode.Overwrite)
    .format("com.databricks.spark.sqldw")
    .option("url", connectionString)
    .option("user", dbutils.secrets.get(scope = "synapse", key = "username"))
    .option("password", dbutils.secrets.get(scope = "synapse", key = "password"))
    .option("forwardSparkAzureStorageCredentials", "true")
    .option("tempDir", "wasbs://${container}@${storage_account_blob_endpoint}/topGrossingCountriesLast30Days")
    .option("dbTable", "topGrossingCountriesLast30Days")
    .save()

// COMMAND ----------

topGrossingDepartmentsCountriesLast30Days
    .write.mode(SaveMode.Overwrite)
    .format("com.databricks.spark.sqldw")
    .option("url", connectionString)
    .option("user", dbutils.secrets.get(scope = "synapse", key = "username"))
    .option("password", dbutils.secrets.get(scope = "synapse", key = "password"))
    .option("forwardSparkAzureStorageCredentials", "true")
    .option("tempDir", "wasbs://${container}@${storage_account_blob_endpoint}/topGrossingDepartmentsCountriesLast30Days")
    .option("dbTable", "topGrossingDepartmentsCountriesLast30Days")
    .save()


// Databricks notebook source
import org.apache.spark.sql.functions._
import org.apache.spark.sql.types._

// COMMAND ----------

dbutils.fs.ls("/mnt/clean/")

// COMMAND ----------

dbutils.fs.ls("/mnt/transformed/")

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

highestAmountsLastWeek.write.mode(SaveMode.Overwrite).parquet("/mnt/transformed/highest_amounts_last_week.parquet")

// COMMAND ----------

topGrossingDepartmentsLast30Days.write.mode(SaveMode.Overwrite).parquet("/mnt/transformed/top_grossing_departments.parquet")

// COMMAND ----------

topSalesDepartmentsLast30Days.write.mode(SaveMode.Overwrite).parquet("/mnt/transformed/top_sales_departments.parquet")

// COMMAND ----------

highestAmountPerSaleDepartmentsLast30Days.write.mode(SaveMode.Overwrite).parquet("/mnt/transformed/highest_amount_sales_ratio.parquet")

// COMMAND ----------

topGrossingCountriesLast30Days.write.mode(SaveMode.Overwrite).parquet("/mnt/transformed/top_grossing_countries.parquet")

// COMMAND ----------

topGrossingDepartmentsCountriesLast30Days.write.mode(SaveMode.Overwrite).parquet("/mnt/transformed/top_grossing_departments_countries.parquet")

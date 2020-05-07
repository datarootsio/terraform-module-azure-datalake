// Databricks notebook source
import org.apache.spark.sql.functions._
import org.apache.spark.sql.types._

// COMMAND ----------

dbutils.fs.ls("/mnt/raw/")

// COMMAND ----------

import java.text.SimpleDateFormat
import java.util.Date

val dateFormat = new SimpleDateFormat("yyyyMM/d")
val today = new Date
val date = dateFormat.format(today)
val raw = spark.read.json(s"/mnt/raw/$date.json")

// COMMAND ----------

raw.printSchema

// COMMAND ----------

raw.show(5)

// COMMAND ----------

display(raw.limit(1))

// COMMAND ----------

val df = raw.select(
  lit("USD").as("currency"),
  trim($"amount", "$").cast(DoubleType).as("amount"),
  $"country_code",
  $"department",
  to_timestamp($"timestamp", "yyyy-MM-dd HH:mm:ss Z").as("timestamp"))

// COMMAND ----------

df.show

// COMMAND ----------

df.write.mode("append").partitionBy("department").parquet("/mnt/clean/sample_data")
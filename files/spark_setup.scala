// Databricks notebook source
sc.hadoopConfiguration.set("fs.azure.account.key.${blob_host}", dbutils.secrets.get(scope = "temp_storage", key = "access_key"))
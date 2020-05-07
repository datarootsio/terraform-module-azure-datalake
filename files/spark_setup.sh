#!/bin/sh

curl -sf -X POST "$DATABRICKS_HOST/api/2.0/jobs/runs/submit" -H "Authorization: Bearer $DATABRICKS_TOKEN" -H "Content-Type: application/json" -d "{\"existing_cluster_id\":\"$CLUSTER_ID\", \"notebook_task\": {\"notebook_path\": \"$NOTEBOOK_PATH\"}}"
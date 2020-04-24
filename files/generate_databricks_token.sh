#!/bin/sh

set -e

function parse_input() {
  test -n "$DATABRICKS_WORKSPACE_RESOURCE_ID"
  test -n "$DATABRICKS_ENDPOINT"
}

function produce_output() {
  # Get a token for the global Databricks application.
  # The resource name is fixed and never changes.
  token_response=$(az account get-access-token --resource 2ff814a6-3304-4ab8-85cb-cd0e6f879c1d)
  token=$(jq .accessToken -r <<< "$token_response")

  # Get a token for the Azure management API
  token_response=$(az account get-access-token --resource https://management.core.windows.net/)
  azToken=$(jq .accessToken -r <<< "$token_response")

  get_existing_token=$(curl -sf $DATABRICKS_ENDPOINT/api/2.0/token/list \
      -H "Authorization: Bearer $token" \
      -H "X-Databricks-Azure-SP-Management-Token:$azToken" \
      -H "X-Databricks-Azure-Workspace-Resource-Id:$DATABRICKS_WORKSPACE_RESOURCE_ID")

  if [[ ! -z "$get_existing_token"  ]] && [ "${get_existing_token}" != "{}" ]; then
    existing_token=$(jq '.token_infos[]  | select(.comment == "Default Terraform Token") | .token_id' -r <<< "$get_existing_token")
  fi

  if [[ -n "$existing_token" ]]; then
      get_existing_token=$(curl -sf $DATABRICKS_ENDPOINT/api/2.0/token/delete \
      -H "Authorization: Bearer $token" \
      -H "X-Databricks-Azure-SP-Management-Token:$azToken" \
      -H "X-Databricks-Azure-Workspace-Resource-Id:$DATABRICKS_WORKSPACE_RESOURCE_ID" \
      -d '{"token_id":"'"$existing_token"'"}')
  fi

  # You can also generate a PAT token. Note the quota limit of 600 tokens.
  api_response=$(curl -sf $DATABRICKS_ENDPOINT/api/2.0/token/create \
    -H "Authorization: Bearer $token" \
    -H "X-Databricks-Azure-SP-Management-Token:$azToken" \
    -H "X-Databricks-Azure-Workspace-Resource-Id:$DATABRICKS_WORKSPACE_RESOURCE_ID" \
    -d '{ "lifetime_seconds": 3600, "comment": "Default Terraform Token" }')
  pat_token=$(jq .token_value -r <<< "$api_response")
  echo $pat_token
}

parse_input
produce_output
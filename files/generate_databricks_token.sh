#!/bin/bash

# Change these values.
# Use a Client ID with Contributor permissions
#   on the Databricks workspace.

function parse_input() {
  # jq reads from stdin so we don't have to set up any inputs, but let's validate the outputs
  eval "$(jq -r '@sh "REGION=\(.region) DATABRICKS_WORKSPACE=\(.databricks_workspace) RESOURCE_GROUP=\(.resource_group)"')"
  if [[ -z "${DATABRICKS_WORKSPACE}" ]]; then export DATABRICKS_WORKSPACE=none; fi
  if [[ -z "${REGION}" ]]; then export REGION=none; fi
  if [[ -z "${RESOURCE_GROUP}" ]]; then export RESOURCE_GROUP=none; fi
}

function exit_with_dummy_token() {
    jq -n --arg pat_token "thisisadummytoken" '{"token":$pat_token}'
    exit 0
}

function produce_output() {

  wsId=$(az resource show \
    --resource-type Microsoft.Databricks/workspaces \
    -g "$RESOURCE_GROUP" \
    -n "$DATABRICKS_WORKSPACE" \
    --query id -o tsv) || exit_with_dummy_token

  # Get a token for the global Databricks application.
  # The resource name is fixed and never changes.
  token_response=$(az account get-access-token --resource 2ff814a6-3304-4ab8-85cb-cd0e6f879c1d)
  token=$(jq .accessToken -r <<< "$token_response") || exit_with_dummy_token

  # Get a token for the Azure management API
  token_response=$(az account get-access-token --resource https://management.core.windows.net/)
  azToken=$(jq .accessToken -r <<< "$token_response")

  get_existing_token=$(curl -sf https://$REGION.azuredatabricks.net/api/2.0/token/list \
      -H "Authorization: Bearer $token" \
      -H "X-Databricks-Azure-SP-Management-Token:$azToken" \
      -H "X-Databricks-Azure-Workspace-Resource-Id:$wsId")

  existing_token=$(jq '.token_infos[]  | select(.comment == "Default Terraform Token") | .token_id' -r <<< "$get_existing_token") || exit_with_dummy_token

  if [[ -n "$existing_token" ]]; then
      get_existing_token=$(curl -sf https://$REGION.azuredatabricks.net/api/2.0/token/delete \
      -H "Authorization: Bearer $token" \
      -H "X-Databricks-Azure-SP-Management-Token:$azToken" \
      -H "X-Databricks-Azure-Workspace-Resource-Id:$wsId" \
      -d '{"token_id":"'"$existing_token"'"}')
  fi
  # You can also generate a PAT token. Note the quota limit of 600 tokens.
  api_response=$(curl -sf https://$REGION.azuredatabricks.net/api/2.0/token/create \
    -H "Authorization: Bearer $token" \
    -H "X-Databricks-Azure-SP-Management-Token:$azToken" \
    -H "X-Databricks-Azure-Workspace-Resource-Id:$wsId" \
    -d '{ "lifetime_seconds": 3600, "comment": "Default Terraform Token" }') || exit_with_dummy_token
  pat_token=$(jq .token_value -r <<< "$api_response")
  jq -n --arg pat_token "$pat_token" '{"token":$pat_token}'
}

parse_input
produce_output
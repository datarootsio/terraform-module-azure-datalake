#!/bin/bash

token_response=$(az account get-access-token --resource https://management.core.windows.net/)
azToken=$(jq .accessToken -r <<< "$token_response")
curl -sSf -X DELETE "https://management.azure.com$RESOURCE_ID?api-version=2018-06-01" -H "Authorization: Bearer $azToken"
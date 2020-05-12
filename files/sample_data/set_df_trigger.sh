#!/bin/sh

token_response=$(az account get-access-token --resource https://management.core.windows.net/)
azToken=$(jq .accessToken -r <<< "$token_response")
curl -sSf -X POST "https://management.azure.com$TRIGGER_ID/$TRIGGER_ACTION?api-version=2018-06-01" -H "Authorization: Bearer $azToken" -H "Content-Length: 0"

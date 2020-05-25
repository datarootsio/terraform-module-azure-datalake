package test

import (
	"strings"
	"testing"
	"time"

	"github.com/gruntwork-io/terratest/modules/azure"
	"github.com/gruntwork-io/terratest/modules/random"
	"github.com/gruntwork-io/terratest/modules/terraform"
	test_structure "github.com/gruntwork-io/terratest/modules/test-structure"
	"github.com/sethvargo/go-password/password"
	"github.com/stretchr/testify/assert"
)

func getDefaultTerraformOptions(t *testing.T) (string, *terraform.Options, error) {

	tempTestFolder := test_structure.CopyTerraformFolderToTemp(t, "..", ".")

	sqlServerAdmin := random.UniqueId()
	sqlServerPass := password.Generate(30, 10, 10, false, true)
	dataLakeName := "tfadlt" + strings.ToLower(random.UniqueId())

	region, err := azure.GetRandomRegionE(t, []string{"centralus", "eastus", "eastus2", "westus", "westus2", "northeurope", "westeurope"}, nil, "")
	if err != nil {
		return "", nil, err
	}

	terraformOptions := &terraform.Options{
		TerraformDir: tempTestFolder,
		Vars:         map[string]interface{}{},
		RetryableTerraformErrors: map[string]string{
			".*429.*": "Failed to create notebooks due to rate limiting",
			".*does not have any associated worker environments.*:":        "Databricks API was not ready for requests",
			".*we are currently experiencing high demand in this region.*": "Azure service at capacity",
		},
		MaxRetries:         5,
		TimeBetweenRetries: 5 * time.Minute,
		NoColor:            true,
	}

	terraformOptions.Vars["data_lake_name"] = dataLakeName
	terraformOptions.Vars["sql_server_admin_username"] = sqlServerAdmin
	terraformOptions.Vars["sql_server_admin_password"] = sqlServerPass
	terraformOptions.Vars["region"] = region

	// default values
	terraformOptions.Vars["storage_replication"] = "LRS"
	terraformOptions.Vars["service_principal_end_date"] = time.Now().Add(time.Hour * 4).Format(time.RFC3339)
	terraformOptions.Vars["databricks_cluster_node_type"] = "Standard_DS3_v2"
	terraformOptions.Vars["databricks_cluster_version"] = "6.5.x-scala2.11"
	terraformOptions.Vars["data_warehouse_dtu"] = "DW100c"
	terraformOptions.Vars["cosmosdb_consistency_level"] = "Session"
	terraformOptions.Vars["cosmosdb_db_throughput"] = 400
	terraformOptions.Vars["databricks_sku"] = "standard"
	terraformOptions.Vars["databricks_token_lifetime"] = 60 * 60 * 4

	return dataLakeName, terraformOptions, nil
}

func TestApplyAndDestroyWithSamples(t *testing.T) {
	t.Parallel()

	name, options, err := getDefaultTerraformOptions(t)
	assert.NoError(t, err)

	defer terraform.Destroy(t, options)
	_, err = terraform.InitAndApplyE(t, options)
	assert.NoError(t, err)

	outDataLakeName, err := terraform.OutputE(t, options, "name")
	assert.NoError(t, err)

	assert.Equal(t, name, outDataLakeName)
}

func TestApplyAndDestroyWithoutSamples(t *testing.T) {
	t.Parallel()

	name, options, err := getDefaultTerraformOptions(t)
	assert.NoError(t, err)

	options.Vars["provision_sample_data"] = false

	defer terraform.Destroy(t, options)
	_, err = terraform.InitAndApplyE(t, options)
	assert.NoError(t, err)

	outDataLakeName, err := terraform.OutputE(t, options, "name")
	assert.NoError(t, err)

	assert.Equal(t, name, outDataLakeName)
}

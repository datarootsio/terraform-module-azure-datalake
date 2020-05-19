package test

import (
	"math/rand"
	"strconv"
	"testing"
	"time"

	"github.com/gruntwork-io/terratest/modules/azure"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
)

func getDefaultTerraformOptions(t *testing.T) (string, *terraform.Options, error) {
	rand.Seed(time.Now().UnixNano())
	sqlServerAdmin := randSeq(10)
	sqlServerPass := randSeq(20) + strconv.Itoa(rand.Intn(1000))
	dataLakeName := "tfadltest" + strconv.Itoa(rand.Intn(1000))

	region, err := azure.GetRandomRegionE(t, nil, nil, "")
	if err != nil {
		return "", nil, err
	}

	terraformOptions := &terraform.Options{
		TerraformDir: "../",
		Vars:         map[string]interface{}{},
		RetryableTerraformErrors: map[string]string{
			".*Response from server (429).*": "Failed to create notebooks due to rate limiting",
		},
		MaxRetries:         5,
		TimeBetweenRetries: 30 * time.Second,
	}

	terraformOptions.Vars["data_lake_name"] = dataLakeName
	terraformOptions.Vars["sql_server_admin_username"] = sqlServerAdmin
	terraformOptions.Vars["sql_server_admin_password"] = sqlServerPass
	terraformOptions.Vars["region"] = region

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

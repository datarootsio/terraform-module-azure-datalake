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

const KeyDataLakeName = "data_lake_name"

func getDefaultTerraformOptions() (string, *terraform.Options, error) {
	rand.Seed(time.Now().UnixNano())
	sqlServerAdmin := randSeq(10)
	sqlServerPass := randSeq(20) + strconv.Itoa(rand.Intn(1000))
	dataLakeName := "tfadltest" + strconv.Itoa(rand.Intn(1000))

	region, err := azure.GetRandomStableRegionE()

	if err != nil {
		return err
	}

	terraformOptions := &terraform.Options{
		TerraformDir: "../",
		Vars:         map[string]interface{}{},
		RetryableTerraformErrors: map[string]string{
			"*Response from server (429)",
		},
		MaxRetries:         5,
		TimeBetweenRetries: 30 * time.Second,
	}

	terraformOptions.Vars[KeyDataLakeName] = dataLakeName
	terraformOptions.Vars["sql_server_admin_username"] = sqlServerAdmin
	terraformOptions.Vars["sql_server_admin_password"] = sqlServerPass
	terraformOptions.Vars["region"] = region

	return dataLakeName, terraformOptions
}

func TestApplyAndDestroyWithSamples(t *testing.T) {
	t.Parallel()

	name, options, err := getDefaultTerraformOptions()
	assert.NoError(t, err)

	defer terraform.Destroy(t, options)
	err := terraform.InitAndApplyE(t, options)
	assert.NoError(t, err)

	outDataLakeName, err := terraform.OutputE(t, options, KeyDataLakeName)
	assert.NoError(t, err)

	assert.Equal(t, outDataLakeName, name)
}

func TestApplyAndDestroyWithoutSamples(t *testing.T) {
	t.Parallel()

	name, options, err := getDefaultTerraformOptions()
	assert.NoError(t, err)

	options.Vars["provision_sample_data"] = false

	defer terraform.Destroy(t, options)
	err := terraform.InitAndApplyE(t, options)
	assert.NoError(t, err)

	outDataLakeName, err := terraform.OutputE(t, options, KeyDataLakeName)
	assert.NoError(t, err)

	assert.Equal(t, outDataLakeName, name)
}

package test

import (
	"os"
	"strings"
	"testing"
	"time"

	"github.com/gruntwork-io/terratest/modules/azure"
	"github.com/gruntwork-io/terratest/modules/logger"
	"github.com/gruntwork-io/terratest/modules/random"
	"github.com/gruntwork-io/terratest/modules/terraform"
	test_structure "github.com/gruntwork-io/terratest/modules/test-structure"
	"github.com/stretchr/testify/assert"
)

func getDefaultTerraformOptions(t *testing.T) (*terraform.Options, error) {

	tempTestFolder := test_structure.CopyTerraformFolderToTemp(t, "..", "test/module_test")

	region, err := azure.GetRandomRegionE(t, []string{
		"centralus",
		"eastus",
		"eastus2",
		"westus",
		"westus2",
		"southcentralus",
		"northeurope",
		"westeurope",
		"francecentral",
		"uksouth",
	}, nil, "")
	if err != nil {
		return nil, err
	}

	terraformOptions := &terraform.Options{
		TerraformDir: tempTestFolder,
		Vars:         map[string]interface{}{},
		RetryableTerraformErrors: map[string]string{
			".*429.*": "Failed to create notebooks due to rate limiting",
			".*does not have any associated worker environments.*:":        "Databricks API was not ready for requests",
			".*we are currently experiencing high demand in this region.*": "Azure service at capacity",
			".*connection reset by peer.*":                                 "Temporary connectivity issue",
			".*Error 403 Failed to retrieve tenant ID for given token.*":   "Databricks access token not valid yet",
			".*Timeout exceeded while awaiting headers.*":                  "Databricks HTTP timeout",
		},
		MaxRetries:         5,
		TimeBetweenRetries: 5 * time.Minute,
		NoColor:            true,
		Logger:             logger.TestingT,
	}

	terraformOptions.Vars["region"] = region

	// used to distinguish resources from each test run
	githubRunID, inGithub := os.LookupEnv("GITHUB_RUN_ID")
	if inGithub {
		terraformOptions.Vars["test_id"] = githubRunID
	} else {
		terraformOptions.Vars["test_id"] = strings.ToLower(random.UniqueId())
	}

	return terraformOptions, nil
}

func TestApplyAndDestroy(t *testing.T) {
	t.Parallel()

	options, err := getDefaultTerraformOptions(t)
	assert.NoError(t, err)

	defer terraform.Destroy(t, options)
	_, err = terraform.InitAndApplyE(t, options)
	assert.NoError(t, err)
}

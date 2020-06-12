package test

import (
	"context"
	"fmt"

	"github.com/Azure/azure-sdk-for-go/services/graphrbac/1.6/graphrbac"
	"github.com/Azure/azure-sdk-for-go/services/keyvault/mgmt/2016-10-01/keyvault"
	"github.com/Azure/azure-sdk-for-go/services/resources/mgmt/2017-05-10/resources"
	"github.com/Azure/go-autorest/autorest"
	"github.com/Azure/go-autorest/autorest/adal"
	"github.com/Azure/go-autorest/autorest/azure"
	"github.com/Azure/go-autorest/autorest/azure/auth"
	"github.com/Azure/go-autorest/autorest/to"
	uuid "github.com/satori/go.uuid"
)

func setupKeyVault(ctx context.Context, keyVaultName string, resourceGroupName string, region string, subscriptionID string, clientID string, clientSecret, tenantID string) (keyvault.Vault, error) {
	tenantIDGuid, err := uuid.FromString(tenantID)
	if err != nil {
		return keyvault.Vault{}, err
	}

	objectID, err := getObjectID(ctx, tenantID, clientID, clientSecret)
	if err != nil {
		return keyvault.Vault{}, err
	}

	_, err = createResourceGroup(ctx, resourceGroupName, region, subscriptionID, clientID, clientSecret, tenantID)
	if err != nil {
		return keyvault.Vault{}, err
	}

	kvClient, err := getKeyVaultsClient(subscriptionID, clientID, clientSecret, tenantID)
	if err != nil {
		return keyvault.Vault{}, err
	}

	kv, err := kvClient.CreateOrUpdate(ctx, resourceGroupName, keyVaultName, keyvault.VaultCreateOrUpdateParameters{
		Location: to.StringPtr(region),
		Properties: &keyvault.VaultProperties{
			EnableSoftDelete: to.BoolPtr(false),
			CreateMode:       keyvault.CreateModeDefault,
			TenantID:         &tenantIDGuid,
			Sku: &keyvault.Sku{
				Name:   keyvault.Standard,
				Family: to.StringPtr("A"),
			},
			AccessPolicies: &[]keyvault.AccessPolicyEntry{
				{
					ObjectID: &objectID,
					TenantID: &tenantIDGuid,
					Permissions: &keyvault.Permissions{
						Secrets: &[]keyvault.SecretPermissions{
							keyvault.SecretPermissionsGet,
							keyvault.SecretPermissionsList,
							keyvault.SecretPermissionsDelete,
							keyvault.SecretPermissionsSet,
						},
					},
				},
			},
		},
	})

	return kv, err
}

func createResourceGroup(ctx context.Context, name string, region string, subscriptionID string, clientID string, clientSecret, tenantID string) (resources.Group, error) {
	rgClient, err := getResourceGroupsClient(subscriptionID, clientID, clientSecret, tenantID)
	if err != nil {
		return resources.Group{}, err
	}

	rg, err := rgClient.CreateOrUpdate(ctx, name, resources.Group{
		Location: to.StringPtr(region),
	})
	return rg, err
}

func destroyResourceGroup(ctx context.Context, resourceGroupName string, subscriptionID string, clientID string, clientSecret, tenantID string) (resources.GroupsDeleteFuture, error) {
	rgClient, err := getResourceGroupsClient(subscriptionID, clientID, clientSecret, tenantID)
	if err != nil {
		return resources.GroupsDeleteFuture{}, err
	}

	future, err := rgClient.Delete(ctx, resourceGroupName)
	return future, err
}

func getKeyVaultsClient(subscriptionID string, clientID string, clientSecret, tenantID string) (keyvault.VaultsClient, error) {
	kvClient := keyvault.NewVaultsClient(subscriptionID)
	authorizer, err := getARMAuthorizer(clientID, clientSecret, tenantID)
	if err != nil {
		return keyvault.VaultsClient{}, err
	}

	kvClient.Authorizer = authorizer
	return kvClient, err
}

func getResourceGroupsClient(subscriptionID string, clientID string, clientSecret, tenantID string) (resources.GroupsClient, error) {
	rgClient := resources.NewGroupsClient(subscriptionID)
	authorizer, err := getARMAuthorizer(clientID, clientSecret, tenantID)
	if err != nil {
		return resources.GroupsClient{}, err
	}

	rgClient.Authorizer = authorizer
	return rgClient, err
}

func getARMAuthorizer(clientID string, clientSecret string, tenantID string) (autorest.Authorizer, error) {
	authorizer, err := auth.NewClientCredentialsConfig(clientID, clientSecret, tenantID).Authorizer()
	return authorizer, err
}

func getObjectID(ctx context.Context, tenantID string, clientID string, clientSecret string) (string, error) {
	spClient, err := getServicePrincipalsClient(clientID, clientSecret, tenantID)
	if err != nil {
		return "", err
	}

	page, err := spClient.List(ctx, fmt.Sprintf("servicePrincipalNames/any(c:c eq '%s')", clientID))
	if err != nil {
		return "", err
	}

	servicePrincipals := page.Values()
	objectID := *servicePrincipals[0].ObjectID
	return objectID, nil
}

func getServicePrincipalsClient(clientID string, clientSecret string, tenantID string) (graphrbac.ServicePrincipalsClient, error) {
	spClient := graphrbac.NewServicePrincipalsClient(tenantID)
	authorizer, err := getGraphAuthorizer(clientID, clientSecret, tenantID)
	if err != nil {
		return graphrbac.ServicePrincipalsClient{}, err
	}

	spClient.Authorizer = authorizer
	return spClient, nil
}

func getGraphAuthorizer(clientID string, clientSecret string, tenantID string) (autorest.Authorizer, error) {
	cloudName := "AzurePublicCloud"
	env, err := azure.EnvironmentFromName(cloudName)
	if err != nil {
		return nil, err
	}

	oauthConfig, err := adal.NewOAuthConfig(env.ActiveDirectoryEndpoint, tenantID)
	if err != nil {
		return nil, err
	}

	token, err := adal.NewServicePrincipalToken(*oauthConfig, clientID, clientSecret, env.GraphEndpoint)
	if err != nil {
		return nil, err
	}

	authorizer := autorest.NewBearerAuthorizer(token)
	return authorizer, nil
}

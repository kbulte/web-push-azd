targetScope = 'subscription'

@minLength(1)
@maxLength(64)
@description('Name of the the environment which is used to generate a short unique hash used in all resources.')
param environmentName string

@minLength(1)
@description('Primary location for all resources')
param location string

@description('Name of the resourcegroup all resources will be organized in')
param resourceGroupName string = ''

@description('Name of the key vault used to store secrets')
param keyVaultName string = ''

@description('Id of the user or app to assign application roles')
param principalId string = ''

@description('Name of the appservice plan used by the appservice')
param appServicePlanName string = ''

@description('Name of the appservice used for hosting the backend API')
param apiAppServiceName string = ''

@description('Name of the appservice used for hosting the frontend application')
param webAppServiceName string = ''

param vapidPublicKey string
@secure()
param vapidPrivateKey string

var abbrs = loadJsonContent('abbreviatons.json')
var resourceToken = toLower(uniqueString(subscription().id, resourceGroupName, environmentName, location))
var tags = { 'azd-env-name': environmentName }

// When resourcegroup parameter is not provided create a resourcegroup name based on the environment
resource rg 'Microsoft.Resources/resourceGroups@2023-07-01' = {
  name: !empty(resourceGroupName) ? resourceGroupName : '${abbrs.resourcesResourceGroups}${environmentName}'
  location: location
  tags: tags
}

// Create a keyvault for storing secrets
module keyVault 'core/security/keyvault.bicep' = {
  name: 'keyvault'
  scope: rg
  params: {
    name: !empty(keyVaultName) ? keyVaultName : '${abbrs.keyVaultVaults}${resourceToken}'
    location: location
    tags: tags
    principalId: principalId
  }
}

// Create an App Service Plan to group applications under the same payment plan and SKU
module appServicePlan './core/host/appserviceplan.bicep' = {
  name: 'appserviceplan'
  scope: rg
  params: {
    name: !empty(appServicePlanName) ? appServicePlanName : '${abbrs.webServerFarms}${resourceToken}'
    location: location
    tags: tags
    sku: {
      name: 'F1' // Use a free plan. You can have 10 F1 App Service plans per region and only up to 10 Web Apps under F1 App Service Plan. Totally 100 Web Apps under F1 App Service plans per region.
    }
  }
}

// The application frontend on a free azure appservice
module web './app/web.bicep' = {
    name: 'web'
    scope: rg
    params: {
      name: !empty(webAppServiceName) ? webAppServiceName : '${abbrs.webSitesAppService}web-${resourceToken}'
      location: location
      tags: tags
      appServicePlanId: appServicePlan.outputs.id
      use32BitWorkerProcess:  true //Free plans only support 32 bit worker processes
      alwaysOn: false //Free plans don't support always on
    }
  }

// The application backend API on a free azure appservice
module api './app/api.bicep' = {
  name: 'api'
  scope: rg
  params: {
    name: !empty(apiAppServiceName) ? apiAppServiceName : '${abbrs.webSitesAppService}api-${resourceToken}'
    location: location
    tags: tags
    appServicePlanId: appServicePlan.outputs.id
    keyVaultName: keyVault.outputs.name
    use32BitWorkerProcess:  true //Free plans only support 32 bit worker processes
    alwaysOn: false //Free plans don't support always on
    allowedOrigins: [ web.outputs.SERVICE_WEB_URI ]
    appSettings: {
      API_ALLOW_ORIGINS: web.outputs.SERVICE_WEB_URI
      VAP_ID_PUBLIC_KEY: vapidPublicKey
      VAP_ID_PRIVATE_KEY: vapidPrivateKey
    }
  }
}

// set environment variables for the frontend application in the appservice, these will be used to generate client config with entrypoint.sh
module webAppSettings './core/host/appservice-appsettings.bicep' = {
  name: 'web-appsettings'
  scope: rg
  params: {
    name: web.outputs.SERVICE_WEB_NAME
    appSettings: {
      REACT_APP_API_BASE_URL: api.outputs.SERVICE_API_URI
      REACT_APP_VAP_ID_PUBLIC_KEY: vapidPublicKey
    }
  }
}


// App outputs
output AZURE_KEY_VAULT_ENDPOINT string = keyVault.outputs.endpoint
output API_BASE_URL string = api.outputs.SERVICE_API_URI
output REACT_APP_WEB_BASE_URL string = web.outputs.SERVICE_WEB_URI
output REACT_APP_API_BASE_URL string = api.outputs.SERVICE_API_URI

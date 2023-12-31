param name string
param location string = resourceGroup().location
param tags object = {}
param serviceName string = 'frontend' //needs to match services in the azure.yaml

param appCommandLine string = './entrypoint.sh -o ./env-config.js && pm2 serve /home/site/wwwroot --no-daemon --spa'
param appServicePlanId string

param use32BitWorkerProcess bool
param alwaysOn bool

module web '../core/host/appservice.bicep' = {
  name: '${name}-deployment'
  params: {
    name: name
    location: location
    appCommandLine: appCommandLine
    appServicePlanId: appServicePlanId
    use32BitWorkerProcess: use32BitWorkerProcess
    alwaysOn: alwaysOn
    runtimeName: 'node'
    runtimeVersion: '18-lts'
    tags: union(tags, { 'azd-service-name': serviceName })
  }
}

output SERVICE_WEB_IDENTITY_PRINCIPAL_ID string = web.outputs.identityPrincipalId
output SERVICE_WEB_NAME string = web.outputs.name
output SERVICE_WEB_URI string = web.outputs.uri

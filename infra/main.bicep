targetScope = 'subscription'

@description('Short lowercase prefix used to create globally unique resource names.')
@minLength(3)
@maxLength(12)
param prefix string

@description('Deployment environment.')
@allowed([
  'dev'
  'test'
  'prod'
])
param environment string = 'dev'

@description('Azure region for the resource group and resources.')
param location string

@description('Microsoft Entra tenant that issues caller tokens.')
param tenantId string

@description('Application (client) ID allowed to call the APIM API.')
param clientApplicationId string

@description('Contact address required by API Management.')
param publisherEmail string

@description('Publisher name required by API Management.')
param publisherName string = 'Platform Engineering'

@secure()
@description('Base64-encoded PFX certificate used by the Application Gateway HTTPS listener.')
param listenerCertificateData string

@secure()
@description('Password for the Application Gateway listener PFX.')
param listenerCertificatePassword string

@description('Optional Azure OpenAI model name. Leave empty to omit the deployment.')
param modelName string = ''

@description('Optional Azure OpenAI model version. Required when modelName is set.')
param modelVersion string = ''

@description('Deployment name exposed in the OpenAI request path.')
param modelDeploymentName string = 'chat'

@minValue(1)
@maxValue(1000)
param modelCapacity int = 10

@description('Tags applied to all supported resources.')
param tags object = {}

var resourceGroupName = 'rg-${prefix}-${environment}'
var deploymentTags = union({
  application: 'secure-azure-openai-landing-zone'
  environment: environment
  managedBy: 'bicep'
}, tags)

resource resourceGroup 'Microsoft.Resources/resourceGroups@2025-04-01' = {
  name: resourceGroupName
  location: location
  tags: deploymentTags
}

module landingZone 'landing-zone.bicep' = {
  name: 'landing-zone'
  scope: resourceGroup
  params: {
    prefix: prefix
    environment: environment
    location: location
    tenantId: tenantId
    clientApplicationId: clientApplicationId
    publisherEmail: publisherEmail
    publisherName: publisherName
    listenerCertificateData: listenerCertificateData
    listenerCertificatePassword: listenerCertificatePassword
    modelName: modelName
    modelVersion: modelVersion
    modelDeploymentName: modelDeploymentName
    modelCapacity: modelCapacity
    tags: deploymentTags
  }
}

output resourceGroupName string = resourceGroup.name
output applicationGatewayPublicIp string = landingZone.outputs.applicationGatewayPublicIp
output apiHostname string = landingZone.outputs.apiHostname
output openAIAccountName string = landingZone.outputs.openAIAccountName

// Secure-Azure-OpenAI-LandingZone infrastructure template.
// Resource behavior stays in this file; deployment-time values are supplied by ./environments/dev.bicepparam.

targetScope = 'subscription'

// Deployment inputs: values are explicit, reviewable, and environment-specific.

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
param environment string

@description('Azure region for the resource group and resources.')
param location string

@description('Microsoft Entra tenant that issues caller tokens.')
param tenantId string

@description('Application (client) ID allowed to call the APIM API.')
param clientApplicationId string

@description('Contact address required by API Management.')
param publisherEmail string

@description('Publisher name required by API Management.')
param publisherName string

@secure()
@description('Base64-encoded PFX certificate used by the Application Gateway HTTPS listener.')
param listenerCertificateData string

@secure()
@description('Password for the Application Gateway listener PFX.')
param listenerCertificatePassword string

@description('Optional Azure OpenAI model name. Leave empty to omit the deployment.')
param modelName string

@description('Optional Azure OpenAI model version. Required when modelName is set.')
param modelVersion string

@description('Deployment name exposed in the OpenAI request path.')
param modelDeploymentName string

@minValue(1)
@maxValue(1000)
param modelCapacity int

@description('Tags applied to all supported resources.')
param tags object

// Derived configuration: constructs deterministic names, IDs, and policy values.
var resourceGroupName = 'rg-${prefix}-${environment}'
var deploymentTags = union(
  {
    application: 'secure-azure-openai-landing-zone'
    environment: environment
    managedBy: 'bicep'
  },
  tags
)

// Resource resourceGroup: declares Microsoft.Resources/resourceGroups@2025-04-01 and its security settings.
resource resourceGroup 'Microsoft.Resources/resourceGroups@2025-04-01' = {
  name: resourceGroupName
  location: location
  tags: deploymentTags
}

// Module landingZone: composes landing-zone.bicep with validated inputs.
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

// Deployment outputs: expose identifiers needed by operators and downstream automation.
output resourceGroupName string = resourceGroup.name
output applicationGatewayPublicIp string = landingZone.outputs.applicationGatewayPublicIp
output apiHostname string = landingZone.outputs.apiHostname
output openAIAccountName string = landingZone.outputs.openAIAccountName

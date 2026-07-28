using '../main.bicep'

param prefix = 'aoailz'
param environment = 'dev'
param location = 'westeurope'
param tenantId = '00000000-0000-0000-0000-000000000000'
param clientApplicationId = '00000000-0000-0000-0000-000000000000'
param publisherEmail = 'platform@example.com'
param publisherName = 'Platform Engineering'
param listenerCertificateData = readEnvironmentVariable('APPGW_CERTIFICATE_DATA')
param listenerCertificatePassword = readEnvironmentVariable('APPGW_CERTIFICATE_PASSWORD')
param modelName = ''
param modelVersion = ''
param modelDeploymentName = 'chat'
param modelCapacity = 10
param tags = {
  owner: 'platform-engineering'
  costCenter: 'replace-me'
  dataClassification: 'confidential'
}

// Deployment values for Secure-Azure-OpenAI-LandingZone (landing-zone.bicep).
// Values are synthetic and safe by default; review placeholders before what-if or deployment.
using './landing-zone.bicep'

// Defines deterministic naming for this example environment.
param prefix = 'saolsecu'

// Supplies the environment input separately from the resource template.
param environment = 'dev'

// Selects the Azure region explicitly for this environment.
param location = 'westeurope'

// Supplies a synthetic identity or scope identifier; replace it with the approved value.
param tenantId = '00000000-0000-4000-8000-000000000001'

// Supplies a synthetic identity or scope identifier; replace it with the approved value.
param clientApplicationId = '00000000-0000-4000-8000-000000000001'

// Supplies the publisherEmail input separately from the resource template.
param publisherEmail = 'platform@example.com'

// Defines deterministic naming for this example environment.
param publisherName = 'Platform Engineering'

// Reads sensitive deployment material from the environment instead of source control.
param listenerCertificateData = readEnvironmentVariable('APPGW_CERTIFICATE_DATA', 'REPLACE_BEFORE_DEPLOYMENT')

// Reads sensitive deployment material from the environment instead of source control.
param listenerCertificatePassword = readEnvironmentVariable('APPGW_CERTIFICATE_PASSWORD', 'REPLACE_BEFORE_DEPLOYMENT')

// Defines deterministic naming for this example environment.
param modelName = ''

// Supplies the modelVersion input separately from the resource template.
param modelVersion = ''

// Defines deterministic naming for this example environment.
param modelDeploymentName = 'chat'

// Supplies the modelCapacity input separately from the resource template.
param modelCapacity = 10

// Provides ownership and governance metadata outside the resource template.
param tags = {
  environment: 'dev'
  owner: 'platform-engineering'
}

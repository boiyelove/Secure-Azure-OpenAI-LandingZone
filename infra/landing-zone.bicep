targetScope = 'resourceGroup'

param prefix string
param environment string
param location string
param tenantId string
param clientApplicationId string
param publisherEmail string
param publisherName string
@secure()
param listenerCertificateData string
@secure()
param listenerCertificatePassword string
param modelName string
param modelVersion string
param modelDeploymentName string
param modelCapacity int
param tags object

var suffix = uniqueString(subscription().id, resourceGroup().id)
var compactPrefix = replace('${prefix}${environment}', '-', '')
var openAIName = take('oai${compactPrefix}${suffix}', 64)
var apimName = take('apim-${prefix}-${environment}-${suffix}', 50)
var gatewayName = 'agw-${prefix}-${environment}'
var vnetName = 'vnet-${prefix}-${environment}'
var workspaceName = 'log-${prefix}-${environment}'
var openAIDnsZoneName = 'privatelink.openai.azure.com'
var openAIRoleDefinitionId = subscriptionResourceId(
  'Microsoft.Authorization/roleDefinitions',
  '5e0bd9bd-7b93-4f28-af87-19fc36ad61bd'
)

resource workspace 'Microsoft.OperationalInsights/workspaces@2025-02-01' = {
  name: workspaceName
  location: location
  tags: tags
  properties: {
    retentionInDays: 30
    features: {
      enableLogAccessUsingOnlyResourcePermissions: true
    }
  }
}

resource apimNsg 'Microsoft.Network/networkSecurityGroups@2024-07-01' = {
  name: 'nsg-apim-${prefix}-${environment}'
  location: location
  tags: tags
  properties: {
    securityRules: [
      {
        name: 'AllowApiManagementControlPlane'
        properties: {
          priority: 100
          direction: 'Inbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '3443'
          sourceAddressPrefix: 'ApiManagement'
          destinationAddressPrefix: 'VirtualNetwork'
        }
      }
      {
        name: 'AllowGatewayFromApplicationGateway'
        properties: {
          priority: 110
          direction: 'Inbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '443'
          sourceAddressPrefix: '10.42.0.0/24'
          destinationAddressPrefix: '10.42.1.0/26'
        }
      }
      {
        name: 'DenyOtherVnetInbound'
        properties: {
          priority: 4096
          direction: 'Inbound'
          access: 'Deny'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
        }
      }
    ]
  }
}

resource vnet 'Microsoft.Network/virtualNetworks@2024-07-01' = {
  name: vnetName
  location: location
  tags: tags
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.42.0.0/16'
      ]
    }
    subnets: [
      {
        name: 'application-gateway'
        properties: {
          addressPrefix: '10.42.0.0/24'
        }
      }
      {
        name: 'api-management'
        properties: {
          addressPrefix: '10.42.1.0/26'
          networkSecurityGroup: {
            id: apimNsg.id
          }
        }
      }
      {
        name: 'private-endpoints'
        properties: {
          addressPrefix: '10.42.2.0/27'
          privateEndpointNetworkPolicies: 'Disabled'
        }
      }
    ]
  }
}

resource applicationGatewaySubnet 'Microsoft.Network/virtualNetworks/subnets@2024-07-01' existing = {
  parent: vnet
  name: 'application-gateway'
}

resource apimSubnet 'Microsoft.Network/virtualNetworks/subnets@2024-07-01' existing = {
  parent: vnet
  name: 'api-management'
}

resource privateEndpointSubnet 'Microsoft.Network/virtualNetworks/subnets@2024-07-01' existing = {
  parent: vnet
  name: 'private-endpoints'
}

resource openAI 'Microsoft.CognitiveServices/accounts@2025-06-01' = {
  name: openAIName
  location: location
  kind: 'OpenAI'
  sku: {
    name: 'S0'
  }
  identity: {
    type: 'SystemAssigned'
  }
  tags: tags
  properties: {
    customSubDomainName: openAIName
    disableLocalAuth: true
    publicNetworkAccess: 'Disabled'
    networkAcls: {
      defaultAction: 'Deny'
    }
    restrictOutboundNetworkAccess: true
    dynamicThrottlingEnabled: true
  }
}

resource modelDeployment 'Microsoft.CognitiveServices/accounts/deployments@2025-06-01' = if (!empty(modelName)) {
  parent: openAI
  name: modelDeploymentName
  sku: {
    name: 'GlobalStandard'
    capacity: modelCapacity
  }
  properties: {
    model: {
      format: 'OpenAI'
      name: modelName
      version: modelVersion
    }
    versionUpgradeOption: 'NoAutoUpgrade'
  }
}

resource openAIDns 'Microsoft.Network/privateDnsZones@2024-06-01' = {
  name: openAIDnsZoneName
  location: 'global'
  tags: tags
}

resource openAIDnsLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2024-06-01' = {
  parent: openAIDns
  name: 'link-${vnetName}'
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: vnet.id
    }
  }
}

resource openAIPrivateEndpoint 'Microsoft.Network/privateEndpoints@2024-07-01' = {
  name: 'pep-${openAIName}'
  location: location
  tags: tags
  properties: {
    subnet: {
      id: privateEndpointSubnet.id
    }
    privateLinkServiceConnections: [
      {
        name: 'openai'
        properties: {
          privateLinkServiceId: openAI.id
          groupIds: [
            'account'
          ]
        }
      }
    ]
  }
}

resource openAIDnsGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2024-07-01' = {
  parent: openAIPrivateEndpoint
  name: 'default'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'openai'
        properties: {
          privateDnsZoneId: openAIDns.id
        }
      }
    ]
  }
}

resource apim 'Microsoft.ApiManagement/service@2024-05-01' = {
  name: apimName
  location: location
  tags: tags
  sku: {
    name: 'Developer'
    capacity: 1
  }
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    publisherEmail: publisherEmail
    publisherName: publisherName
    publicNetworkAccess: 'Enabled'
    virtualNetworkType: 'Internal'
    virtualNetworkConfiguration: {
      subnetResourceId: apimSubnet.id
    }
  }
}

resource openAIUserRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(openAI.id, apim.id, openAIRoleDefinitionId)
  scope: openAI
  properties: {
    principalId: apim.identity.principalId
    principalType: 'ServicePrincipal'
    roleDefinitionId: openAIRoleDefinitionId
  }
}

resource tenantNamedValue 'Microsoft.ApiManagement/service/namedValues@2024-05-01' = {
  parent: apim
  name: 'entra-tenant-id'
  properties: {
    displayName: 'entra-tenant-id'
    secret: false
    value: tenantId
  }
}

resource audienceNamedValue 'Microsoft.ApiManagement/service/namedValues@2024-05-01' = {
  parent: apim
  name: 'client-application-id'
  properties: {
    displayName: 'client-application-id'
    secret: false
    value: clientApplicationId
  }
}

resource backendNamedValue 'Microsoft.ApiManagement/service/namedValues@2024-05-01' = {
  parent: apim
  name: 'openai-backend-url'
  properties: {
    displayName: 'openai-backend-url'
    secret: false
    value: '${openAI.properties.endpoint}openai'
  }
}

resource openAIApi 'Microsoft.ApiManagement/service/apis@2024-05-01' = {
  parent: apim
  name: 'openai'
  properties: {
    displayName: 'Governed Azure OpenAI'
    path: 'openai'
    protocols: [
      'https'
    ]
    subscriptionRequired: false
    type: 'http'
    format: 'openapi+json'
    value: loadTextContent('../policies/openapi.json')
  }
}

resource openAIPolicy 'Microsoft.ApiManagement/service/apis/policies@2024-05-01' = {
  parent: openAIApi
  name: 'policy'
  properties: {
    format: 'rawxml'
    value: loadTextContent('../policies/api-policy.xml')
  }
  dependsOn: [
    tenantNamedValue
    audienceNamedValue
    backendNamedValue
    openAIUserRole
  ]
}

resource publicIp 'Microsoft.Network/publicIPAddresses@2024-07-01' = {
  name: 'pip-${gatewayName}'
  location: location
  tags: tags
  sku: {
    name: 'Standard'
  }
  zones: [
    '1'
    '2'
    '3'
  ]
  properties: {
    publicIPAllocationMethod: 'Static'
  }
}

resource wafPolicy 'Microsoft.Network/ApplicationGatewayWebApplicationFirewallPolicies@2024-07-01' = {
  name: 'waf-${prefix}-${environment}'
  location: location
  tags: tags
  properties: {
    policySettings: {
      state: 'Enabled'
      mode: 'Prevention'
      requestBodyCheck: true
      maxRequestBodySizeInKb: 128
      fileUploadLimitInMb: 1
    }
    managedRules: {
      managedRuleSets: [
        {
          ruleSetType: 'OWASP'
          ruleSetVersion: '3.2'
        }
      ]
    }
  }
}

resource applicationGateway 'Microsoft.Network/applicationGateways@2024-07-01' = {
  name: gatewayName
  location: location
  tags: tags
  zones: [
    '1'
    '2'
    '3'
  ]
  properties: {
    firewallPolicy: {
      id: wafPolicy.id
    }
    sku: {
      name: 'WAF_v2'
      tier: 'WAF_v2'
    }
    autoscaleConfiguration: {
      minCapacity: 1
      maxCapacity: 2
    }
    gatewayIPConfigurations: [
      {
        name: 'gateway'
        properties: {
          subnet: {
            id: applicationGatewaySubnet.id
          }
        }
      }
    ]
    frontendIPConfigurations: [
      {
        name: 'public'
        properties: {
          publicIPAddress: {
            id: publicIp.id
          }
        }
      }
    ]
    frontendPorts: [
      {
        name: 'https'
        properties: {
          port: 443
        }
      }
    ]
    backendAddressPools: [
      {
        name: 'apim'
        properties: {
          backendAddresses: [
            {
              fqdn: '${apimName}.azure-api.net'
            }
          ]
        }
      }
    ]
    backendHttpSettingsCollection: [
      {
        name: 'apim-https'
        properties: {
          port: 443
          protocol: 'Https'
          cookieBasedAffinity: 'Disabled'
          requestTimeout: 120
          hostName: '${apimName}.azure-api.net'
          probe: {
            id: resourceId('Microsoft.Network/applicationGateways/probes', gatewayName, 'apim-status')
          }
        }
      }
    ]
    httpListeners: [
      {
        name: 'https'
        properties: {
          frontendIPConfiguration: {
            id: resourceId('Microsoft.Network/applicationGateways/frontendIPConfigurations', gatewayName, 'public')
          }
          frontendPort: {
            id: resourceId('Microsoft.Network/applicationGateways/frontendPorts', gatewayName, 'https')
          }
          protocol: 'Https'
          sslCertificate: {
            id: resourceId('Microsoft.Network/applicationGateways/sslCertificates', gatewayName, 'listener')
          }
        }
      }
    ]
    sslCertificates: [
      {
        name: 'listener'
        properties: {
          data: listenerCertificateData
          password: listenerCertificatePassword
        }
      }
    ]
    probes: [
      {
        name: 'apim-status'
        properties: {
          protocol: 'Https'
          path: '/status-0123456789abcdef'
          interval: 30
          timeout: 30
          unhealthyThreshold: 3
          pickHostNameFromBackendHttpSettings: true
          match: {
            statusCodes: [
              '200-399'
            ]
          }
        }
      }
    ]
    requestRoutingRules: [
      {
        name: 'openai'
        properties: {
          ruleType: 'Basic'
          priority: 100
          httpListener: {
            id: resourceId('Microsoft.Network/applicationGateways/httpListeners', gatewayName, 'https')
          }
          backendAddressPool: {
            id: resourceId('Microsoft.Network/applicationGateways/backendAddressPools', gatewayName, 'apim')
          }
          backendHttpSettings: {
            id: resourceId('Microsoft.Network/applicationGateways/backendHttpSettingsCollection', gatewayName, 'apim-https')
          }
        }
      }
    ]
  }
}

resource workspaceDiagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'send-to-${workspaceName}'
  scope: openAI
  properties: {
    workspaceId: workspace.id
    logs: [
      {
        categoryGroup: 'audit'
        enabled: true
      }
      {
        categoryGroup: 'allLogs'
        enabled: true
      }
    ]
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
      }
    ]
  }
}

resource apimDiagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'send-to-${workspaceName}'
  scope: apim
  properties: {
    workspaceId: workspace.id
    logs: [
      {
        categoryGroup: 'audit'
        enabled: true
      }
      {
        categoryGroup: 'allLogs'
        enabled: true
      }
    ]
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
      }
    ]
  }
}

resource gatewayDiagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'send-to-${workspaceName}'
  scope: applicationGateway
  properties: {
    workspaceId: workspace.id
    logs: [
      {
        categoryGroup: 'allLogs'
        enabled: true
      }
    ]
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
      }
    ]
  }
}

output applicationGatewayPublicIp string = publicIp.properties.ipAddress
output apiHostname string = '${apimName}.azure-api.net'
output openAIAccountName string = openAI.name

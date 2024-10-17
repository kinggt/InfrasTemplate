@description('Required. Name of the Key Vault. Must be globally unique.')
@maxLength(24)
param name string

@description('required. The name of the Log Analytics workspace to configure the diagnostic logs.')
param logAnalyticsName string

@description('Optional. Location for all resources.')
param location string = resourceGroup().location

@description('Optional. softDelete data retention days. It accepts >=7 and <=90.')
param softDeleteRetentionInDays int = 7

@description('Optional. The vault\'s create mode to indicate whether the vault need to be recovered or not. - recover or default.')
param createMode string = 'default'

@description('Optional. Specifies the SKU for the vault.')
@allowed([
  'premium'
  'standard'
])
param sku string = 'standard'

@description('Optional. The outbound IP addresses of the function app.')
param funcOutboundIpAddresses string = ''

@description('Optional. The possible outbound IP addresses of the function app.')
param funcPossibleOutboundIpAddresses string = ''

@description('Optional. The object id of the identity to be assigned as the Key Vault\'s User Assigned Identity.')
param identityObjectIds array = []

var identityVaultAccessPolicy = [
  for objectId in identityObjectIds: {
    tenantId: subscription().tenantId
    objectId: objectId
    permissions: {
      secrets: [
        'Get'
        'List'
        'Set'
      ]
      keys: [
        'Get'
        'List'
        'Update'
        'Create'
        'UnwrapKey'
        'WrapKey'
      ]
      certificates: [
        'Get'
        'List'
        'Update'
        'Create'
      ]
    }
  }
]

param ipAddressesResult array = concat(
  empty(funcOutboundIpAddresses) ? [] : split(funcOutboundIpAddresses, ','),
  empty(funcOutboundIpAddresses) ? [] : split(funcPossibleOutboundIpAddresses, ',')
)

resource keyVault 'Microsoft.KeyVault/vaults@2022-07-01' = {
  name: name
  location: location
  properties: {
    enabledForDiskEncryption: true
    enableSoftDelete: true
    softDeleteRetentionInDays: softDeleteRetentionInDays
    createMode: createMode
    enablePurgeProtection: true
    tenantId: subscription().tenantId
    accessPolicies: identityVaultAccessPolicy
    sku: {
      name: sku
      family: 'A'
    }
    networkAcls: {
      defaultAction: 'Deny'
      bypass: 'AzureServices'
      ipRules: [for ipAddress in ipAddressesResult: { value: ipAddress }]
    }
  }
}

resource logAnalytics 'Microsoft.OperationalInsights/workspaces@2021-06-01' existing = {
  name: logAnalyticsName
}

resource diagnosticLogs 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'keyVaultDiagnosticlog'
  scope: keyVault
  properties: {
    workspaceId: logAnalytics.id
    logs: [
      {
        category: null
        categoryGroup: 'audit'
        enabled: true
        retentionPolicy: {
          days: 0
          enabled: false
        }
      }
      {
        category: null
        categoryGroup: 'allLogs'
        enabled: true
        retentionPolicy: {
          days: 0
          enabled: false
        }
      }
    ]
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
        retentionPolicy: {
          days: 0
          enabled: false
        }
      }
    ]
  }
}

@description('The resource id of the Key Vault.')
output resourceId string = keyVault.id

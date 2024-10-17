@maxLength(24)
@description('Required. Name of the Storage Account. Must be lower-case.')
param name string

@description('Optional. Location for all resources.')
param location string = resourceGroup().location

@allowed([
  'Storage'
  'StorageV2'
  'BlobStorage'
  'FileStorage'
  'BlockBlobStorage'
])
@description('Optional. Type of Storage Account to create.')
param kind string = 'StorageV2'

@allowed([
  'Standard_LRS'
  'Standard_GRS'
  'Standard_RAGRS'
  'Standard_ZRS'
  'Premium_LRS'
  'Premium_ZRS'
  'Standard_GZRS'
  'Standard_RAGZRS'
])
@description('Optional. Storage Account Sku Name.')
param skuName string = 'Standard_GRS'

@allowed([
  'Premium'
  'Hot'
  'Cool'
])
@description('Conditional. Required if the Storage Account kind is set to BlobStorage. The access tier is used for billing. The "Premium" access tier is the default value for premium block blobs storage account type and it cannot be changed for the premium block blobs storage account type.')
param accessTier string = 'Hot'

@description('Optional. Indicates whether the storage account permits requests to be authorized with the account access key via Shared Key. If false, then all requests, including shared access signatures, must be authorized with Azure Active Directory (Azure AD). The default value is null, which is equivalent to true.')
param allowSharedKeyAccess bool = true

@allowed([
  'TLS1_0'
  'TLS1_1'
  'TLS1_2'
])
@description('Optional. Set the minimum TLS version on request to storage.')
param minimumTlsVersion string = 'TLS1_2'

@description('Optional.Enable soft-delete for containers')
param containerSoftDeleteEnabled bool = true

@description('Optinal.How long container should be keept after deleting')
param containerSoftDeleteDays int = 14

@description('Optianl.Enable soft-delete for blobs in containers')
param blobSoftDeleteEnabled bool = false

@description('Optinal.How long blob should be keept after deleting')
param blobSoftDeleteDays int = 14

@description('Optional.What containers should be created')
param containers array = [] //if containers need to be created

@description('Optional.The name of the KeyVault to store the storage account connection string.')
param keyVaultName string = ''

@description('Optional.The name of the KeyVault secret to store the storage account connection string.')
param keyVaultSecretName string = 'StorageAccountOptions--ConnectionString'

resource storageAccount 'Microsoft.Storage/storageAccounts@2022-09-01' = {
  name: name
  location: location
  kind: kind
  sku: {
    name: skuName
  }
  properties: {
    allowSharedKeyAccess: allowSharedKeyAccess
    accessTier: (kind != 'Storage' && kind != 'BlockBlobStorage') ? accessTier : null
    supportsHttpsTrafficOnly: true
    minimumTlsVersion: minimumTlsVersion
    networkAcls: {
      defaultAction: 'Deny'
      bypass: 'AzureServices'
    }
    allowBlobPublicAccess: false
  }
}

// Setup soft delte
resource storageAccountBlobServices 'Microsoft.Storage/storageAccounts/blobServices@2022-09-01' = {
  name: 'default'
  parent: storageAccount
  properties: {
    containerDeleteRetentionPolicy: {
      enabled: containerSoftDeleteEnabled
      days: containerSoftDeleteDays
    }
    deleteRetentionPolicy: {
      enabled: blobSoftDeleteEnabled
      days: blobSoftDeleteDays
    }
  }
}

resource containersCreate 'Microsoft.Storage/storageAccounts/blobServices/containers@2021-06-01' = [
  for containerName in containers: {
    parent: storageAccountBlobServices
    name: '${containerName}'
    properties: {
      publicAccess: 'None'
      metadata: {}
    }
  }
]

resource keyVault 'Microsoft.KeyVault/vaults@2022-07-01' existing = if (!empty(keyVaultName)) {
  name: keyVaultName
}

var storageAccountKey = '${listKeys(storageAccount.id, storageAccount.apiVersion).keys[0].value}'
var connectionString = 'DefaultEndpointsProtocol=https;AccountName=${name};AccountKey=${storageAccountKey};EndpointSuffix=${environment().suffixes.storage};'

resource secret 'Microsoft.KeyVault/vaults/secrets@2022-07-01' = if (!empty(keyVaultName)) {
  name: keyVaultSecretName
  parent: keyVault
  properties: {
    attributes: {
      enabled: true
    }
    value: connectionString
  }
}

@description('The resourceId of the storage account')
output storageAccountId string = storageAccount.id

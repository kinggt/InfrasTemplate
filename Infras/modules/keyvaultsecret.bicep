@description('Required. The name of the parent key vault.')
param keyVaultName string

@description('Required. The name of the secret.')
param name string

@description('Optional. Expiry date in seconds since 1970-01-01T00:00:00Z. For security reasons, it is recommended to set an expiration date whenever possible.')
param attributesExp int?

@description('Required. The value of the secret. This value will be encrypted in the Key Vault.')
@secure()
param value string

resource keyVault 'Microsoft.KeyVault/vaults@2022-07-01' existing = {
  name: keyVaultName
}

resource secret 'Microsoft.KeyVault/vaults/secrets@2022-07-01' = {
  name: name
  parent: keyVault
  properties: {
    attributes: {
      enabled: true
      exp: attributesExp
    }
    value: value
  }
}

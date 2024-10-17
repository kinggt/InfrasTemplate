@description('Required. The name of the private endpoint.')
param name string

@description('Optional. Location for all resources.')
param location string = resourceGroup().location

@description('Required. The resource ID of the subnet where the private endpoint will be located.')
param subnetId string

@description('Required. The resource ID of the service to which the private endpoint is connecting.')
param privateLinkServiceId string

@description('Required. The group ID of the private link service resource that the private endpoint is connecting to.')
param groupId string

@description('Required. The resource ID of the private DNS zone that will be linked to the private endpoint.')
param privateDnsZoneId string = ''

resource privateEndpoint 'Microsoft.Network/privateEndpoints@2021-05-01' = {
  name: name
  location: location
  properties: {
    subnet: {
      id: subnetId
    }
    privateLinkServiceConnections: [
      {
        name: name
        properties: {
          privateLinkServiceConnectionState: {
            status: 'Approved'
            description: 'Auto-approved'
          }
          privateLinkServiceId: privateLinkServiceId
          groupIds: [
            groupId
          ]
        }
      }
    ]
  }
}

resource privateDnsZoneGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2021-03-01' = if (!empty(privateDnsZoneId)) {
  parent: privateEndpoint
  name: 'dnsgroupname'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'config1'
        properties: {
          privateDnsZoneId: privateDnsZoneId
        }
      }
    ]
  }
}

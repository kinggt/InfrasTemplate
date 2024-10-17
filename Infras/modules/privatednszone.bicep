@description('Required.The name of the private DNS zone to create. This DNS zone will be used for name resolution within a specified virtual network.')
param privateDnsZoneName string

@description('Required.The resource ID of the virtual network to which the private DNS zone will be linked. This enables DNS resolution within this virtual network for the specified DNS zone.')
param vnetId string

resource privateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: privateDnsZoneName
  location: 'global'
  properties: {}
}

resource privateDnsZoneLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  parent: privateDnsZone
  name: '${privateDnsZoneName}-link'
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: vnetId
    }
  }
}

@description('The resource ID of the private DNS zone.')
output resourceId string = privateDnsZone.id

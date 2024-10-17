@description('Required. The name of the Virtual Network (vNet).')
param name string

@description('Optional. Location for all resources.')
param location string = resourceGroup().location

@description('Required. An Array of 1 or more IP Address Prefixes for the Virtual Network.')
param addressPrefixes array

@description('Optional. An Array of subnets to deploy to the Virtual Network.')
param subnets array = []

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2021-05-01' = {
  name: name
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: addressPrefixes
    }
    subnets: [
      for subnet in subnets: {
        name: subnet.name
        properties: {
          addressPrefix: subnet.addressPrefix
          addressPrefixes: contains(subnet, 'addressPrefixes') ? subnet.addressPrefixes : []
          applicationGatewayIpConfigurations: contains(subnet, 'applicationGatewayIPConfigurations')
            ? subnet.applicationGatewayIPConfigurations
            : []
          delegations: contains(subnet, 'delegations') ? subnet.delegations : []
          ipAllocations: contains(subnet, 'ipAllocations') ? subnet.ipAllocations : []
          natGateway: contains(subnet, 'natGatewayResourceId')
            ? {
                id: subnet.natGatewayResourceId
              }
            : null
          networkSecurityGroup: contains(subnet, 'networkSecurityGroupResourceId')
            ? {
                id: subnet.networkSecurityGroupResourceId
              }
            : null
          privateEndpointNetworkPolicies: contains(subnet, 'privateEndpointNetworkPolicies')
            ? subnet.privateEndpointNetworkPolicies
            : null
          privateLinkServiceNetworkPolicies: contains(subnet, 'privateLinkServiceNetworkPolicies')
            ? subnet.privateLinkServiceNetworkPolicies
            : null
          routeTable: contains(subnet, 'routeTableResourceId')
            ? {
                id: subnet.routeTableResourceId
              }
            : null
          serviceEndpoints: contains(subnet, 'serviceEndpoints') ? subnet.serviceEndpoints : []
          serviceEndpointPolicies: contains(subnet, 'serviceEndpointPolicies') ? subnet.serviceEndpointPolicies : []
        }
      }
    ]
  }
}

@description('The resource IDs of the deployed subnets.')
output subnetResourceIds array = [
  for subnet in subnets: az.resourceId('Microsoft.Network/virtualNetworks/subnets', name, subnet.name)
]

@description('The resource ID of the virtual network.')
output resourceId string = virtualNetwork.id

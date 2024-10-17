@description('Required. Name of the app service plan.')
@minLength(1)
@maxLength(60)
param name string

@description('Required. Defines the name, tier, size, family and capacity of the App Service Plan.')
@metadata({
  example: '''
  {
    name: 'P1v3'
    tier: 'Premium'
    size: 'P1v3'
    family: 'P'
    capacity: 3
  }
  '''
})
param sku object = {
  name: 'B1'
  tier: 'Basic'
  size: 'B1'
  family: 'B'
  capacity: 1
}

@description('Optional. Location for all resources.')
param location string = resourceGroup().location

@description('Optional. Kind of server OS.')
@allowed([
  'App'
  'Elastic'
  'FunctionApp'
  'Windows'
  'Linux'
])
param kind string = 'Linux'

@description('Conditional. Defaults to true when creating Linux App Service Plan. If creating a Windows/app App Service Plan , does not need to be specified.')
param reserved bool = true

resource appServicePlan 'Microsoft.Web/serverfarms@2022-09-01' = {
  name: name
  kind: kind
  location: location
  sku: sku
  properties: {
    perSiteScaling: false
    reserved: reserved
  }
}

@description('The resource ID of the app service plan.')
output resourceId string = appServicePlan.id

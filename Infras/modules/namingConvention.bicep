@description('The environment that the resource is for. Accepted values are defined to ensure consistency.')
@allowed([
  'dev'
  'test'
  'stag'
  'prod'
  'devtest' // common services shared across environments
])
param environmentType string

@description('The name of the service')
param serviceName string

@description('The short suffix of location')
param locationShortSuffix string

var environmentMappings = { devTest: 'dt', dev: 'd', test: 't', stag: 's', prod: 'p' }
var shortEnvironmentType = environmentMappings[environmentType]
var aspnetCoreEnvironmentMappings = {
  devTest: 'Devtest'
  test: 'Test'
  stag: 'Staging'
  prod: 'Production'
}
var aspnetCoreEnvironment = aspnetCoreEnvironmentMappings[environmentType]

var keyVaultName = '${serviceName}-kv-${shortEnvironmentType}-${locationShortSuffix}'
var storageAccountName = '${serviceName}sa${shortEnvironmentType}${locationShortSuffix}'
var appServicePlanName = '${serviceName}-asp-${shortEnvironmentType}-${locationShortSuffix}'
var functionAppServicePlanName = '${serviceName}-func-asp-${shortEnvironmentType}-${locationShortSuffix}'
var appServiceName = '${serviceName}-app-${shortEnvironmentType}-${locationShortSuffix}'
var applicationInsightName = '${serviceName}-appins-${shortEnvironmentType}-${locationShortSuffix}'
var logAnalyticsWorkspaceName = '${serviceName}-law-${shortEnvironmentType}-${locationShortSuffix}'
var vnetName = '${serviceName}-vnet-${shortEnvironmentType}-${locationShortSuffix}'
var privateEndpointName = '${serviceName}-pe-${shortEnvironmentType}-${locationShortSuffix}'
var functionAppName = '${serviceName}-func-${shortEnvironmentType}-${locationShortSuffix}'
var agentNetworkSecurityGroupName = '${serviceName}-nsg-${shortEnvironmentType}-${locationShortSuffix}'
var virtualMachineScaleSetName = '${serviceName}-vm-set-${shortEnvironmentType}-${locationShortSuffix}'

output keyVaultName string = keyVaultName
output storageAccountName string = storageAccountName
output appServicePlanName string = appServicePlanName
output functionAppServicePlanName string = functionAppServicePlanName
output appServiceName string = appServiceName
output applicationInsightName string = applicationInsightName
output logAnalyticsWorkspaceName string = logAnalyticsWorkspaceName
output privateEndpointName string = privateEndpointName
output vnetName string = vnetName
output aspnetCoreEnvironment string = aspnetCoreEnvironment
output functionAppName string = functionAppName
output agentNetworkSecurityGroupName string = agentNetworkSecurityGroupName
output virtualMachineScaleSetName string = virtualMachineScaleSetName

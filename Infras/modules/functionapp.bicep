@description('required. The name of the function app.')
param functionAppName string

@description('required. The environment type of the function app.')
param environmentType string

@description('Optional. Location for all Resources.')
param location string = resourceGroup().location

@description('required. The storage account name of the function app.')
param funcStorageAccountName string

@description('required. The app insights name of the function app.')
param appInsightName string

@description('optional. The name of the function app service plan. If  provided, it means use dedicated app service plan.')
param dedicatedAppServicePlanName string = ''

@description('optional. Defines the name, tier, size, family and capacity of the App Service Plan.')
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
param dedicatedAppServicePlanSku object = {}

@description('optional. Control which environment use dedicated app service plan.')
param environmentUsingAppServicePlan array = []

@description('optional. Use by linux function app')
param linuxFxVersion string = 'DOTNET-ISOLATED|8.0'

@description('optional. Used by windows function app')
param netFrameworkVersion string = 'v8.0'

@description('optional. The runtime stack of the function app. Default is "dotnet-isolated".')
@allowed([
  'dotnet-isolated'
  'dotnet'
])
param functionAppWokerRuntime string = 'dotnet-isolated'

@description('optional. Extra function app settings.')
param extraFunctionAppSettings array = []

@description('optional. Some sensitive settings like connection strings, keys, etc. should be encrypted.')
@metadata({
  example: '''
  {
    settings: [{
      key:'StorageAccount_ConnectionString'
      value:'xxxxxxx'
      }
    ]
  }
  '''
})
param sensitiveSettingsObject object = {}

var sensitiveSettings = sensitiveSettingsObject.settings

var functionHostingPlanName = '${functionAppName}-plan'

var usingDedicatedAppServicePlan = !empty(dedicatedAppServicePlanName) && !empty(dedicatedAppServicePlanSku) && contains(
  environmentUsingAppServicePlan,
  environmentType
)

resource defualtHostingPlan 'Microsoft.Web/serverfarms@2021-03-01' = if (!usingDedicatedAppServicePlan) {
  name: functionHostingPlanName
  location: location
  sku: {
    name: 'Y1'
    tier: 'Dynamic'
  }
  properties: {}
}

resource dedicatedHostingPlan 'Microsoft.Web/serverFarms@2022-03-01' = if (usingDedicatedAppServicePlan) {
  name: dedicatedAppServicePlanName
  location: location
  kind: 'linux'
  sku: dedicatedAppServicePlanSku
  properties: {
    reserved: true
  }
}

resource appInsights 'Microsoft.Insights/components@2020-02-02-preview' existing = {
  name: appInsightName
}

resource storageAccount 'Microsoft.Storage/storageAccounts@2022-05-01' existing = {
  name: funcStorageAccountName
}

var defaultAppsettings = [
  {
    name: 'AzureWebJobsStorage'
    value: 'DefaultEndpointsProtocol=https;AccountName=${funcStorageAccountName};EndpointSuffix=${environment().suffixes.storage};AccountKey=${storageAccount.listKeys().keys[0].value}'
  }
  {
    name: 'WEBSITE_CONTENTAZUREFILECONNECTIONSTRING'
    value: 'DefaultEndpointsProtocol=https;AccountName=${funcStorageAccountName};EndpointSuffix=${environment().suffixes.storage};AccountKey=${storageAccount.listKeys().keys[0].value}'
  }
  {
    name: 'WEBSITE_CONTENTSHARE'
    value: toLower(functionAppName)
  }
  {
    name: 'AzureFunctionsWebHost__hostid'
    value: toLower(functionAppName)
  }
  {
    name: 'WEBSITE_USE_PLACEHOLDER_DOTNETISOLATED'
    value: 1
  }
  {
    name: 'FUNCTIONS_EXTENSION_VERSION'
    value: '~4'
  }
  {
    name: 'AZURE_FUNCTIONS_ENVIRONMENT'
    value: environmentType
  }
  {
    name: 'WEBSITE_ENABLE_SYNC_UPDATE_SITE'
    value: true
  }
  {
    name: 'WEBSITE_RUN_FROM_PACKAGE'
    value: '1'
  }
  {
    name: 'WEBSITE_NODE_DEFAULT_VERSION'
    value: '~14'
  }
  {
    name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
    value: appInsights.properties.ConnectionString
  }
  {
    name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
    value: appInsights.properties.InstrumentationKey
  }
  {
    name: 'FUNCTIONS_WORKER_RUNTIME'
    value: functionAppWokerRuntime
  }
]

var secureAppSettings = [
  for secureSettings in sensitiveSettings: empty(secureSettings)
    ? {}
    : {
        name: secureSettings.key
        value: secureSettings.value
      }
]

var functionAppSettings = concat(defaultAppsettings, secureAppSettings, extraFunctionAppSettings)

var baseSiteConfigLinux = {
  ftpsState: 'FtpsOnly'
  minTlsVersion: '1.2'
  linuxFxVersion: linuxFxVersion
  alwaysOn: true
  use32BitWorkerProcess: false
}

var baseSiteConfigWindows = {
  ftpsState: 'FtpsOnly'
  minTlsVersion: '1.2'
  netFrameworkVersion: netFrameworkVersion
}

var baseSiteConfig = usingDedicatedAppServicePlan ? baseSiteConfigLinux : baseSiteConfigWindows
var siteConfig = union(baseSiteConfig, { appSettings: functionAppSettings })

resource functionApp 'Microsoft.Web/sites@2021-03-01' = {
  name: functionAppName
  location: location
  kind: usingDedicatedAppServicePlan ? 'functionapp,linux' : 'functionapp'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    serverFarmId: usingDedicatedAppServicePlan ? dedicatedHostingPlan.id : defualtHostingPlan.id
    siteConfig: siteConfig
    httpsOnly: true
  }
}
@description('The principal ID of the function app.')
output funcPrincipalId string = functionApp.identity.principalId
@description('The outbound IP addresses of the function app.')
output funcOutboundIpAddresses string = functionApp.properties.outboundIpAddresses
@description('The possible outbound IP addresses of the function app.')
output funcPossibleOutboundIpAddresses string = functionApp.properties.possibleOutboundIpAddresses

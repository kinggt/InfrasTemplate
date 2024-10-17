@description('Required. Name of the site.')
param name string

@description('Optional. Location for all Resources.')
param location string = resourceGroup().location

@description('Required. Type of site to deploy.')
@allowed([
  'functionapp' // function app windows os
  'functionapp,linux' // function app linux os
  'functionapp,workflowapp' // logic app workflow
  'functionapp,workflowapp,linux' // logic app docker container
  'app,linux' // linux web app
  'app' // normal web app
])
param kind string = 'app,linux'

@description('Required. The resource ID of the app service plan to use for the site.')
param serverFarmResourceId string

@description('Optional. Azure Resource Manager ID of the Virtual network and subnet to be joined by Regional VNET Integration. This must be of the form /subscriptions/{subscriptionName}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/virtualNetworks/{vnetName}/subnets/{subnetName}.')
param virtualNetworkSubnetId string?

@description('Optional. If client affinity is enabled.')
param clientAffinityEnabled bool = true

@description('Required. The runtime stack and version for the web app. This setting defines the programming language and version that the app will run on. For example, "DOTNETCORE|6.0" indicates the app will run on .NET Core 6.0.')
param linuxFxVersion string = 'DOTNETCORE|8.0'

@description('Required. The name of the Application Insight.')
param appInsightName string

@description('required. The name of the Log Analytics workspace to configure the diagnostic logs.')
param logAnalyticsName string

@description('Required. The environment name for the web app. This setting defines the environment variables that the web app will run with.')
param aspnetCoreEnvironment string

@description('Optional. Additional App Settings.')
param extraAppsettings array = []

@description('Optional. The public network access setting for the web app. This setting defines whether the web app can be accessed from the internet. Possible values are "Enabled" or "Disabled".')
param publicNetworkAccess string = 'Enabled'

@description('Optional. This setting defines whether all outbound traffic is forced to be routed through the VNet. Possible values are "true" or "false".')
param vnetRouteAllEnabled bool = true

resource appInsights 'Microsoft.Insights/components@2020-02-02-preview' existing = {
  name: appInsightName
}

var basisAppsettings = [
  {
    name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
    value: appInsights.properties.InstrumentationKey
  }
  {
    name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
    value: appInsights.properties.ConnectionString
  }
  {
    name: 'ApplicationInsightsAgent_EXTENSION_VERSION'
    value: '~3'
  }
  {
    name: 'XDT_MicrosoftApplicationInsights_Mode'
    value: 'default'
  }
  {
    name: 'WEBSITE_RUN_FROM_PACKAGE'
    value: '1'
  }
  {
    name: 'ASPNETCORE_ENVIRONMENT'
    value: aspnetCoreEnvironment
  }
]

var appSettings = concat(basisAppsettings, extraAppsettings)

resource app 'Microsoft.Web/sites@2022-09-01' = {
  name: name
  location: location
  kind: kind
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    serverFarmId: serverFarmResourceId
    clientAffinityEnabled: clientAffinityEnabled
    httpsOnly: true
    virtualNetworkSubnetId: virtualNetworkSubnetId
    siteConfig: {
      ftpsState: 'Disabled'
      alwaysOn: true
      linuxFxVersion: linuxFxVersion
      ipSecurityRestrictionsDefaultAction: 'Allow'
      appSettings: appSettings
    }
    publicNetworkAccess: publicNetworkAccess
    vnetRouteAllEnabled: vnetRouteAllEnabled
  }
}

resource logAnalytics 'Microsoft.OperationalInsights/workspaces@2021-06-01' existing = {
  name: logAnalyticsName
}

resource diagnosticLogs 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'appServiceDiagnosticlog'
  scope: app
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
    ]
    metrics: [
      {
        category: 'AllMetrics'
        enabled: false
        retentionPolicy: {
          days: 0
          enabled: false
        }
      }
    ]
  }
}

@description('The principalId ID of the App Service.')
output appServicePrincipalId string = app.identity.principalId

@description('The resource ID of the App Service.')
output appServiceId string = app.id

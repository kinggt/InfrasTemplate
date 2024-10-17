@description('The environment for the resources. Accepted values are defined to ensure consistency.')
@allowed([
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

@description('the service principal id of the azure service connection , aim to access key vault')
param azureServiceConnectionServicePrincipalId string

module names '../modules/namingConvention.bicep' = {
  name: 'namingconvention'
  params: {
    environmentType: environmentType
    serviceName: serviceName
    locationShortSuffix: locationShortSuffix
  }
}

module logAnalyticsWorkSpace '../modules/loganalyticsworkspace.bicep' = {
  name: 'logAnalyticsWorkSpace'
  params: {
    name: names.outputs.logAnalyticsWorkspaceName
  }
}

module applicationInsights '../modules/applicationInsight.bicep' = {
  name: 'applicationInsights'
  params: {
    name: names.outputs.applicationInsightName
    workspaceResourceId: logAnalyticsWorkSpace.outputs.resourceId
  }
}

module appServicePlan '../modules/appserviceplan.bicep' = {
  name: 'appServicePlan'
  params: {
    name: names.outputs.appServicePlanName
  }
}

resource SpokeMiddleSubnet 'Microsoft.Network/virtualNetworks/subnets@2022-05-01' existing = {
  name: 'Spoke-VNet/MiddleTier'
  scope: resourceGroup('GSSIT-VerITNetwork-RG-WE')
}

module appService '../modules/appservice.bicep' = {
  name: 'appService'
  dependsOn: [
    applicationInsights
    appServicePlan
  ]
  params: {
    name: names.outputs.appServiceName
    aspnetCoreEnvironment: names.outputs.aspnetCoreEnvironment
    serverFarmResourceId: appServicePlan.outputs.resourceId
    virtualNetworkSubnetId: SpokeMiddleSubnet.id
    appInsightName: names.outputs.applicationInsightName
    logAnalyticsName: names.outputs.logAnalyticsWorkspaceName
    publicNetworkAccess: 'Disabled'
    vnetRouteAllEnabled: false
    extraAppsettings: [
      {
        name: 'WEBSITE_DNS_ALT_SERVER'
        value: '168.63.129.16'
      }
    ]
  }
}

resource SpokeFrontSubnet 'Microsoft.Network/virtualNetworks/subnets@2022-05-01' existing = {
  name: 'Spoke-VNet/FrontTier'
  scope: resourceGroup('GSSIT-VerITNetwork-RG-WE')
}

module appServicePrivateEndpoint '../modules/privateendpoint.bicep' = {
  name: 'appServicePrivateEndpoint'
  params: {
    name: '${names.outputs.privateEndpointName}-spoke-as'
    subnetId: SpokeFrontSubnet.id
    privateLinkServiceId: appService.outputs.appServiceId
    groupId: 'sites'
  }
}

module keyVault '../modules/keyvault.bicep' = {
  name: 'keyVault'
  params: {
    name: names.outputs.keyVaultName
    identityObjectIds: [appService.outputs.appServicePrincipalId, azureServiceConnectionServicePrincipalId]
    logAnalyticsName: names.outputs.logAnalyticsWorkspaceName
  }
}

resource SpokeBackSubnet 'Microsoft.Network/virtualNetworks/subnets@2022-05-01' existing = {
  name: 'Spoke-VNet/BackTier'
  scope: resourceGroup('GSSIT-VerITNetwork-RG-WE')
}

module keyVaultPrivateEndpoint '../modules/privateendpoint.bicep' = {
  name: 'keyVaultPrivateEndpoint'
  params: {
    name: '${names.outputs.privateEndpointName}-spoke-kv'
    subnetId: SpokeBackSubnet.id
    privateLinkServiceId: keyVault.outputs.resourceId
    groupId: 'vault'
  }
}

module storageAccount '../modules/storageaccout.bicep' = {
  name: 'storageAccount'
  dependsOn: [keyVault]
  params: {
    name: names.outputs.storageAccountName
    containers: ['test']
    keyVaultName: names.outputs.keyVaultName
    allowSharedKeyAccess: false
  }
}

module storageAccountPrivateEndpoint '../modules/privateendpoint.bicep' = {
  name: 'storageAccountPrivateEndpoint'
  params: {
    name: '${names.outputs.privateEndpointName}-spoke-sa'
    subnetId: SpokeBackSubnet.id
    privateLinkServiceId: storageAccount.outputs.storageAccountId
    groupId: 'blob'
  }
}

module virtualMachineScaleSet '../modules/virturalmachinescalesets.bicep' = {
  name: 'virtualMachineScaleSet'
  params: {
    sku: {
      name: 'Standard_B1s'
      tier: 'Standard'
      capacity: 1
    }
    vmAdminUsername: 'commonTemplateVmScaleSet'
    vmAdminPassword: 'commonTemplateVmScaleSetPWD~！'
    virtualMachineScaleSetName: names.outputs.virtualMachineScaleSetName
    computerNamePrefix: '${environmentType}vmset'
    networkSecurityGroupName: names.outputs.agentNetworkSecurityGroupName
    subnetId: SpokeBackSubnet.id
    networkInterfaceConfName: 'nic01'
  }
}

// resource existingStorageAccount 'Microsoft.Storage/storageAccounts@2022-09-01' existing = {
//   name: names.outputs.storageAccountName
// }

// var storageAccountKey = '${listKeys(existingStorageAccount.id, existingStorageAccount.apiVersion).keys[0].value}'
// var connectionString = 'DefaultEndpointsProtocol=https;AccountName=${existingStorageAccount.name};AccountKey=${storageAccountKey};EndpointSuffix=${environment().suffixes.storage};'

// module functionAppUsingDefaultPlan '../modules/functionapp.bicep' = {
//   name: 'functionAppUsingDefaultPlan'
//   params: {
//     functionAppName: names.outputs.functionAppName
//     environmentType: environmentType
//     funcStorageAccountName: names.outputs.storageAccountName
//     appInsightName: names.outputs.applicationInsightName
//     sensitiveSettingsObject: {
//       settings: [
//         {
//           key: 'StorageAccount_ConnectionString'
//           value: connectionString
//         }
//       ]
//     }
//   }
// }

// module functionAppUsingDedicatedPlan '../modules/functionapp.bicep' = {
//   name: 'functionAppUsingDedicatedPlan'
//   params: {
//     functionAppName: names.outputs.functionAppName
//     environmentType: environmentType
//     funcStorageAccountName: names.outputs.storageAccountName
//     appInsightName: names.outputs.applicationInsightName
//     dedicatedAppServicePlanName: names.outputs.functionAppServicePlanName
//     dedicatedAppServicePlanSku: {
//       name: 'B1'
//       tier: 'Basic'
//       size: 'B1'
//       family: 'B'
//       capacity: 1
//     }
//     sensitiveSettingsObject: {
//       settings: [
//         {
//           key: 'StorageAccount_ConnectionString'
//           value: connectionString
//         }
//       ]
//     }
//   }
// }

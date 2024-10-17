@description('required. The name of the function app.')
param functionAppName string

resource functionApp 'Microsoft.Web/sites@2021-03-01' existing = {
  name: functionAppName
}

resource functionAppSettings 'Microsoft.Web/sites/config@2021-03-01' = {
  name: 'appsettings'
  kind: 'string'
  parent: functionApp
  properties: {}
}

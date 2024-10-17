@description('Optional. Location for all Resources.')
param location string = resourceGroup().location
@description('Required. SKU for the Virtual Machine Scale Set.')
param sku object
@description('Required. Name of the Virtual Machine Scale Set.')
param virtualMachineScaleSetName string
@description('Required. Prefix for the computer name of the Virtual Machine Scale Set.')
param computerNamePrefix string
@description('Required. Name of the Network Security Group.')
param networkSecurityGroupName string
@description('Required. Resource ID of the Subnet.')
param subnetId string
@description('Required. Name of the Network Interface Configuration.')
param networkInterfaceConfName string
@description('Required. Admin username for the Virtual Machine Scale Set.')
@secure()
param vmAdminUsername string
@description('Required. Admin password for the Virtual Machine Scale Set.')
@secure()
param vmAdminPassword string

resource securityGroup 'Microsoft.Network/networkSecurityGroups@2020-11-01' = {
  name: networkSecurityGroupName
  location: location
  properties: {
    securityRules: []
  }
}

resource virtualMachineScaleSets 'Microsoft.Compute/virtualMachineScaleSets@2022-11-01' = {
  name: virtualMachineScaleSetName
  location: location
  sku: sku
  properties: {
    singlePlacementGroup: false
    orchestrationMode: 'Uniform'
    overprovision: false
    doNotRunExtensionsOnOverprovisionedVMs: false
    platformFaultDomainCount: 1
    upgradePolicy: {
      mode: 'Manual'
    }
    scaleInPolicy: {
      rules: [
        'Default'
      ]
      forceDeletion: false
    }
    virtualMachineProfile: {
      osProfile: {
        adminUsername: vmAdminUsername
        adminPassword: vmAdminPassword
        computerNamePrefix: computerNamePrefix
        linuxConfiguration: {
          disablePasswordAuthentication: false
          provisionVMAgent: true
          enableVMAgentPlatformUpdates: false
        }
        secrets: []
        allowExtensionOperations: true
      }
      securityProfile: {
        encryptionAtHost: true
      }
      storageProfile: {
        osDisk: {
          osType: 'Linux'
          createOption: 'FromImage'
          caching: 'ReadWrite'
          managedDisk: {
            storageAccountType: 'StandardSSD_LRS'
          }
          diskSizeGB: 30
        }
        imageReference: {
          publisher: 'canonical'
          offer: '0001-com-ubuntu-server-jammy'
          sku: '22_04-lts-gen2'
          version: 'latest'
        }
        diskControllerType: 'SCSI'
      }
      networkProfile: {
        networkInterfaceConfigurations: [
          {
            name: networkInterfaceConfName
            properties: {
              primary: true
              enableAcceleratedNetworking: false
              disableTcpStateTracking: false
              networkSecurityGroup: {
                id: securityGroup.id
              }
              dnsSettings: {
                dnsServers: []
              }
              enableIPForwarding: false
              ipConfigurations: [
                {
                  name: '${networkInterfaceConfName}-defaultIpConfiguration'
                  properties: {
                    primary: true
                    subnet: {
                      id: subnetId
                    }
                    privateIPAddressVersion: 'IPv4'
                  }
                }
              ]
            }
          }
        ]
      }
      diagnosticsProfile: {
        bootDiagnostics: {
          enabled: true
        }
      }
    }
  }
}

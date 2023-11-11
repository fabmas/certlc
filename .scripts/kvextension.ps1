#Articolidi riferimento 
# (per Windows): https://learn.microsoft.com/en-us/azure/virtual-machines/extensions/key-vault-windows
# (per Linux):https://learn.microsoft.com/en-us/azure/virtual-machines/extensions/key-vault-linux
# (per ARC): https://techcommunity.microsoft.com/t5/azure-arc-blog/in-preview-azure-key-vault-extension-for-arc-enabled-servers/ba-p/1888739

#Salvare il certificato (e non il secret) all'interno di "Certificate" nel keyvault
#Seegnare all'identity delle VM o al service principal della ARCMachine i ruoli di "Key Vault Secrets User" sul keyVault

Connect-AzAccount -TenantId 16b3c013-d300-468d-ac64-7eda0820b6d3 -Subscription fabmas-azure
Connect-AzAccount -TenantId 1912158f-712f-400e-819d-8498b1ad6f85 -Subscription ME-MngEnv999102-angelom-1
Connect-AzAccount -TenantID 5d64871e-f8ee-48b9-8653-6ac7999b3967 -Subscription vs-famasci

#Prendere il SecretID SENZA LA VERSIONE a partire dal certificato all'interno del keyvault
Get-AzKeyVaultCertificate -VaultName "fabmas-DEMO-KV-02" -name democert | select SecretID

#Nel file Json per la configurazione dell'extension specificare il SecretID (es:https://pv-kv01.vault.azure.net:443/secrets/prova-PFX)


# Build settings on Windows VM
$settings = (get-content -raw ".\kvextensionwin.json")
$extName = "KeyVaultForWindows"
$extPublisher = "Microsoft.Azure.KeyVault"
$extType = "KeyVaultForWindows"
 
# Start the deployment on Windows VM
Set-AzVmExtension -TypeHandlerVersion "3.0" -ResourceGroupName "certlc" -Location "italynorth" -VMName "ca01" -Name $extName -Publisher $extPublisher -Type $extType -SettingString $settings

##############################

# Build settings on Linux VM
$settings = (get-content -raw ".\kvextensionlinux.json")
$extName = "KeyVaultForLinux"
$extPublisher = "Microsoft.Azure.KeyVault"
$extType = "KeyVaultForLinux"

# Start the deployment on Linux VM
Set-AzVmExtension -TypeHandlerVersion "2.0" -EnableAutomaticUpgrade $true -ResourceGroupName "PosteVITA" -Location "westeurope" -VMName "ubutu01" -Name $extName -Publisher $extPublisher -Type $extType -SettingString $settings

##############################
# Build settings on Windows ARC Server
$settings = (get-content -raw ".\kvextensionARCWin.json")
$extName = "KeyVaultForWindows"
$extPublisher = "Microsoft.Azure.KeyVault"
$extType = "KeyVaultForWindows"
 
# Start the deployment on Windows ARC Server
New-AzConnectedMachineExtension -ResourceGroupName "PosteVITA" -MachineName "ADFSSRV" -Name "KeyVaultForWindows" -Location "westeurope" -Publisher "Microsoft.Azure.KeyVault" -ExtensionType "KeyVaultForWindows" -Setting $Settings


################################

# Build settings on Linux ARC Server
# $settings = (get-content -raw ".\ARCLinux.json")
$Settings = @{
    secretsManagementSettings = @{
        observedCertificates = @(
            "https://kv-testpv.vault.azure.net:443/secrets/certificate2"
            # Add more here, don't forget a comma on the preceding line
        )
        # The cert store location is optional, the default path is shown below
        # certificateStoreLocation = "/var/lib/waagent/Microsoft.Azure.KeyVault.Store/"
        pollingIntervalInS   = "60" 
    }
    authenticationSettings    = @{
        msiEndpoint = "http://localhost:40342/metadata/identity"
    }
}

$extName = "KeyVaultForLinux"
$extPublisher = "Microsoft.Azure.KeyVault"
$extType = "KeyVaultForLinux"

# Start the deployment on Linux ARC Server
New-AzConnectedMachineExtension -ResourceGroupName "pvtest"-MachineName "angelo-VM" -Name "KeyVaultForLinux" -Location "italynorth" -Publisher "Microsoft.Azure.KeyVault" -ExtensionType "KeyVaultForLinux" -Setting $Settings








################################
#Test webhook
$body = '[
    {
      "id": "df4de7ec-6291-4e34-a430-42e0a7384c01",
      "topic": "/subscriptions/0f3f9511-aa31-4981-a283-f6bb651546d7/resourceGroups/CERTLC/providers/Microsoft.KeyVault/vaults/fabmas-DEMO-KV-07",
      "subject": "democert",
      "eventType": "Microsoft.KeyVault.CertificateNearExpiry",
      "data": {
        "Id": "https://fabmas-demo-kv-07.vault.azure.net/certificates/democert/e0765abf606b4429b99a3b0ede90b3ef",
        "VaultName": "fabmas-DEMO-KV-07",
        "ObjectType": "Certificate",
        "ObjectName": "democert",
        "Version": "e0765abf606b4429b99a3b0ede90b3ef",
        "NBF": 1699656798,
        "EXP": 1700088798
      },
      "dataVersion": "1",
      "metadataVersion": "1",
      "eventTime": "2023-11-10T23:07:16.4775919Z"
    }
  ]'

$Headers = New-Object 'System.Collections.Generic.Dictionary[[String],[String]]'
$Headers.Add('aeg-subscription-name', 'SECURE-WEBHOOK') 
$Headers.Add('aeg-delivery-count', '0')
$Headers.Add('aeg-data-version', '1')
$Headers.Add('aeg-metadata-version', '0')
$Headers.Add('aeg-event-type', 'Notification')
#$Headers.Add('Authorization', 'Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiIsIng1dCI6IjlHbW55RlBraGMzaE91UjIybXZTdmduTG83WSIsImtpZCI6IjlHbW55RlBraGMzaE91UjIybXZTdmduTG83WSJ9.eyJhdWQiOiI0ZDU3ZmI2Yi03NWZmLTRlNzUtYjJmMS1iNzc4ODY4NWYzODMiLCJpc3MiOiJodHRwczovL3N0cy53aW5kb3dzLm5ldC8xOTEyMTU4Zi03MTJmLTQwMGUtODE5ZC04NDk4YjFhZDZmODUvIiwiaWF0IjoxNjk4MDc4OTg1LCJuYmYiOjE2OTgwNzg5ODUsImV4cCI6MTY5ODE2NTY4NSwiYWlvIjoiRTJGZ1lNaTYrN1V2MjlVaG16WHhkYUpWZ2MwSkFBPT0iLCJhcHBpZCI6IjQ5NjI3NzNiLTljZGItNDRjZi1hOGJmLTIzNzg0NmEwMGFiNyIsImFwcGlkYWNyIjoiMiIsImlkcCI6Imh0dHBzOi8vc3RzLndpbmRvd3MubmV0LzE5MTIxNThmLTcxMmYtNDAwZS04MTlkLTg0OThiMWFkNmY4NS8iLCJvaWQiOiJkZjI0N2E5YS1mNjRmLTQzMWEtODczZi1mZmIzNjMzOGI2ODMiLCJyaCI6IjAuQUgwQWp4VVNHUzl4RGtDQm5ZU1lzYTF2aFd2N1YwM19kWFZPc3ZHM2VJYUY4NE9jQUFBLiIsInN1YiI6ImRmMjQ3YTlhLWY2NGYtNDMxYS04NzNmLWZmYjM2MzM4YjY4MyIsInRpZCI6IjE5MTIxNThmLTcxMmYtNDAwZS04MTlkLTg0OThiMWFkNmY4NSIsInV0aSI6IlM5Vk1iQ29PNzBHTUxZdE1la1diQVEiLCJ2ZXIiOiIxLjAifQ.bSZxCU2lHtgVslV6aQl0JRsJdo_yRdHSSL60pGoIExiNhRuRNkUHOCOSYJRDQmWyerkeb7TMfFkmSDY54tDnDYHOymo0W4sYsmDZpGalXyvi7d3JOHEMTHuAAH1ENpQBIadQc87YDNxg8w_N4a3IUv1sZJrp-vxwUoBcdHn3N6hsGcDlSgjLKNVmAfxTUOnBwxZz-m6-aiEKeW5eL1SPsDzcVYw3rbM48FEJ1QDrttHlK9zD_wcCZYRURtHYF-3H8gr0A_MbS7TtXF5KSkuLPfmgwEIUC81ITchv5MShpfK0xh0jANNbIu7c5CTT9jNKqo6BybqIpC9G2VBAnjlgTQ')
#$Headers.Add('Host', '5e314d7b-cfce-415f-aaca-73cf2a963b8c.webhook.we.azure-automation.net')
$Headers.Add('x-ms-request-id', '1cce86be-f112-436b-beee-ae9a051b3116')


#angelom
$webhookURI = "https://1af729e4-f610-4e9a-abe5-a8e623eafc95.webhook.we.azure-automation.net/webhooks?token=KZZ6W2YIbytll07%2fpaJMMkGLmZ1OiABVL4rQo2yns78%3d"

#fabmas
$webhookURI = "https://1af729e4-f610-4e9a-abe5-a8e623eafc95.webhook.we.azure-automation.net/webhooks?token=KZZ6W2YIbytll07%2fpaJMMkGLmZ1OiABVL4rQo2yns78%3d"


$response = Invoke-WebRequest -Method Post -Uri $webhookURI -Headers $Headers -Body $body -UseBasicParsing
$response

################################
# COPIA SNAPSHOTS SU Storage Account IN ALTRA SOTTOSCRIZIONE
azcopy copy "https://md-nv2vhkz3glvq.z1.blob.storage.azure.net/fnml0nf1v4ql/abcd?sv=2018-03-28&sr=b&si=b6eb74ba-13b6-45fa-a56d-b7536320c651&sig=S46gmGTVtACsVYKcVjgai9o%2BD85JRCxAKHS0VsrewW0%3D" "https://famascitmp.blob.core.windows.net/snapshots/pv-osdisk1.vhd?sp=racwdl&st=2023-10-23T06:26:46Z&se=2023-10-23T14:26:46Z&spr=https&sv=2022-11-02&sr=c&sig=CNf1Z6KkzEbQ2x8GZ6swDwBQUcciR3KJDPymoGPGYzI%3D"

#CREAZIONE DISCHI
# Provide the subscription Id where the VHD is stored
$subscriptionId = "0f3f9511-aa31-4981-a283-f6bb651546d7"
# Set the context to the subscription Id where VHD is stored
az account set --subscription $subscriptionId


# Provide the URL of the VHD in the storage account
$vhdUrl = "https://famascitmp.blob.core.windows.net/snapshots/pv-os.vhd"

# Provide the location (i.e., Azure region)
$location = "westeurope"

# Provide the name of the OS disk
$osDiskName = "pv-DC01-OS"


# Create OS disk from the VHD
az disk create --resource-group $resourceGroupName --name $osDiskName --source $vhdUrl --location $location --os-type Windows --hyper-v-generation V2

#Create Data Disk
az disk create --resource-group $resourceGroupName --name $diskName --source  $vhdUrl --sku Standard_LRS





##########
Set-AzVMExtension -ResourceGroupName "Poste-Vita" -VMName "pv-dc01" -Location "westeurope" -Publisher "Microsoft.Azure.Security.MDE" -ExtensionType "MDE.Windows" -TypeHandlerVersion "1.0" -Name "DefenderForEndpoint"




$temp = "Template=1.3.6.1.4.1.311.21.8.13172761.5506148.3097506.3378869.1791674.67.38881081.92656882, Major Version Number=100, Minor Version Number=3"
write-output "temp = $temp"
$oid=$null
$substring = $temp -match '\((.*?)\)' | Out-Null
if ($matches -ne $null -and $matches.Count -gt 0) {
    $oid = $matches[1]
    write-output "OID1 = $oid"
} 

if ($oid -eq $null) {
    $split = $temp -split ","
    $template = $split[0]
    $templateSplit = $template -split "="
    $oid = $templateSplit[1]
    write-output "OID2 = $oid"
}

if ($oid -eq $null) {
    $pattern = 'Template=([\d.]+)'
    if ($temp -match $pattern) {
        $oid = $matches[1]
        write-output "OID3 = $oid"
    } 
}
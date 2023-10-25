# Azure CA Lifecycle Management

## Deployment DEMO environment

[![Deploy To Azure](https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/1-CONTRIBUTION-GUIDE/images/deploytoazure.svg?sanitize=true)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2Fazure-quickstart-templates%2Fmaster%2Fmodules%2Factive-directory-new-domain%2F0.9%2Fazuredeploy.json)


## Articoli di riferimento:
1. (per Windows): https://learn.microsoft.com/en-us/azure/virtual-machines/extensions/key-vault-windows
1. (per Linux):https://learn.microsoft.com/en-us/azure/virtual-machines/extensions/key-vault-linux
1. (per ARC): https://techcommunity.microsoft.com/t5/azure-arc-blog/in-preview-azure-key-vault-extension-for-arc-enabled-servers/ba-p/1888739
1. configure token lifetime : https://learn.microsoft.com/it-it/entra/identity-platform/configure-token-lifetimes

## Note
- Salvare il certificato (e non il secret) all'interno di "Certificate" nel keyvault
- il file **kvextension.ps1** contiene gli esempi per il push dell'extension per Win/Linux ARCWin/ARCLinux
- il file **kvextension.ps1** contiene un esempio per il test veloce del webhook con un JSON di input (per il cert pippo)
- Assegnare all'identity delle VM o al service principal della ARCMachine i ruoli di "Key Vault Secrets User" sul keyVault
- Prendere il SecretID *SENZA LA VERSIONE* a partire dal certificato all'interno del keyvault
Get-AzKeyVaultCertificate -VaultName pv-kv01 -name prova-pfx | select SecretID
- Nel file Json per la configurazione dell'extension specificare il SecretID (es:https://pv-kv01.vault.azure.net:443/secrets/prova-PFX)
- Configurare il WebHook per girare con l'Hybrid Worker
- Configurare Az.Accounts con versione 2.12.1 (2.13 non funziona) Install-Module Az.Accounts -requiredVersion 2.12.1
- seguire gli step per la comunicazione autenticata tra eventgrid e webhook indicata qui: https://learn.microsoft.com/en-us/azure/event-grid/secure-webhook-delivery#configure-the-event-subscription-by-using-a-microsoft-entra-application

## Web Hook:
(fabmas-Azure) https://791d2196-d4f8-4191-bda4-2423f9c0dd9a.webhook.we.azure-automation.net/webhooks?token=mUAIvhMaIIR76kIXs4TxhEmn47Z4l58M0snbW8BmCIA%3d

(angelom) https://5e314d7b-cfce-415f-aaca-73cf2a963b8c.webhook.we.azure-automation.net/webhooks?token=ao7%2bS7P7Wp2vLuEktvwuH5nYhMQRHluVPB%2foeGXi73o%3d

vedi esempio per lanciare il webhook da powershell in **kvextension.ps1**

## Secrets
|description|secret|
|---|---|
|Eventgridwriter-secret|J9d8Q~XET2VoVuNRv1OIP573qYrEjSzX.IF6Rc_p|
|Webhook-secret|ZR_8Q~jgdNqeZ6IzuD3dIfJlclBgyxpmTgbYzaAs|


## Permessi sul KeyVault per la sicurezza
- Identità dell'automation account deve essere Keyvault Certificate Officer su tutto il KeyVault (KV dedicato solo a certificatelifecycle)
- La managed Identity del Server su cui installare l'extension per il rinnovo del cert deve essere Keyvault Secret User sul SINGOLO CERTIFICATO
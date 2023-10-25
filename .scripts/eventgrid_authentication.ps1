# NOTE: Before run this script ensure you are logged in Azure by using "az login" command.

$webhookAppObjectId = "3e9691a5-d778-4134-8dbe-d7d3c53c8292"
$eventSubscriptionWriterAppId = "fb856d75-db5f-4dc0-83dd-59b2681c38d2"

# Start execution
try {

    # Creates an application role of given name and description

    Function CreateAppRole([string] $Name, [string] $Description)
    {
        $appRole = New-Object Microsoft.Open.AzureAD.Model.AppRole
        $appRole.AllowedMemberTypes = New-Object System.Collections.Generic.List[string]
        $appRole.AllowedMemberTypes.Add("Application");
        $appRole.AllowedMemberTypes.Add("User");
        $appRole.DisplayName = $Name
        $appRole.Id = New-Guid
        $appRole.IsEnabled = $true
        $appRole.Description = $Description
        $appRole.Value = $Name;

        return $appRole
    }

    # Creates Azure Event Grid Azure AD Application if not exists
    # You don't need to modify this id
    # But Azure Event Grid Azure AD Application Id is different for different clouds

    $eventGridAppId = "4962773b-9cdb-44cf-a8bf-237846a00ab7" # Azure Public Cloud
    # $eventGridAppId = "54316b56-3481-47f9-8f30-0300f5542a7b" # Azure Government Cloud
    $eventGridRoleName = "AzureEventGridSecureWebhookSubscriber" # You don't need to modify this role name
    $eventGridSP = Get-AzADServicePrincipal -Filter ("appId eq '" + $eventGridAppId + "'")
    if ($eventGridSP -match "Microsoft.EventGrid")
    {
        Write-Host "The Azure AD Application is already defined.`n"
    } else {
        Write-Host "Creating the Azure Event Grid Azure AD Application"c
        $eventGridSP = New-AzADServicePrincipal -AppId $eventGridAppId
    }

    # Creates the Azure app role for the webhook Azure AD application

    $app = Get-AzADApplication -ObjectId $webhookAppObjectId
    $appRoles = $app.AppRoles

    Write-Host "Azure AD App roles before addition of the new role..."
    Write-Host $appRoles
    
    if ($appRoles -match $eventGridRoleName)
    {
        Write-Host "The Azure Event Grid role is already defined.`n"
    } else {      
        Write-Host "Creating the Azure Event Grid role in Azure AD Application: " $webhookAppObjectId
        $newRole = CreateAppRole -Name $eventGridRoleName -Description "Azure Event Grid Role"
        $appRoles.Add($newRole)
        Set-AzADApplication -ObjectId $app.ObjectId -AppRoles $appRoles
    }

    Write-Host "Azure AD App roles after addition of the new role..."
    Write-Host $appRoles

    # Creates the user role assignment for the app that will create event subscription

    $servicePrincipal = Get-AzADServicePrincipal -Filter ("appId eq '" + $app.AppId + "'")
    $eventSubscriptionWriterSP = Get-AzADServicePrincipal -Filter ("appId eq '" + $eventSubscriptionWriterAppId + "'")

    if ($null -eq $eventSubscriptionWriterSP)
    {
        Write-Host "Create new Azure AD Application"
        $eventSubscriptionWriterSP = New-AzADServicePrincipal -AppId $eventSubscriptionWriterAppId
    }

    try
    {
        Write-Host "Creating the Azure AD Application role assignment: " $eventSubscriptionWriterAppId
        $eventGridAppRole = $app.AppRoles | Where-Object -Property "DisplayName" -eq -Value $eventGridRoleName
        New-AzADServiceAppRoleAssignment -Id $eventGridAppRole.Id -ResourceId $servicePrincipal.ObjectId -ObjectId $eventSubscriptionWriterSP.ObjectId -PrincipalId $eventSubscriptionWriterSP.ObjectId
    }
    catch
    {
        if( $_.Exception.Message -like '*Permission being assigned already exists on the object*')
        {
            Write-Host "The Azure AD Application role is already defined.`n"
        }
        else
        {
            Write-Error $_.Exception.Message
        }
        Break
    }

    # Creates the service app role assignment for Event Grid Azure AD Application

    $eventGridAppRole = $app.AppRoles | Where-Object -Property "DisplayName" -eq -Value $eventGridRoleName
    New-AzADServiceAppRoleAssignment -Id $eventGridAppRole.Id -ResourceId $servicePrincipal.ObjectId -ObjectId $eventGridSP.ObjectId -PrincipalId $eventGridSP.ObjectId
    
    # Print output references for backup

    Write-Host ">> Webhook's Azure AD Application Id: $($app.AppId)"
    Write-Host ">> Webhook's Azure AD Application ObjectId Id: $($app.ObjectId)"
}
catch {
  Write-Host ">> Exception:"
  Write-Host $_
  Write-Host ">> StackTrace:"  
  Write-Host $_.ScriptStackTrace
}
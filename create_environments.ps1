#TODO: Add parameter for user name list as well.
param ($Password, $Tenant)

#if (-not(Get-Module -Name Microsoft.PowerApps.Administration.PowerShell) -or
#     -not(Get-Module -Name Microsoft.PowerApps.PowerShell) -or
#     -not(Get-Module -Name AzureAD))
#{
#    Write-Host "Importing PowerApp Admin Modules..."
#    Install-Module -Name Microsoft.PowerApps.Administration.PowerShell -Force -AllowClobber
#    Install-Module -Name Microsoft.PowerApps.PowerShell -Force -AllowClobber
#    Install-Module -Name AzureAD -Force -AllowClobber
#}

$users = Import-Csv -Path .\users.csv

#$credential = Get-Credential
#Connect-AzureAD -Credential $credential


$licenses = New-Object -TypeName Microsoft.Open.AzureAD.Model.AssignedLicenses
$licenses.AddLicenses = @{}

$elicense = New-Object -TypeName Microsoft.Open.AzureAD.Model.AssignedLicense
$elicense.SkuId = (Get-AzureADSubscribedSku | Where-Object -Property SkuPartNumber -Value "ENTERPRISEPREMIUM" -EQ).SkuID
$licenses.AddLicenses.Add($elicense)

$flowlicense = New-Object -TypeName Microsoft.Open.AzureAD.Model.AssignedLicense
$flowlicense.SkuId = (Get-AzureADSubscribedSku | Where-Object -Property SkuPartNumber -Value "FLOW_PER_USER" -EQ).SkuID
$licenses.AddLicenses.Add($flowlicense)

$palicense = New-Object -TypeName Microsoft.Open.AzureAD.Model.AssignedLicense
$palicense.SkuId = (Get-AzureADSubscribedSku | Where-Object -Property SkuPartNumber -Value "POWERAPPS_PER_USER" -EQ).SkuID
$licenses.AddLicenses.Add($palicense)


$passwordProfile = New-Object -TypeName Microsoft.Open.AzureAD.Model.PasswordProfile
$passwordProfile.Password = $Password

foreach($user in $users)
{
    $displayname = $user.First + $user.Last[0]
    $upn = $displayname + "@" + $Tenant + ".onmicrosoft.com"

    #New-AzureADUser -UserPrincipalName $upn -DisplayName $displayname -AccountEnabled $true -PasswordProfile $passwordProfile -PasswordPolicies "DisablePasswordExpiration" -MailNickName $displayname -UsageLocation "US"

    $newPassword = ConvertTo-SecureString $Password -AsPlainText -Force
    #Set-AzureADUserPassword -ObjectId $upn -Password $newPassword -ForceChangePasswordNextLogin $false

    #Set-AzureADUserLicense -ObjectId $upn -AssignedLicenses $licenses

    # Create a Power Apps Environment for each user.
    $envName = $displayname + "-devenv"
    $logon = Add-PowerAppsAccount -Username $upn -Password $newPassword
    New-AdminPowerAppEnvironment -DisplayName $envName -EnvironmentSku Trial -LocationName unitedstates -CurrencyName USD -ProvisionDatabase -LanguageName 1033

    Write-Host "Created user and environment for " + $displayname
}

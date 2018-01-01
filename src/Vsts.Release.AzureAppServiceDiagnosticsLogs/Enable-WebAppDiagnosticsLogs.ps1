Trace-VstsEnteringInvocation $MyInvocation
Import-VstsLocStrings "$PSScriptRoot\task.json"

try {

	$StorageAccountName = Get-VstsInput -Name StorageAccountRM -Require
	$ResourceGroupName = Get-VstsInput -Name ResourceGroupName -Require
	$WebAppName = Get-VstsInput -Name WebAppName -Require
	$ApplicationLogsLogLevel = Get-VstsInput -Name ApplicationLogsLogLevel -Default 'Information'
	[int]$ApplicationLogsRetentionDays = Get-VstsInput -Name ApplicationLogsRetentionDays -Default '14' -AsInt
	$HttpLogsLogLevel = Get-VstsInput -Name HttpLogsLogLevel -Default 'Information'
	[int]$HttpLogsRetentionDays = Get-VstsInput -Name HttpLogsRetentionDays -Default '14' -AsInt

	# Initialize Azure.
    Import-Module $PSScriptRoot\ps_modules\VstsAzureHelpers_
    Initialize-Azure

	Write-Host "##[command](Get-AzureRmStorageAccount | Where-Object{$_.StorageAccountName -eq $StorageAccountName})"
	$StorageAccount = (Get-AzureRmStorageAccount | Where-Object{$_.StorageAccountName -eq $StorageAccountName})
	$StorageAccountContext = $StorageAccount.Context
	$storageResourceGroup = $StorageAccount.ResourceGroupName

	Write-Host "##[command]New-AzureStorageContainer -Context $StorageAccountContext -Name 'webapp-logs'  -ErrorAction Ignore"
	New-AzureStorageContainer -Context $StorageAccountContext -Name "webapp-logs" -ErrorAction Ignore

	Write-Host "##[command]New-AzureStorageContainerSASToken -Context $StorageAccountContext -Name 'webapp-logs' -FullUri -Permission rwdl StartTime (Get-Date).Date -ExpiryTime (Get-Date).Date.AddYears(1)"
	$webSASToken = New-AzureStorageContainerSASToken -Context $StorageAccountContext -Name "webapp-logs" -FullUri -Permission rwdl -StartTime (Get-Date).Date -ExpiryTime (Get-Date).Date.AddYears(1)

	Write-Host "##[command]New-AzureStorageContainer -Context $StorageAccountContext -Name 'http-logs' -ErrorAction Ignore"
    New-AzureStorageContainer -Context $StorageAccountContext -Name "http-logs" -ErrorAction Ignore

	Write-Host "##[command]New-AzureStorageContainerSASToken -Context $StorageAccountContext -Name 'http-logs' -FullUri -Permission rwdl -StartTime (Get-Date).Date -ExpiryTime (Get-Date).Date.AddYears(1) "
    $httpSASToken = New-AzureStorageContainerSASToken -Context $StorageAccountContext -Name "http-logs" -FullUri -Permission rwdl -StartTime (Get-Date).Date -ExpiryTime (Get-Date).Date.AddYears(1) 

	Write-Host "##[command](Get-AzureRmResource).Where( {$_.ResourceType -eq 'Microsoft.Web/sites' -and $_.ResourceGroupName -eq $StorageAccount.ResourceGroupName})"
	$resources = (Get-AzureRmResource).Where( {$_.ResourceType -eq "Microsoft.Web/sites" -and $_.ResourceGroupName -eq $storageResourceGroup})

	$webApp = Get-AzureRmWebApp -ResourceGroupName $ResourceGroupName -Name $WebAppName

	Write-Host "Setting diagnostic log configuration for $WebAppName"

	$propertiesObject = [ordered] @{
				'applicationLogs' = @{
					'azureBlobStorage' = @{
						'level'           = $ApplicationLogsLogLevel
						'sasUrl'          = [string]$webSASToken
						'retentionInDays' = $ApplicationLogsRetentionDays
					}
				}
				'httpLogs'        = @{
					'azureBlobStorage' = @{
						'level'           = $HttpLogsLogLevel
						'sasUrl'          = [string]$httpSASToken
						'retentionInDays' = $HttpLogsRetentionDays
						'enabled'         = $true
					}
				}
			}

		# Set the properties. Note that the resource type is: Microsoft.Web/sites/config and the resource name: [Web App Name]/logs		
		Write-Host "##[command]Set-AzureRmResource -PropertyObject $propertiesObject -ResourceGroupName $ResourceGroupName -ResourceType Microsoft.Web/sites/config -ResourceName '$($WebAppName)/logs' -ApiVersion 2016-03-01 -Force"
        Set-AzureRmResource -PropertyObject $propertiesObject -ResourceGroupName $ResourceGroupName -ResourceType Microsoft.Web/sites/config -ResourceName "$($WebAppName)/logs" -ApiVersion 2016-03-01 -Force	
} finally {
    Trace-VstsLeavingInvocation $MyInvocation
}



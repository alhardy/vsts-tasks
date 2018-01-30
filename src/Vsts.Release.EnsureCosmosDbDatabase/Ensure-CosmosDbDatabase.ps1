Trace-VstsEnteringInvocation $MyInvocation
Import-VstsLocStrings "$PSScriptRoot\task.json"

try {

	$CosmosDBAccount = Get-VstsInput -Name CosmosDBAccount -Require
	$ResourceGroupName = Get-VstsInput -Name ResourceGroupName -Require
	$DatabaseName = Get-VstsInput -Name DatabaseName -Require
	$CollectionName = Get-VstsInput -Name CollectionName -Require
	$CollectionPartitionKey = Get-VstsInput -Name CollectionPartitionKey -Require
	$CollectionRUs = Get-VstsInput -Name CollectionRUs -Require

	# Initialize Azure.
    Import-Module $PSScriptRoot\ps_modules\VstsAzureHelpers_
	Initialize-Azure
	
	Install-Module -Name CosmosDB -Force -Verbose -Scope CurrentUser

	Write-Host "##[command](New-CosmosDbConnection -Account $CosmosDBAccount -Database $DatabaseName -ResourceGroup $ResourceGroupName -MasterKeyType 'SecondaryMasterKey')"
	$cosmosDbConnection = New-CosmosDbConnection -Account $CosmosDBAccount -Database $DatabaseName -ResourceGroup $ResourceGroupName -MasterKeyType 'SecondaryMasterKey'
	
	try {
		Write-Host "##[command](Get-CosmosDbDatabase -Connection $cosmosDbConnection -Id $DatabaseName)"
		Get-CosmosDbDatabase -Connection $cosmosDbConnection -Id $DatabaseName
	} catch {
		if (-not ($_.Exception.Response.StatusCode.value__ -eq "404")) {
			throw $_.Exception
		} else {
			Write-Host "##[command](New-CosmosDbDatabase -Connection $cosmosDbConnection -Id $DatabaseName)"
			New-CosmosDbDatabase -Connection $cosmosDbConnection -Id $DatabaseName
		}
	}

	try {
		Write-Host "##[command](Get-CosmosDbCollection -Connection $cosmosDbConnection -Id $CollectionName)"
		Get-CosmosDbCollection -Connection $cosmosDbConnection -Id $CollectionName
	} catch {
		if (-not ($_.Exception.Response.StatusCode.value__ -eq "404")) {
			throw $_.Exception
		} else {
			Write-Host "##[command](New-CosmosDbCollection -Connection $cosmosDbConnection -Id $CollectionName -PartitionKey $CollectionPartitionKey -OfferThroughput $CollectionRUs)"
			New-CosmosDbCollection -Connection $cosmosDbConnection -Id $CollectionName -PartitionKey $CollectionPartitionKey -OfferThroughput $CollectionRUs
		}
	}
} finally {
    Trace-VstsLeavingInvocation $MyInvocation
}



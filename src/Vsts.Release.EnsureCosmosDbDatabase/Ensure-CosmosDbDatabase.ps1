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

	Write-Host "##[command](New-CosmosDbContext -Account $CosmosDBAccount -Database $DatabaseName -ResourceGroup $ResourceGroupName -MasterKeyType 'SecondaryMasterKey')"
	$cosmosDbContext = New-CosmosDbContext -Account $CosmosDBAccount -Database $DatabaseName -ResourceGroup $ResourceGroupName -MasterKeyType 'SecondaryMasterKey'
	
	try {
		Write-Host "##[command](Get-CosmosDbDatabase -Context $cosmosDbContext -Id $DatabaseName)"
		Get-CosmosDbDatabase -Context $cosmosDbContext -Id $DatabaseName
	} catch {
		if (-not ($_.Exception.Response.StatusCode.value__ -eq "404")) {
			throw $_.Exception
		} else {
			Write-Host "##[command](New-CosmosDbDatabase -Context $cosmosDbContext -Id $DatabaseName)"
			New-CosmosDbDatabase -Context $cosmosDbContext -Id $DatabaseName
		}
	}

	try {
		Write-Host "##[command](Get-CosmosDbCollection -Context $cosmosDbContext -Id $CollectionName)"
		Get-CosmosDbCollection -Context $cosmosDbContext -Id $CollectionName
	} catch {
		if (-not ($_.Exception.Response.StatusCode.value__ -eq "404")) {
			throw $_.Exception
		} else {
			Write-Host "##[command](New-CosmosDbCollection -Context $cosmosDbContext -Id $CollectionName -PartitionKey $CollectionPartitionKey -OfferThroughput $CollectionRUs)"
			New-CosmosDbCollection -Context $cosmosDbContext -Id $CollectionName -PartitionKey $CollectionPartitionKey -OfferThroughput $CollectionRUs
		}
	}
} finally {
    Trace-VstsLeavingInvocation $MyInvocation
}



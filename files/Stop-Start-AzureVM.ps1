Param 
(    
	[Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()] 
	[String] 
	$vmlist="All", 
	[Parameter(Mandatory=$true)][ValidateSet("Start","Stop")] 
	[String] 
	$action 
) 

# Ensures you do not inherit an AzContext in your runbook
Disable-AzContextAutosave -Scope Process

# Connect to Azure with system-assigned managed identity
$AzureContext = (Connect-AzAccount -Identity).context

# Set and store context
$AzureContext = Set-AzContext -SubscriptionName $AzureContext.Subscription -DefaultProfile $AzureContext

if($vmlist -ne "All") 
{ 
	$AzureVMs = $vmlist.Split(",") 
	[System.Collections.ArrayList]$AzureVMsToHandle = $AzureVMs 
} 
else 
{ 
	$AzureVMs = (Get-AzVM).Name 
	[System.Collections.ArrayList]$AzureVMsToHandle = $AzureVMs 

} 

foreach($AzureVM in $AzureVMsToHandle) 
{ 
	if(!(Get-AzVM | ? {$_.Name -eq $AzureVM})) 
	{ 
		throw " AzureVM : [$AzureVM] - Does not exist! - Check your inputs " 
	} 
} 

if($action -eq "Stop") 
{ 
	Write-Output "Stopping VMs"; 
	foreach ($AzureVM in $AzureVMsToHandle) 
	{ 
		Get-AzVM | ? {$_.Name -eq $AzureVM} | Stop-AzVM -Force 
	} 
} 
else 
{ 
	Write-Output "Starting VMs"; 
	foreach ($AzureVM in $AzureVMsToHandle) 
	{ 
		Get-AzVM | ? {$_.Name -eq $AzureVM} | Start-AzVM
	} 
}

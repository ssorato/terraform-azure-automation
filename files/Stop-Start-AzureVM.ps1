Param 
(    
	[Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()] 
	[String] 
	$vmlist="All", 
	[Parameter(Mandatory=$true)][ValidateSet("Start","Stop")] 
	[String] 
	$action,
	[Parameter(Mandatory=$false)]
	[String]
	$startscript=$null,
	[Parameter(Mandatory=$false)]
	[String]
	$stopscript=$null
) 

# Ensures you do not inherit an AzContext in your runbook
Disable-AzContextAutosave -Scope Process

# Connect to Azure with system-assigned managed identity
$AzureContext = (Connect-AzAccount -Identity).context

# Set and store context
$AzureContext = Set-AzContext -SubscriptionName $AzureContext.Subscription -DefaultProfile $AzureContext

if ($vmlist.ToLower() -ne "all") 
{ 
	$AzureVMs = $vmlist.Split(",") 
	[System.Collections.ArrayList]$AzureVMsToHandle = $AzureVMs 
} 
else 
{ 
	$AzureVMs = (Get-AzVM).Name 
	[System.Collections.ArrayList]$AzureVMsToHandle = $AzureVMs 

} 

foreach ($AzureVM in $AzureVMsToHandle) 
{ 
	if(!(Get-AzVM | ? {$_.Name -eq $AzureVM})) 
	{ 
		throw "Azure VM '$AzureVM' does not exist! - Check your inputs " 
	} 
} 

if ($action.ToLower() -eq "stop") 
{ 
	foreach ($AzureVM in $AzureVMsToHandle) 
	{ 
		$AzureRG = (Get-AzVM | ? {$_.Name -eq 'sboxvm'}).ResourceGroupName
		Write-Output "Stopping VM $AzureVM"; 
		if ($stopscript)
		{
			Invoke-AzVMRunCommand -ResourceGroupName $AzureRG -Name $AzureVM -CommandId 'RunShellScript' -Scripts $stopscript
		}
		Stop-AzVM -ResourceGroupName $AzureRG -Name $AzureVM -Confirm:$false -Force
	} 
} 
elseif ($action.ToLower() -eq "start")
{ 
	foreach ($AzureVM in $AzureVMsToHandle) 
	{
		$AzureRG = (Get-AzVM | ? {$_.Name -eq 'sboxvm'}).ResourceGroupName
		Write-Output "Starting VM $AzureVM"; 
		if ($startscript)
		{
			Invoke-AzVMRunCommand -ResourceGroupName $AzureRG -Name $AzureVM -CommandId 'RunShellScript' -Scripts $startscript
		}
		Start-AzVM -ResourceGroupName $AzureRG -Name $AzureVM -Confirm:$false
	} 
}
else 
{
	throw "Action '$action' does not exist! - Check your inputs " 
}

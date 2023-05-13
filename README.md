# Azure automation

Sample automation to start/stop VMs at scheduled time

## Testing azure commands using PowerShell

```ps
> Connect-AzAccount -UseDeviceAuthentication

> Get-AzVM | ? {$_.Name -eq 'sboxvm'}

ResourceGroupName   Name Location        VmSize OsType        NIC ProvisioningState Zone
-----------------   ---- --------        ------ ------        --- ----------------- ----
RG-SANDBOX-DEVOPS sboxvm   eastus Standard_B1ls  Linux nic-sboxvm         Succeeded

> (Get-AzVM).Name
sboxvm

> (Get-AzVM | ? {$_.Name -eq 'sboxvm'}).ResourceGroupName
RG-SANDBOX-DEVOPS

> $AzureRG = (Get-AzVM | ? {$_.Name -eq 'sboxvm'}).ResourceGroupName

> $AzureVM = 'sboxvm'

> Invoke-AzVMRunCommand -ResourceGroupName $AzureRG -Name $AzureVM -CommandId 'RunShellScript' -Scripts '/usr/bin/echo 123 > /tmp/from_azure_automation.txt'
```

On _sboxvm_ VM check the file `/tmp/from_azure_automation.txt`

```bash
sandbox@sboxvm ~]$ cat /tmp/from_azure_automation.txt
123
[sandbox@sboxvm ~]$ ls -l /tmp/from_azure_automation.txt
-rw-r--r--. 1 root root 4 May 13 11:57 /tmp/from_azure_automation.txt
```

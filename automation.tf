data "azurerm_resource_group" "azure_rg" {
  name = var.rg_name
}

resource "azurerm_automation_account" "aa_sandbox" {
  name                = var.automation_name
  location            = data.azurerm_resource_group.azure_rg.location
  resource_group_name = data.azurerm_resource_group.azure_rg.name
  sku_name = "Basic"
  
  identity {
    type          = "SystemAssigned"
  }

  tags = merge(
    {
      name        = var.automation_name
    },
    var.common_tags
  )
}

resource "azurerm_role_assignment" "automation_role" {
  scope                = data.azurerm_resource_group.azure_rg.id
  role_definition_name = "Contributor"
  principal_id         = azurerm_automation_account.aa_sandbox.identity[0].principal_id
}

#
# Credits: https://github.com/azureautomation/stopstartazurevm--scheduled-vm-shutdownstartup-/blob/master/Stop-Start-AzureVM.ps1
data "local_file" "Stop-Start-AzureVM" {
  filename = "files/Stop-Start-AzureVM.ps1"
}

resource "azurerm_automation_runbook" "rb_stop_start_vm" {
  name                    = "Stop-Start-AzureVM"
  location                = data.azurerm_resource_group.azure_rg.location
  resource_group_name     = data.azurerm_resource_group.azure_rg.name
  automation_account_name = azurerm_automation_account.aa_sandbox.name
  log_verbose             = "true"
  log_progress            = "true"
  description             = "This Run Book stop or start Azure VM"
  runbook_type            = "PowerShell"
  content                 = data.local_file.Stop-Start-AzureVM.content
  tags = merge(
    {
      name        = "Runbook-Stop-Start-AzureVM"
    },
    var.common_tags
  )
}

resource "azurerm_automation_schedule" "start_vm" {
  name                    = "StartVmEveryWorkDay7AM"
  resource_group_name     = data.azurerm_resource_group.azure_rg.name
  automation_account_name = azurerm_automation_account.aa_sandbox.name
  frequency               = "Week"
  interval                = 1
  timezone                = "America/Sao_Paulo"
  start_time              = timeadd(formatdate("YYYY-MM-DD'T'07:00:00-03:00", timestamp()), "24h")
  description             = "Run every week day at 7AM"
  week_days               = ["Monday","Tuesday","Wednesday","Thursday","Friday"]
}

resource "azurerm_automation_schedule" "stop_vm" {
  name                    = "StopVmEveryWorkDay9PM"
  resource_group_name     = data.azurerm_resource_group.azure_rg.name
  automation_account_name = azurerm_automation_account.aa_sandbox.name
  frequency               = "Week"
  interval                = 1
  timezone                = "America/Sao_Paulo"
  start_time              = timeadd(formatdate("YYYY-MM-DD'T'21:00:00-03:00", timestamp()), "24h")
  description             = "Run every week day at 9PM"
  week_days               = ["Monday","Tuesday","Wednesday","Thursday","Friday"]
}

resource "azurerm_automation_job_schedule" "start_vm_sched" {
  resource_group_name     = data.azurerm_resource_group.azure_rg.name
  automation_account_name = azurerm_automation_account.aa_sandbox.name
  schedule_name           = azurerm_automation_schedule.start_vm.name
  runbook_name            = azurerm_automation_runbook.rb_stop_start_vm.name
  depends_on = [
    azurerm_automation_schedule.start_vm
  ]
  parameters = {
    vmlist         = "${var.vm_name}"
    action         = "Start"
  }
}

resource "azurerm_automation_job_schedule" "stop_vm_sched" {
  resource_group_name     = data.azurerm_resource_group.azure_rg.name
  automation_account_name = azurerm_automation_account.aa_sandbox.name
  schedule_name           = azurerm_automation_schedule.stop_vm.name
  runbook_name            = azurerm_automation_runbook.rb_stop_start_vm.name
  depends_on = [
    azurerm_automation_schedule.stop_vm
  ]
  parameters = {
    vmlist         = "${var.vm_name}"
    action         = "Stop"
  }
}

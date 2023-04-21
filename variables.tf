variable "location" {
  type = string
  description = "Azure Region"
  default = "East US"
}

variable "rg_name" {
  type = string
  description = "Azure Resource Group name"
  default = "rg-sandbox-devops"
}

variable "vnet_name" {
  type = string
  description = "Azure Vnet name"
  default = "vnet-sandbox-devops"
}

variable "subnet_name" {
  type = string
  description = "Azure subnet name"
  default = "subnet-sandbox-devops"
}

variable "common_tags" {
  type        = map(string)
  description = "Common tags"
  default     = {
      created_by = "terraform-automation"
      sandbox    = "devops"
  }
}

variable "admin_username" {
  type = string
  description = "The admin username"
  default = "sandbox"
}

variable "vm_name" {
  type = string
  description = "The VM name"
  default = "sboxvm"
}

variable "automation_name" {
  type = string
  description = "The automation name"
  default = "automationsandbox"
}

variable "ssh_public_key_file" {
  type        = string
  description = "The contents of ssh public key for Linux VMs"
  default     = "~/.ssh/id_rsa.pub"
}

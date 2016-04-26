#requires -version 3
#
#  .SYNOPSIS
#
#  vm-setprivileges [-File="ScriptDirectory\vm-setcpumem.csv"] [-vCenter="MTO-VC.mars-ad.net","ISXVC1.mars-ad.net"]
#
#  .DESCRIPTION
#
#  PowerCLI script provides access for VMs specified in csv file
#
#  CSV File format: VMname, Role(ReadOnly, Admin, Virtual Machine Console Access), Principal
#
#  .EXAMPLE
#
#  1. Parse ScriptDirectory\vm-setprivileges.csv file and grant privileges for CSV specified VMs looking them in ISX and MTO 
#
#     vm-setprivileges.ps1
#
#  2. Parse C:\Scripts\privileges.csv file and grant privileges for CSV specified VMs looking them in issvcenter
#
#     vm-setprivileges.ps1 -File "C:\Scripts\privileges.csv" -vCenter issvcenter
#
#_______________________________________________________
#  Start of parameters block
#
[CmdletBinding()]
Param(
#
#  File path and name
#
   [Parameter(Mandatory=$False)]
   [string]$File=$PSScriptRoot+"\vm-setprivileges.csv",
#
#  vCenter
#
   [Parameter(Mandatory=$False)]
   [string]$vCenter=@("MTO-VC.mars-ad.net","ISXVC1.mars-ad.net")
)
#
# End of parameters block
#_______________________________________________________
#
# Add VMware PowerCLI Snap-Ins
#
   Add-PSSnapin VMware.VimAutomation.Core
#
# Reading csv
#
   write-host "Reading file "$File
   $VMs = import-csv $File
   $line=1
   foreach($VM in $VMs){
      Write-Host "Reading line "$line
      $VMname = $VM.VMname
      $role = $VM.Role
      $principal = $VM.Principal
      foreach($server in $vCenter){
#
# Connecting to vCenter
#
         write-host “Connecting to vCenter Server $server” -Foreground Yellow
         Connect-VIServer $server
         write-host “Connected to vCenter Server $server” -Foreground Green
#
# Check if we connected to appropriate vCenter
#
         $exist = Get-VM -Name $VMname -ErrorAction SilentlyContinue
         if(!$exist){
            write-host "Specified machine doesn't exist on "$server -ForegroundColor Red
            write-host “Disconnecting from vCenter Server $server” -foreground Yellow
            Disconnect-VIServer $server -confirm:$false
            write-host “Disconnected from vCenter Server $server” -foreground Green
            continue;
         }
         else{
            write-host "Virtual machine "$VMname" found at "$server" vCenter"
         }
#
#  Assigning privileges
#
         Get-Vm $VMname | New-VIPermission -role $role -Principal $principal
#
# Disconnecting from vCenter
#
         write-host “Disconnecting from vCenter Server $server” -foreground Yellow
         Disconnect-VIServer $server -confirm:$false
         write-host “Disconnected from vCenter Server $server” -foreground Green
#
# As we have done all nessesary changes stop looping servers
#
         break
      }
      $line++
   }
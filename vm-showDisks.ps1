#requires -version 4
#
#  .SYNOPSIS
#
#  vm-showDisk -vCenter -VMname
#
#  .DESCRIPTION
#
#  PowerCLI script connects to specified vCenter and list specified VM disks with all possible parameters (datastore, file, controller type and number,
#  disk number, provision type, etc.)
#
#  .EXAMPLES
#
#  1. Connects to isxvc1 vCenter and shows all discs for TestVM.
#
#     vm-showDisk.ps1 -vCenter isxvc1 -VMname TestVM
#
#_______________________________________________________
#  Start of parameters block
#
[CmdletBinding()]
Param(
#
#  vCenter Server (Login and password will be supplied via SSO)
#
   [Parameter(Mandatory=$True,Position=1)]
   [string]$vCenter,
#
#  VMname
#
   [Parameter(Mandatory=$True,Position=2)]
   [string]$VMname
)
#
# End of parameters block
#_______________________________________________________
#
# Add VMware PowerCLI Snap-Ins
#
   Add-PSSnapin VMware.VimAutomation.Core
#
# Connecting to vCenter
#
   write-host “Connecting to vCenter Server $vCenter” -Foreground Yellow
   Connect-VIServer $vCenter
   write-host “Connected to vCenter Server $vCenter” -Foreground Green
#
# Formated output
#
# vmXXXX
# Name: Hard disk 26 / CapacityKB: 144703488 / CapacityGB: 138 / StorageFormat: Thin / Filename: [MTOCLS04_NA1_07] vmwl3703_clone/vmwl3703_clone_9-000001.vmdk / Id: VirtualMachine-vm-415626/2013
#
   write-host $VMname
   write-host "__________"
   foreach($hd in Get-VM -Name $VMname | Get-HardDisk){
     $capacityKB = $hd | select CapacityKB
     $capacityGB = $hd | select CapacityGB
     $StorageFormat = $hd | select StorageFormat
     $filename = $hd | select Filename
     $id = $hd | select Id
     $scsiController = Get-ScsiController -HardDisk $hd
     $scsiControllerType = $scsiController | select Type

     write-host "Name:$hd / $capacityKB / $capacityGB / $StorageFormat / $filename / $id / C.Name:$scsicontroller / $scsiControllerType"
     write-host "__________"
   }

#
# Disconnecting from vCenter
#
   write-host “Disconnecting from vCenter Server $vCenter” -foreground Yellow
   Disconnect-VIServer $vCenter
   write-host “Disconnected from vCenter Server $vCenter” -foreground Green
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
   write-host $VMname
   write-host "__________"
   foreach($hd in Get-VM -Name $VMname | Get-HardDisk){
     $capacityKB = $hd.CapacityKB
     $capacityGB = $hd.CapacityGB
     $StorageFormat = $hd | select StorageFormat
     $filename = $hd.Filename
     $id = $hd.Id
     $scsiController = Get-ScsiController -HardDisk $hd
     $scsiControllerType = $scsiController.Type

     write-host "Name:$hd | CapacityKB:$capacityKB | CapacityGB:$capacityGB | $StorageFormat | Filename:$filename | Id:$id | C.Name:$scsicontroller | C.Type:$scsiControllerType"
     write-host "__________"
   }

#
# Disconnecting from vCenter
#
   write-host “Disconnecting from vCenter Server $vCenter” -foreground Yellow
   Disconnect-VIServer $vCenter
   write-host “Disconnected from vCenter Server $vCenter” -foreground Green
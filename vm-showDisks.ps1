#requires -version 4
#
#  .SYNOPSIS
#
#  vm-showDisk [-vCenter="MTO-VC.mars-ad.net","ISXVC1.mars-ad.net"] -VMname
#
#  .DESCRIPTION
#
#  PowerCLI script connects to specified vCenter or iterate over existing MTO and ISX farms and list specified VM disks with all possible parameters 
#  (datastore, file, controller type and number, disk number, provision type, etc.)
#
#  .EXAMPLES
#
#
#  1. Connects to both mto-vc and isxvc1 vCenters and shows all discs for TestVM.
#
#     vm-showDisk.ps1 -VMname TestVM
#
#  2. Connects to isxvc1 vCenter and shows all discs for TestVM.
#
#     vm-showDisk.ps1 -VMname TestVM -vCenter isxvc1
#
#_______________________________________________________
#  Start of parameters block
#
[CmdletBinding()]
Param(
#
#  vCenter Server (Login and password will be supplied via SSO)
#
   [Parameter(Mandatory=$False)]
   $vCenter=@("MTO-VC.mars-ad.net","ISXVC1.mars-ad.net"),
#
#  VMname
#
   [Parameter(Mandatory=$True,Position=1)]
   [string]$VMname
)
#
# End of parameters block
#_______________________________________________________
#
# Add VMware PowerCLI Snap-Ins
#
   Add-PSSnapin VMware.VimAutomation.Core

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
   write-host “Disconnecting from vCenter Server $server” -foreground Yellow
   Disconnect-VIServer $server -confirm:$false
   write-host “Disconnected from vCenter Server $server” -foreground Green
#
# Check if we've done
#
   if($exist){
     return
   }
}
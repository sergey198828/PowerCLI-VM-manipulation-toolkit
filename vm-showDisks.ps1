#requires -version 3
#
#  .SYNOPSIS
#
#  vm-showDisks -VMname [-vCenter="MTO-VC.mars-ad.net","ISXVC1.mars-ad.net"] [-File="ScriptDirectory\vm-showDisks.csv"]
#
#  .DESCRIPTION
#
#  PowerCLI script connects to specified vCenter or iterate over existing MTO and ISX farms and list specified VM disks with all possible parameters 
#  (datastore, file, controller type and number, disk number, provision type, etc.) and put result to csv file
#
#  .EXAMPLE
#
#  1. Connects to both mto-vc and isxvc1 vCenters to find TestVM and shows all its disks, results put to default file ScriptDirectory\vm-showDisks.csv.
#
#     vm-showDisks.ps1 -VMname TestVM
#
#  2. Connects to isxvc1 vCenter and shows all discs for TestVM and shows all its disks, results put to default file ScriptDirectory\vm-showDisks.csv.
#
#     vm-showDisks.ps1 -VMname TestVM -vCenter isxvc1
#
#  3. Connects to isxvc1 vCenter and shows all discs for TestVM and shows all its disks, results put to specified file C:\disks.csv. 
#
#     vm-showDisks.ps1 -VMname TestVM -vCenter isxvc1 -File "C:\disks.csv"
#
#_______________________________________________________
#  Start of parameters block
#
[CmdletBinding()]
Param(
#
#  VMname
#
   [Parameter(Mandatory=$True)]
   [string]$VMname,
#
#  vCenter Server (Login and password will be supplied via SSO)
#
   [Parameter(Mandatory=$False)]
   $vCenter=@("MTO-VC.mars-ad.net","ISXVC1.mars-ad.net"),
#
#  File path and name
#
   [Parameter(Mandatory=$False)]
   [string]$File=$PSScriptRoot+"\vm-showDisks.csv"
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
# Writing CSV
#
   $OutArray = @()
   foreach($hd in Get-VM -Name $VMname | Get-HardDisk){
     $out = "" | Select "Name","CapacityKB","CapacityGB","StorageFormat","Filename","Id","CName","CType","CId"
     $out.Name = $hd.Name
     $out.CapacityKB = $hd.CapacityKB
     $out.CapacityGB = $hd.CapacityGB
     $out.StorageFormat = $hd.StorageFormat
     $out.filename = $hd.Filename
     $out.Id = $hd.Id
     $scsiController = Get-ScsiController -HardDisk $hd
     $out.Cname = $scsiController.Name
     $out.CType = $scsiController.Type
     $out.CId = "SCSI[$($scsiController.ExtensionData.BusNumber):$($hd.ExtensionData.UnitNumber)]"
     $outarray += $out
   }
   $outarray | export-csv $File –NoTypeInformation
#
# Printing result
#
   Import-Csv $File
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
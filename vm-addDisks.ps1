#requires -version 4
#
#  .SYNOPSIS
#
#  vm-addDisks -VMname [-File="ScriptDirectory\vm-addDisks.csv"] [-vCenter="MTO-VC.mars-ad.net","ISXVC1.mars-ad.net"] [-force]
#
#  .DESCRIPTION
#
#  PowerCLI script connects to specified vCenter or iterate over existing MTO and ISX farms and add CSV specified hard drives to specified VM
#
#  .EXAMPLE
#
#  1. Connects to both mto-vc and isxvc1 vCenters in order to find TestVM and create new hard disks specified in ScriptDirectory\vm-addDisks.csv
#     each creation will promt for confirmation
#
#     vm-addDisks.ps1 -VMname TestVM
#
#  2. Connects to isxvc1 vCenter and create new hard disks specified in C:\NewDisks.csv without promting for confirmation
#
#     vm-addDisks.ps1 -VMname TestVM -vCenter isxvc1 -File="C:\NewDisks.csv" -force
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
   [string]$File=$PSScriptRoot+"\vm-addDisks.csv",
#
#  Force flag
#
   [Parameter(Mandatory=$False)]
   [switch]$force
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
# Reading csv
#
   write-host "Reading file "$File
   $hardDisks = import-csv $File
   $line = 1
   foreach($hardDisk in $hardDisks){
      Write-Host "Reading line "$line
      $capacityKB = $hardDisk.CapacityKB
      $datastoreName = $hardDisk.Datastore
      $datastoreMask = $hardDisk.DatastoreMask
#
# Selecting datastore
#
      #Option - user selects datastore from list awailable for the host
      if($datastoreName -eq "select"){
         $selectedDatastore = Get-VM -Name $VMname | Get-VMHost | Get-Datastore
         #Formated output
         $counter=1
         foreach ($ds in $selectedDatastore){
            Write-Host $counter" "$ds
            $counter++
         }
         $selectedDatastoreNumber = Read-Host "Select datastore (digits only)"
         $selectedDatastore = $selectedDatastore[$selectedDatastoreNumber-1]
         Write-Host "Datastore "$selectedDatastore" selected" -ForegroundColor Green
      }
      #Datastore with most free space awailable for host
      elseif($datastoreName -eq "mostFree"){
         $selectedDatastore = Get-VM -Name $VMname | Get-VMHost | Get-Datastore
         #No mask
         if($datastoreMask -eq ""){
            $selectedDatastore = $selectedDatastore |sort -descending FreeSpaceGB
         }
         #Mask
         else{
            $selectedDatastore = $selectedDatastore -match $datastoreMask |sort -descending FreeSpaceGB
            write-host "Mask '"$datastoreMask"' applied" -Foreground Green
         }
         $selectedDatastore = $selectedDatastore[0]
         Write-Host "Datastore "$selectedDatastore" with most free space selected" -Foreground Green
      }
      #User specified datastore
      else{
         $selectedDatastore = Get-Datastore -Name $datastoreName
         Write-Host "Specified datastore "$selectedDatastore" selected" -ForegroundColor Green
      }
#
# Resulted Disk configuration
#
    Write-Host "Capacity(KB): "$capacityKB -ForegroundColor Magenta
    Write-Host "Datastore: "$selectedDatastore -ForegroundColor Magenta
#
# Disk creation
#
   #Without confirmatiomn
   if($force){
      write-host “Adding disk to virtual machine” -Foreground Yellow
      Get-VM -Name $VMname | New-HardDisk -CapacityKB $capacityKB -Datastore $selectedDatastore
      write-host “Disk added" -Foreground Green 
   }
   #With confirmation
   else{
   $confirmation = Read-Host "Are you Sure Want To Proceed? (y|n)"
      if ($confirmation -eq 'y') {
         write-host “Adding disk to virtual machine” -Foreground Yellow
         Get-VM -Name $VMname | New-HardDisk -CapacityKB $capacityKB -Datastore $selectedDatastore
         write-host “Disk added" -Foreground Green  
      }
   }
      $line++
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
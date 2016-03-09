#requires -version 4
#
#  .SYNOPSIS
#
#  vm-create [-File="ScriptDirectory\vm-create.csv"] [-force]
#
#  .DESCRIPTION
#
#  PowerCLI script creates CSV specified virtual machines with CSV specified parameters
#
#  CSV File format: vCenter, Cluster, Host(select, random, specific), VMname, Datastore(select, mostFree, specific), DatastoreMask(Stacked with mostFree only),
#  NumCpu, MemoryMB, DiskMB
#
#  .EXAMPLE
#
#  1. Parse ScriptDirectory\vm-create.csv file and create specified VMs prompting for confirmation for each.
#
#     vm-create.ps1
#
#  2. Parse C:\create.csv file and create specified VMs without prompting for confirmation for each
#
#     vm-create.ps1 -File="C:\create.csv" -force
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
   [string]$File=$PSScriptRoot+"\vm-create.csv",
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
#
# Reading csv
#
   write-host "Reading file "$File
   $VMs = import-csv $File
   $line=1
   foreach($VM in $VMs){
      Write-Host "Reading line "$line
      $vCenter = $VM.vCenter
      $cluster = $VM.Cluster
      $hostname = $VM.Host
      $VMname = $VM.VMname
      $datastoreName = $VM.Datastore
      $datastoreMask = $VM.DatastoreMask
      $NumCpu = $VM.NumCpu
      $MemoryMB = $VM.MemoryMB
      $DiskMB = $VM.DiskMB
#
# Connecting to vCenter
#
      write-host “Connecting to vCenter Server $vCenter” -Foreground Yellow
      Connect-VIServer $vCenter
      write-host “Connected to vCenter Server $vCenter” -Foreground Green
#
# Selecting host
#
      write-host "Selecting host" -Foreground Yellow
      #Default option - user selects host from the list awailable for the cluster
      if($hostname -eq "select"){
         $selectedHost = Get-Cluster $cluster | Get-VMHost -state connected
         #Formated output
         $counter=1
         foreach ($h in $selectedHost){
            Write-Host $counter" "$h
            $counter++
         }
         $selectedHostNumber = Read-Host "Select host (digits only)"
         $selectedHost = $selectedHost[$selectedHostNumber-1]
         Write-Host "Specified host $selectedHost from $cluster cluster selected" -Foreground Green
      }
      #Random host of selected cluster
      elseif($hostname -eq "random"){
         $selectedHost = Get-Cluster $cluster | Get-VMHost -state connected | Get-Random
         Write-Host "Random host $selectedHost from " $cluster " cluster selected" -Foreground Green
      }
      #User specified host
      else{
         $selectedHost = Get-Cluster $cluster | Get-VMHost -name $hostname
         Write-Host "Specified host $selectedHost from " $cluster " cluster selected" -Foreground Green
      }
#
# Selecting datastore
#
      write-host "Selecting datastore" -Foreground Yellow
      #Default option - user selects datastore from list awailable for the host
      if($datastoreName -eq "select"){
         $selectedDatastore = Get-Datastore -VMHost $selectedHost
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
         $selectedDatastore = Get-Datastore -VMHost $selectedHost
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
# Resulted VMHost configuration
#
      Write-Host "vCenter: "$vCenter -ForegroundColor Magenta
      Write-Host "Cluster: "$cluster -ForegroundColor Magenta
      Write-Host "VMname: "$VMname -ForegroundColor Magenta
      Write-Host "Host: "$selectedHost -ForegroundColor Magenta
      Write-Host "Datastore: "$selectedDatastore -ForegroundColor Magenta
      Write-Host "Number of CPUs: "$NumCpu -ForegroundColor Magenta
      Write-Host "Memory(MB): "$MemoryMB -ForegroundColor Magenta
      Write-Host "Disk(MB): "$DiskMB -ForegroundColor Magenta
#
# Creating host
#
      #Without confirmatiomn
      if($force){
         write-host “Creating new virtual machine” -Foreground Yellow
         New-VM -Name $VMname -VMHost $selectedHost -Datastore $selectedDatastore -NumCpu $NumCpu -MemoryMB $MemoryMB -DiskMB $DiskMB
         write-host “New virtual machine ”$VMname" created" -Foreground Green
      }
      #With confirmation
      else{
         $confirmation = Read-Host "Are you Sure Want To Proceed? (y|n)"
         if ($confirmation -eq 'y') {
            write-host “Creating new virtual machine” -Foreground Yellow
            New-VM -Name $VMname -VMHost $selectedHost -Datastore $selectedDatastore -NumCpu $NumCpu -MemoryMB $MemoryMB -DiskMB $DiskMB
            write-host “New virtual machine ”$VMname" created" -Foreground Green  
         }
      }
#
# Disconnecting from vCenter
#
      write-host “Disconnecting from vCenter Server $vCenter” -foreground Yellow
      Disconnect-VIServer $vCenter -confirm:$false
      write-host “Disconnected from vCenter Server $vCenter” -foreground Green
      
      $line++
   }
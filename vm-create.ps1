#requires -version 4
#
#  .SYNOPSIS
#
#  vm-create -vCenter -cluster -VMname [-hostName=select] [-datastoreName=select] [-datastoreMask=null]
#  [-NumCpu=4] [-MemoryMB=8192] [-DiskMB=51200]
#
#  .DESCRIPTION
#
#  PowerCLI script connects to specified vCenter and creates virtual machine in specified Cluster with  
#  specified Name and parameters
#
#  .EXAMPLES
#
#  1. Connects to isxvc1 vCenter and creates virtual machine named TestVM on host which user promted to choose from console dialog of ISXMGTCLS
#     cluster in datastore awailable for selected host which user also promted to choose from console dialog
#
#     vm-create.ps1 -vCenter isxvc1.mars-ad.net -cluster ISXMGTCLS -VMname TestVM
#
#  2. Connects to isxvc1 vCenter and creates virtual machine named TestVM on random host of ISXMGTCLS
#     cluster in datastore with most free space awailable for selected host
#
#     vm-create.ps1 -vCenter isxvc1.mars-ad.net -cluster ISXMGTCLS -VMname TestVM -hostname random -datastoreName mostFree
#
#  3. Connects to isxvc1 vCenter and creates virtual machine named TestVM on specified host isxe0804.mars-ad.net
#     in datastore with most free space which has "local" keyword in name
#
#     vm-create.ps1 -vCenter isxvc1.mars-ad.net -cluster ISXMGTCLS -VMname TestVM -hostName isxe0804.mars-ad.net 
#     -datastoreName mostFree -datastoreMask local
#
#  4. Connects to isxvc1 vCenter and creates virtual machine named TestVM on specified host isxe0804.mars-ad.net
#     in specified datastore ISXE0804_Local_Boot
#
#     vm-create.ps1 -vCenter isxvc1.mars-ad.net -cluster ISXMGTCLS -VMname TestVM -hostName isxe0804.mars-ad.net 
#     -datastoreName ISXE0804_Local_Boot 
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
#  Cluster
#
   [Parameter(Mandatory=$True,Position=2)]
   [string]$cluster,
#
#  Name
#
   [Parameter(Mandatory=$True,Position=3)]
   [string]$VMname,
#
#  Host (Default behavior is random host in specified cluster)
#
   [Parameter(Mandatory=$False)]
   [string]$hostName="select",
#
#  Datastore (Default behavior is Datastore with most free space)
#
   [Parameter(Mandatory=$False)]
   [string]$datastoreName="select",
#
#  Mask to filter datastores (Default behavior is no filter)
#
   [Parameter(Mandatory=$False)]
   [string]$datastoreMask="",
#
#  Number of CPUs (Default is 4)
#
   [Parameter(Mandatory=$False)]
   [string]$NumCpu=4,
#
#  Memory configuration (Default is 8GB)
#
   [Parameter(Mandatory=$False)]
   [string]$MemoryMB=8192,
#
#  Disk configuration (Default is 50GB)
#
   [Parameter(Mandatory=$False)]
   [string]$DiskMB=51200
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
      $selectedDatastore = $selectedDatastore[$selectedDatastoreNumber]
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
   $confirmation = Read-Host "Are you Sure Want To Proceed? (y|n)"
   if ($confirmation -eq 'y') {
      write-host “Creating new virtual machine” -Foreground Yellow
      New-VM -Name $VMname -VMHost $selectedHost -Datastore $selectedDatastore -NumCpu $NumCpu -MemoryMB $MemoryMB -DiskMB $DiskMB
      write-host “New virtual machine ”$VMname" created" -Foreground Green  
   }
#
# Disconnecting from vCenter
#
    write-host “Disconnecting from vCenter Server $vCenter” -foreground Yellow
    Disconnect-VIServer $vCenter
    write-host “Disconnected from vCenter Server $vCenter” -foreground Green
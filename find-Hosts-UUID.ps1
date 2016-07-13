#requires -version 3
#
#  .SYNOPSIS
#
#  find-Hosts-UUID [-vCenter="MTO-VC.mars-ad.net","ISXVC1.mars-ad.net"] [-File="ScriptDirectory\find-Hosts-UUID.csv"]
#
#  .DESCRIPTION
#
#  PowerCLI script connects to specified vCenter or iterate over existing MTO and ISX farms and list UUIDs of all hosts to file.
#
#  .EXAMPLE
#
#  1. Connects to both mto-vc and isxvc1 vCenters and outputs UUIDs of all hosts to file ScriptDirectory\find-Hosts-UUID.csv.
#
#     find-Hosts-UUID.ps1
#
#  2. Connects to isxvc1 vCenter and output UUIDs of all hosts to file C:\Output.csv.
#
#     find-Hosts-UUID.ps1 -vCenter="isxvc1" -File="C:\Output.csv"
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
#  File path and name
#
   [Parameter(Mandatory=$False)]
   [string]$File=$PSScriptRoot+"\find-Hosts-UUID.csv"
)
#
# End of parameters block
#_______________________________________________________
#
# Add VMware PowerCLI Snap-Ins
#
   Add-PSSnapin VMware.VimAutomation.Core
#
# Container for results
#
   $OutArray = @()   
#
# Looping over vCenters
#
   foreach($server in $vCenter){
#
# Connecting to vCenter
#
     write-host “Connecting to vCenter Server $server” -Foreground Yellow
     Connect-VIServer $server
     write-host “Connected to vCenter Server $server” -Foreground Green
#
# Looping over all hosts in vCenter
#
     $hosts = Get-VMHost
     foreach ($h in $hosts){
#
# Gathering UUID
#
       $vmhostUUID = (Get-VMHost $h | Get-View).hardware.systeminfo.uuid
       write-host $h.Name" "$vmhostUUID
#
# Adding to container
#
     $out = "" | Select "vCenter","Host","UUID"
     $out.vCenter = $server
     $out.Host = $h.Name
     $out.UUID = $vmhostUUID
     $outarray += $out     
     }
#
# Disconnecting from vCenter
#
   write-host “Disconnecting from vCenter Server $server” -foreground Yellow
   Disconnect-VIServer $server -confirm:$false
   write-host “Disconnected from vCenter Server $server” -foreground Green
  }

#
# Writing CSV
#
   write-host "Writing results to file "$File -ForegroundColor Yellow
   $outarray | export-csv $File –NoTypeInformation
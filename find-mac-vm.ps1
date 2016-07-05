#requires -version 3
#
#  .SYNOPSIS
#
#  find-mac-vm -mac [-vCenter="MTO-VC.mars-ad.net","ISXVC1.mars-ad.net"]
#
#  .DESCRIPTION
#
#  PowerCLI script connects to specified vCenter or iterate over existing MTO and ISX farms and search for VM with specific MAC address
#
#  .EXAMPLE
#
#  1. Connects to both mto-vc and isxvc1 vCenters to find VM with following mac address ff:ff:ff:ff:ff:ff.
#
#     find-mac-vm -mac "ff:ff:ff:ff:ff:ff"
#
#  2. Connects to isxvc1 vCenter to find VM with following mac address ff:ff:ff:ff:ff:ff.
#
#     find-mac-vm -mac "ff:ff:ff:ff:ff:ff" -vCenter "isxvc1" 
#
#_______________________________________________________
#  Start of parameters block
#
[CmdletBinding()]
Param(
#
#  Mac address
#
   [Parameter(Mandatory=$True)]
   [string]$mac,
#
#  vCenter Server (Login and password will be supplied via SSO)
#
   [Parameter(Mandatory=$False)]
   $vCenter=@("MTO-VC.mars-ad.net","ISXVC1.mars-ad.net")
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
# Looping over all VMs
#
   $VMs = Get-VM 
   foreach ($VM in $VMs){
   write-host Looking at $VM in $server
#
# Looping over all VMs network adapters
#
      $NICs = Get-VM $VM | Get-NetworkAdapter
      foreach ($NIC in $NICs){
#
# Check if we founnd mac
#
         if($mac -eq $NIC.MacAddress){
            write-host found $mac at $NIC of $VM in $server -ForegroundColor Green
            write-host “Disconnecting from vCenter Server $server” -foreground Yellow
            Disconnect-VIServer $server -confirm:$false
            write-host “Disconnected from vCenter Server $server” -foreground Green
            return
         }
      }
   }
}
#
# Didnt manage to find
#
write-host VM with $mac not found -ForegroundColor Red
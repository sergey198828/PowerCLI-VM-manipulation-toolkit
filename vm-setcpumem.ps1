#requires -version 3
#
#  .SYNOPSIS
#
#  vm-setcpumem [-File="ScriptDirectory\vm-setcpumem.csv"] [-vCenter="MTO-VC.mars-ad.net","ISXVC1.mars-ad.net"]
#
#  .DESCRIPTION
#
#  PowerCLI script changes VM cpu and Memory configuration
#
#  CSV File format: VMname, NumCPU, ReservationMhz, LimitMhz, CPUPriority (Low, Normal, High), RAMGB, ReservationGB, LimitGB, RAMPriority(Low, Normal, High)
#
#  .EXAMPLE
#
#  1. Parse ScriptDirectory\vm-setcpumem.csv file and change VM CPU and Memory configuration for specified VMs looking them in ISX and MTO 
#
#     vm-setcpumem.ps1
#
#  2. Parse C:\Scripts\CPUMEM.csv file and change VM CPU and Memory configuration for specified VMs looking them in issvcenter
#
#     vm-setcpumem.ps1 -File "C:\Scripts\CPUMEM.csv" -vCenter issvcenter
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
   [string]$File=$PSScriptRoot+"\vm-setcpumem.csv",
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
      $NumCpu = $VM.NumCPU
      $CpuReservationMhz = $VM.ReservationMhz
      $CpuLimitMhz = $VM.LimitMhz
      $CpuPriority = $VM.CPUPriority
      $RamGB = $VM.RAMGB
      $RamReservationGB = $VM.ReservationGB 
      $RamLimit = $VM.LimitGB
      $RamPriority=$VM.RAMPriority
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
# Shutting VM down
#
         if ((Get-VM $VMname).PowerState -eq "PoweredOn") {
            # Check if VM has VMware tools installed othervize ask user to shutdown it manually
            $toolsStatus = (Get-VM $VMname | Get-View).Guest.ToolsStatus
            if($toolsStatus -eq "toolsNotInstalled"){
               write-host "VMware tools not installed on VM unable to shutdown gracefully. Please shutdown VM manually and then run scrupt again."
               continue
            }
            #Check if installed tools is ok and make user aware
            if(!($toolsStatus -eq "toolsOk")){
               $confirmation = Read-Host "Installed tools has "$toolsStatus" state we cant guarantee proper grace shutdown and recoment to shutdown VM manually and run the script again. Would you like to continue shutdown? (y|n)"
               if (!($confirmation -eq 'y')) {
                  continue
               }
            }
            Write-Host "Shutting Down "$VMname 
            Get-Vm $VMname | Stop-VMGuest -Confirm:$false | Out-Null
            do {
               Write-Host "Shutting down"
               Start-Sleep -s 1
            }until((Get-VM $VMname).PowerState -eq "PoweredOff") 
         } 
#
# Changing CPU
#
         if(!($NumCpu -eq "")){
            Write-Host "Changing CPU number to "$NumCpu -ForegroundColor Yellow
            Get-Vm $VMName | Set-VM -NumCPU $NumCpu -Confirm:$false | Out-Null
         }
         if(!($CpuReservationMhz -eq "")){
            Write-Host "Changing CPU reservation to "$CpuReservationMhz" Mhz" -ForegroundColor Yellow
            Get-VM $VMname | Get-VMResourceConfiguration | Set-VMResourceConfiguration -CpuReservationMhz $CpuReservationMhz -Confirm:$false | Out-Null
         }
         if(!($CpuLimitMhz -eq "")){
            Write-Host "Changing CPU limit to "$CpuLimitMhz" Mhz" -ForegroundColor Yellow
            Get-VM $VMname | Get-VMResourceConfiguration | Set-VMResourceConfiguration -CpuLimitMhz $CpuLimitMhz -Confirm:$false | Out-Null
         }
         if(!($CpuPriority -eq "")){
            Write-Host "Changing CPU priority to "$CpuPriority -ForegroundColor Yellow
            Get-VM $VMname | Get-VMResourceConfiguration | Set-VMResourceConfiguration -CpuSharesLevel $CpuPriority -Confirm:$false | Out-Null    
         }
#
# Changing Memory
#
         if(!($RamGB -eq "")){
            Write-Host "Changing memory to "$RamGB" GB" -ForegroundColor Yellow
            Get-Vm $VMName | Set-VM -MemoryGB $RamGB -Confirm:$false | Out-Null
         }
         if(!($RamReservationGB -eq "")){
            Write-Host "Changing memory reservation to "$RamReservationGB" GB" -ForegroundColor Yellow
            Get-VM $VMname | Get-VMResourceConfiguration | Set-VMResourceConfiguration -MemReservationGB $RamReservationGB -Confirm:$false | Out-Null
         }
         if(!($RamLimit -eq "")){
            Write-Host "Changing memory limit to "$RamLimit" GB" -ForegroundColor Yellow
            Get-VM $VMname | Get-VMResourceConfiguration | Set-VMResourceConfiguration -MemLimitGB $RamLimit -Confirm:$false | Out-Null
         }
         if(!($RamPriority -eq "")){
            Write-Host "Changing memory priority to "$RamPriority -ForegroundColor Yellow
            Get-VM $VMname | Get-VMResourceConfiguration | Set-VMResourceConfiguration -MemSharesLevel $RamPriority -Confirm:$false | Out-Null
         }
#
# Print VM resource configuration
#
         Get-VM $VMname | Get-VMResourceConfiguration
#
# Starting VM up
#
         Get-VM $VMName | Start-VM -Confirm:$false | Out-Null
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
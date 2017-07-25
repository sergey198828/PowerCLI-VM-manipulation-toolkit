#requires -version 3
#
#  .SYNOPSIS
#
#  vm-invokeCmd [-ScriptText] [-vCenter] [-DataStore] [-Iso] [-inputFile] [-outputFile]
#
#  CSV format: Guest
#
#  .DESCRIPTION
#
#  PowerCLI script mounts ISO with bat files to CSV specified list of machines and executes specified Script on each of them putting result to CSV specified output file.
#
#  .EXAMPLE
#
#  1. Execute script with all possible parameters
#
#     $script = "@echo off & setlocal & for /f ""skip=1 tokens=1,2"" %i in ('wmic logicaldisk get caption^, drivetype') do (  if [%j]==[5] ( pushd %i\ & Validate.bat & EXIT ) ) & endlocal"
#
#     vm-invokeCmd -ScriptText $script -vCenter "vcenter.eu.mars" -DataStore "ESX-Local1" -Iso "ISO\Some.iso" -inputFile "C:\Scripts\guests.csv"
#
#
#_______________________________________________________
#  Start of parameters block
#
[CmdletBinding()]
Param(
#
#  Script Text
#
   [Parameter(Mandatory=$False)]
   [string]$ScriptText = "@echo off & setlocal & for /f ""skip=1 tokens=1,2"" %i in ('wmic logicaldisk get caption^, drivetype') do (  if [%j]==[5] ( pushd %i\ & Validate.bat & EXIT ) ) & endlocal",
#
#  vCenter
#
   [Parameter(Mandatory=$False)]
   [string]$vCenter = "10.24.56.100",
#
#  DataStore
#
   [Parameter(Mandatory=$False)]
   [string]$DataStore = "DataStore-ISOs-SAN01-10K",
#
#  ISO
#
   [Parameter(Mandatory=$False)]
   [string]$ISO = "ValidationV6-ZeroTouch.iso",

#
#  Input file
#
   [Parameter(Mandatory=$False)]
   [string]$InputFile=$PSScriptRoot+"\guests.csv",
#
#  Output file
#
   [Parameter(Mandatory=$False)]
   [string]$OutputFile=$PSScriptRoot+"\results.csv"
)
#
#  End of parameters block
#
#_______________________________________________________
#
#  Add VMware PowerCLI Snap-Ins
#
#  Add-PSSnapin VMware.VimAutomation.Core
#_______________________________________________________
#
#  Creating TMP directory if not exist
#
   $TmpPath = "C:\temp"
   If(!(test-path $TmpPath))
   {
      New-Item -ItemType Directory -Force -Path $TmpPath
   }
#
#  Construcing vCenter credentials
#
   Write-host "Please enter vCenter username"
   $vCenterUserName = read-host
   read-host "Please enter vCenter password" -assecurestring | convertfrom-securestring | out-file $TmpPath\securestring.txt
   $vCenterPassword = cat $TmpPath\securestring.txt | convertto-securestring
   $vCenterCredential = new-object -typename System.Management.Automation.PSCredential -argumentlist $vCenterUserName, $vCenterPassword
#
#  Construcing Guest credentials
#
   Write-host "Please enter Guest username"
   $GuestUserName = read-host
   read-host "Please enter Guest password" -assecurestring | convertfrom-securestring | out-file $TmpPath\securestring.txt
   $GuestPassword = cat $TmpPath\securestring.txt | convertto-securestring
   $GuestCredential = new-object -typename System.Management.Automation.PSCredential -argumentlist $GuestUserName, $GuestPassword
#
#  Connecting to vCenter
#
   write-host “Connecting to vCenter Server $vCenter” -Foreground Yellow
   Connect-VIServer -Server $vCenter -Credential $vCenterCredential | Out-Null
   write-host “Connected to vCenter Server $vCenter” -Foreground Green
#
#  Reading input file
#
   Write-Host "Reading file "$InputFile
   $Guests = import-csv $InputFile
#
#  Prepare output file
#
   write-host "Writing file "$OutputFile
   Add-Content $OutputFile "Guest, Output"
#
#  Looping over servers
#
   Foreach($Line in $Guests){
#
#  Get next VM
#
     $GuestName = $Line.Guest
     $Guest = Get-Vm $GuestName
     Write-Host "Checking "$GuestName
     $ScriptOutput = "None"
#
#  Check VMTools status
#
     $toolsStatus = (Get-VM $Guest | Get-View).Guest.ToolsStatus
     if($toolsStatus -eq "toolsOk"){
#
#  Insert ISO to CD Rom
#
       Get-CDDrive $Guest | Set-CDDrive -StartConnected:$false -Connected:$true -IsoPath "[$DataStore] $ISO" -Confirm:$false | Out-Null
#
#  Execute command
#
       try{
         $Output = Invoke-VMScript -ScriptText $ScriptText -VM $Guest -ScriptType Bat -GuestCredential $GuestCredential -ErrorAction Stop
         $ScriptOutput = $Output.ScriptOutput
       }
       Catch
       {
         $ScriptOutput = $_.Exception.Message
       }
#
#  Eject ISO from CD Rom
#
       Get-CDDrive $Guest | Set-CDDrive -StartConnected:$false -Connected:$false -Confirm:$false | Out-Null
#
#  If tools are not ok
#
     }else{
       $ScriptOutput = "VMWare tools is not ok, server skipped, upgrade VMWare tools and try again"
     }
#
#  Writing outout to file
#
    Add-Content $OutputFile "$GuestName, $ScriptOutput"
   }
#
# Disconnecting from vCenter
#
   write-host “Disconnecting from vCenter Server $vCenter” -foreground Yellow
   Disconnect-VIServer -Server $vCenter -Confirm:$false
   write-host “Disconnected from vCenter Server $vCenter” -foreground Green
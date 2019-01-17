<#

.SYNOPSIS
This script removes IIS Log files.

.DESCRIPTION
Run this script against IIS Web servers to remove any stale log files.


.PARAMETER ComputerName
Computer Name or Names to run against


.PARAMETER CSV
Specifies a list of servers to run against. This file should have no heading.

.PARAMETER LogPath
Path of IIS Log files. This defaults to "C:\Inetpub\Logs\"

.PARAMETER MaxMonths
Maximum number of months to keep for log retention.

.PARAMETER Credential
Specifies a Powershell Credential Object to spefified servers, if different that locally authenticated user.

.EXAMPLE
./cleanupIIS.ps1 

Runs against localhost.

.EXAMPLE
./cleanupIIS.ps1 -ComputerName "Web01"

Runs against a single Web Server with authenticated user.

.EXAMPLE
./cleanupIIS.ps1 -VCAList "Web01","Web02"

Runs against multipule Web Servers with authenticated user.

.EXAMPLE
./cleanupIIS.ps1 -CSV ./serverlist.csv -Credential $creds

Runs against a list of servers passing in a Powershell Credential Object.

.NOTES
    Author: Nick Lepore
    Date:   Jan 17, 2019
    Version: 1.01    

#>




[Cmdletbinding()]
param(
$ComputerName,
$Credential,
$CSV,
$LogPath = "C:\inetpub\logs\",
$MaxMonths = 6
)



if (($ComputerName -eq $null) -and ($CSV -eq $null)){
$ComputerName = "localhost"
}
elseif (($ComputerName -eq $null) -and ($CSV -ne $null)){

if (test-path $CSV) {
"Found Server List"

$ComputerName=Get-Content -Path $CSV


} 


else {

"Please specify Computer(s) with -ComputerName"

}

}




##IIS Cleanup Function##
Function IISCleanup {
[Cmdletbinding()]

param(
$LogPath = $args[0],
$MaxMonths = $args[1]
)

 
if (test-path $LogPath){
  
$itemsToDelete = Get-ChildItem -path $LogPath -Recurse -Filter *.log | Where {$_.LastWriteTime -lt ((get-date).AddMonths(-$MaxMonths))} 
$itemMeasure = $itemsToDelete | Measure-Object -Property length -Sum

if ($itemsToDelete.Count -gt 0){ 
    ForEach ($item in $itemsToDelete){ 
        $item | Remove-Item -Verbose 
    } 


    "Space Recovered = " + ($itemMeasure.sum /1mb).ToString() + " MB"
    "Files Removed = "+ ($itemMeasure.count)


} 
ELSE{ 
    "No items to be deleted today $($(Get-Date).DateTime)" 
    } 
   
Write-Output "Cleanup of log files older than $((get-date).AddMonths(-$MaxMonths)) completed..." 
start-sleep -Seconds 5
}
else { "$LogPath does not exist"}
}



##If Alternate Credentials have been provided##


if ($Credential -ne $null){

foreach ($Computer in $ComputerName){   



if (($Computer -eq "localhost") -or ($Computer -eq $env:COMPUTERNAME)){
"Running on Localhost"
invoke-command -ScriptBlock ${function:IISCleanup} -ArgumentList $LogPath, $MaxMonths 

}

else{
"Running on Remote Server $Computer"

Invoke-Command -ComputerName $Computer -Credential $Credential -ScriptBlock ${function:IISCleanup} -ArgumentList $LogPath, $MaxMonths
}
}
}


##If Running as Authenticated User##


else{

foreach ($Computer in $ComputerName){  


if (($Computer -eq "localhost") -or ($Computer -eq $env:COMPUTERNAME)){ 
"Running on Localhost"
invoke-command -ScriptBlock ${function:IISCleanup} -ArgumentList $LogPath, $MaxMonths 
 }
else{ 
"Running on Remote Server $Computer"
Invoke-Command -ComputerName $Computer -ScriptBlock ${function:IISCleanup} -ArgumentList $LogPath, $MaxMonths

}
}
}





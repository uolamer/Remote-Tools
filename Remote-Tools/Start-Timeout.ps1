<#
.SYNOPSIS
Restart a sleep that you can skip by pressing the q key
.DESCRIPTION
This is designed to be a powershell replacement for timeout.exe
Basically a Start-Sleep that lets you press q to skip
There is a minimum of 1 second and a limit of 2147483 seconds
.EXAMPLE
Start-Timeout -Timeout 60
This will start a sleep of 60 seconds that you can skip by pressing the q key.
.EXAMPLE
Start-Timeout -Timeout 60 -Quiet
This will start a sleep of 60 seconds that you can skip by pressing the q key.
no output will be displayed as -Quiet was specified but the q key can still skip the timeout
.EXAMPLE
Start-Timeout 10
Simple 10 second timeout showing that the -Timeout flag is optional
#>
function Start-Timeout {
	[CmdletBinding()]
	Param(	
		# Number of seconds to sleep
		[ValidateRange(1, 2147483)][Parameter(Mandatory, Position = 0)][int]$Timeout,
		# Supress non Warning and Errors
		[Parameter()][switch]$Quiet
	)

	if ($Timeout) {
		if (!$Quiet) { Write-Output "Waiting for $Timeout seconds, press q to continue ..." }
		[int]$Timeout *= 1000
		while ($Timeout) {
			if ([Console]::KeyAvailable) {
				$keyInfo = [Console]::ReadKey($true)
				if ($keyInfo.key -eq "q") {
					break
				}
			}
		Start-Sleep -Milliseconds 50
		$Timeout -= 50
		}
	}
}

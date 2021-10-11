<#
.SYNOPSIS
Stop a service on a remote machine.
.EXAMPLE
Stop-RemoteService -ComputerName Server01 -ServiceName Spooler -Timeout 90 -Force -ProgressBar
Stop the "Spooler" service on Server01 waiting up to 90 seconds for it to stop.
Process will be terminated if still running after those 90 seconds
Progress bar will be shown while waiting.
.EXAMPLE
Stop-RemoteService -ComputerName Server01 -ServiceName Spooler -Timeout 10
Stop the Spooler service on Server01 waiting up to 10 seconds for it to stop.
.EXAMPLE
Stop-RemoteService -ComputerName Server01 -ServiceName Spooler -Timeout 10 -quiet
Stop the Spooler service on Server01 waiting up to 10 seconds for it to stop.
The quiet flag will supress all normal outupt but warnings and errors
#>
function Stop-RemoteService {
	[CmdletBinding()]
	Param(	
		# The name of the remote computer.
		[Parameter(Mandatory, Position = 0)][string]$ComputerName,
		# The name of the remote service.
		[Parameter(Mandatory, Position = 1)][string]$ServiceName,
		# Seconds (0-900) to wait for process to die in seconds. Defaults to 60 if not specified.
		[ValidateRange(0, 900)][Parameter(Position = 2)][int]$TimeOut = 60,
		# How long to wait for process to stop
		[Parameter()][switch]$Force,
		# Option to show a progress bar while waiting
		[Parameter()][switch]$ProgressBar,
		# Option to supress output besides errors and warnings
		[Parameter()][switch]$Quiet
	)

	# Verify there is a PID for service, if not return
	$Service = Get-RemoteService $ComputerName $ServiceName
	if (!$Service) {
		Write-Error "Unable to connect to ""$ComputerName""."
		return $Service
		}
		
	if ($Service.State -eq "Stopped") {
		Write-Warning "$ServiceName"" on ""$ComputerName"" is already stopped."
		return $Service
	}
	
	# Output based on if Force was specified.
	if($Force){
		if (!$Quiet){Write-Host "Stopping ""$ServiceName on ""$ComputerName"". PID ""$($Service.ProcessId)"". (forced after $TimeOut seconds)"}
	} else {
		if (!$Quiet){Write-Host "Stopping ""$ServiceName"" on ""$ComputerName"" PID ""$($Service.ProcessId)""."}
	}
    
	# Send stop service command to remote server.
	$null = $Service.stopservice()


	# Wait up to the timeout for the service to stop.
	if ($ProgressBar -and $TimeOut) {
		$Activity = "Stopping ""$ServiceName"" on ""$ComputerName""."
		for($i = 0; $i -lt $TimeOut -and (Get-RemoteService -ComputerName $ComputerName -ServiceName $ServiceName).ProcessId; $i += 1){
			Write-Progress -Activity $Activity -PercentComplete ($i / $TimeOut * 100) -SecondsRemaining ($TimeOut - $i)
			Start-Sleep -Seconds 1
		}
		Write-Progress -Activity $Activity -Completed
	} elseif($TimeOut) {
		if (!$Quiet){Write-Host "Waiting up to ""$TimeOut"" seconds for service to stop..." }
		while ($TimeOut -and (Get-RemoteService $ComputerName $ServiceName).ProcessId) {
			Start-Sleep -Seconds 1
			$TimeOut -= 1
		}
	}
    
    
	# Get current state of service for verification/force-killing
	$Service = Get-RemoteService -ComputerName $ComputerName -ServiceName $ServiceName
	if ($Service.State -ne 'Stopped' -and $Force) {
		Write-Warning "Process did not die. Force Killing PID ""$($Service.ProcessId)""."
		$null = (get-wmiobject Win32_Process -ComputerName $ComputerName -Filter "ProcessId = '$($Service.ProcessId)'").Terminate()
		Start-Sleep -Seconds 1
		$Service = Get-RemoteService -ComputerName $ComputerName -ServiceName $ServiceName
	}

	if($Service.State -ne 'Stopped' -and $Force){
		Write-Error "Service ""$ServiceName"": ""$($Service.State)""."
	} elseif($Service.State -ne 'Stopped'){
		Write-Warning "Service ""$ServiceName"": ""$($Service.State)""."
	} else {
		if (!$Quiet){Write-Host "Service ""$ServiceName"": ""$($Service.State)""." }
	}
	return $Service
}

# Tab-Completion for service names on the remote computer.
Register-ArgumentCompleter -CommandName Stop-RemoteService -ParameterName ServiceName -ScriptBlock {
    PARAM($CommandName, $ParameterName, $WordToComplete, $CommandAst, $FakeBoundParameters)
    if(!$FakeBoundParameters.ContainsKey('ComputerName')){ return }
    $ComputerName = $FakeBoundParameters['ComputerName']
    Get-WmiObject -Query "select Name from Win32_Service where Name like '$WordToComplete%'" -ComputerName $ComputerName |
        # if there's whitespace, wrap the name in quotes, otherwise just return the name.
        ForEach-Object { if($_.Name -match '\s'){ "'$($_.Name)'" } else { $_.Name } }
}

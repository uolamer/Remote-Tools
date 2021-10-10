<#
.SYNOPSIS
Start a service on a remote machine.
.EXAMPLE
Start-RemoteService -ComputerName Server01 -ServiceName Spooler -Timeout 90 -ProgressBar
Start the "Spooler" service on Server01 waiting up to 90 seconds for it to start.
Progress bar will be shown while waiting.
.EXAMPLE
Start-RemoteService -ComputerName Server01 -ServiceName Spooler -Timeout 10
Start the Spooler service on Server01 waiting up to 10 seconds for it to Start.
.EXAMPLE
Start-RemoteService -ComputerName Server01 -ServiceName Spooler -Timeout 0 -Quiet
Start the Spooler service on Server01 without waiting and supressing most output.
#>
function Start-RemoteService {
	[CmdletBinding()]
	Param(	
		# The name of the remote computer.
		[Parameter(Mandatory, Position = 0)][string]$ComputerName,
		# The name of the remote service.
		[Parameter(Mandatory, Position = 1)][string]$ServiceName,
		# Seconds (0-900) to wait for process to start in seconds. Defaults to 60 if not specified.
		[ValidateRange(0, 900)][Parameter(Position = 2)][int]$TimeOut = 60,
		# Option to show a progress bar while waiting
		[Parameter()][switch]$ProgressBar,
		# Option to supress output besides errors and warnings
		[Parameter()][switch]$Quiet
	)

	# Verify there is a PID for service, if not return
	$Service = Get-RemoteService $ComputerName $ServiceName
	if ($Service.State -eq 'Running') {
		# Supressing this warning with quiet for my use case.
		Write-Warning "Service ""$ServiceName"" is already Running on ""$ComputerName""."
		return $Service
	}
	
	# Send start service command to remote server.
	if (!$Quiet){Write-Output "Attempting to Start ""$ServiceName"" on ""$ComputerName""." }
	$null = $Service.startservice()


	# Wait up to the timeout for the service to start.
	if ($ProgressBar -and $TimeOut) {
		$Activity = "Starting ""$ServiceName"" on ""$ComputerName""."
		for($i = 0; $i -lt $TimeOut -and (Get-RemoteService $ComputerName $ServiceName).State -ne 'Running'; $i += 1){
			Write-Progress -Activity $Activity -PercentComplete ($i / $TimeOut * 100) -SecondsRemaining ($TimeOut - $i)
			Start-Sleep -Seconds 1
		}
		Write-Progress -Activity $Activity -Completed
	} elseif($TimeOut) {
		if (!$Quiet){Write-Output "Waiting up to ""$TimeOut"" seconds for ""$ServiceName"" to start on ""$ComputerName""..." }
		for($i = 0; $i -lt $TimeOut -and (Get-RemoteService $ComputerName $ServiceName).State -ne 'Running'; $i += 1){
			Start-Sleep -Seconds 1
		}
	}
    
    
	# Get current state of service for verification
	$Service = Get-RemoteService -ComputerName $ComputerName -ServiceName $ServiceName
	
	if ($Service.State -eq 'Start Pending') {
		# Decided that if you choose 0 timeout this is less of a warning as it happens often
		if ($timeout) {Write-Warning "Service ""$ServiceName"": ""$($Service.State)""."}
		elseif (!$Quiet){ Write-Output "Service ""$ServiceName"": ""$($Service.State)""." }
	} elseif ($Service.State -eq 'Running'){
		if (!$Quiet){ Write-Output "Service ""$ServiceName"": ""$($Service.State)""." }	
	} else {
		Write-Error "Service ""$ServiceName"": ""$($Service.State)""."
	}
	return $Service
}

# Tab-Completion for service names on the remote computer.
Register-ArgumentCompleter -CommandName Start-RemoteService -ParameterName ServiceName -ScriptBlock {
    PARAM($CommandName, $ParameterName, $WordToComplete, $CommandAst, $FakeBoundParameters)
    if(!$FakeBoundParameters.ContainsKey('ComputerName')){ return }
    $ComputerName = $FakeBoundParameters['ComputerName']
    Get-WmiObject -Query "select Name from Win32_Service where Name like '$WordToComplete%'" -ComputerName $ComputerName |
        # if there's whitespace, wrap the name in quotes, otherwise just return the name.
        ForEach-Object { if($_.Name -match '\s'){ "'$($_.Name)'" } else { $_.Name } }
}

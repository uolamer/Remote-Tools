<#
.SYNOPSIS
Restart a service on a remote machine.
.EXAMPLE
Restart-RemoteService -ComputerName Server01 -ServiceName spooler -TimeOutStop 55 -$TimeOutStart 66 -Wait 10 -StartProgressBar -StopProgressBar -Force -Verbose
Restart the "Spooler" service on Server01 waiting up to 55 seconds for it to stop, waiting 10 seconds before starting it, waiting 66 seconds for it to start
Showing progress bars for start and stop, force killing the PID of stop fails with verbose output
.EXAMPLE
Restart-RemoteService Server01 spooler
Restart the Spooler service on Server01. The default of 60 seconds will be used for timeouts for both stop and start with no wait or force
This example also demostrates the non requirement of -ComputerName and -ServiceName but these are positional.
#>
function Restart-RemoteService {
	[CmdletBinding()]
	Param(	
		# The name of the remote computer.
		[Parameter(Mandatory, Position = 0)][string]$ComputerName,
		# The name of the remote service.
		[Parameter(Mandatory, Position = 1)][string]$ServiceName,
		# Seconds (0-900) time to wait after stopping the service before starting in seconds. Default is 0.
		[ValidateRange(0, 900)][Parameter(Position = 2)][int]$Wait = 0,
		# Seconds (0-900) to wait for process to stop in seconds. Defaults to 60 if not specified.
		[ValidateRange(0, 900)][Parameter(Position = 3)][int]$TimeOutStop = 60,
		# Seconds (0-900) to wait for process to start in seconds. Defaults to 60 if not specified.
		[ValidateRange(0, 900)][Parameter(Position = 4)][int]$TimeOutStart = 60,
		# Option to show a progress bar while waiting to stop
		[Parameter()][switch]$StartProgressBar,
		# Option to show a progress bar while waiting to start
		[Parameter()][switch]$StopProgressBar,
		# Option to show a force kill process if needed
		[Parameter()][switch]$Force,
		# Supress non Warning and Errors
		[Parameter()][switch]$Quiet,
		# Use normal Start-Sleep vs Start-Timeout (needed for some scripts)
		[Parameter()][switch]$UseSleep
		
	)


	# Build Parameters for Stop-RemoteService
	$Parameters = @{
		ComputerName = $ComputerName
		ServiceName = $ServiceName
	    
	}
	if($PSBoundParameters.ContainsKey("StopProgressBar")){ $Parameters.ProgressBar = $StopProgressBar }
	if($PSBoundParameters.ContainsKey("TimeOutStop")){ $Parameters.TimeOut = $TimeOutStop }
	if($PSBoundParameters.ContainsKey("Force")){ $Parameters.Force = $Force }
	if($PSBoundParameters.ContainsKey("Quiet")){ $Parameters.Quiet = $Quiet }
	
	# Stop Remote Service
	Stop-RemoteService @Parameters 

	# If wait before starting service if requested
	if ($Wait -and $UseSleep) {
		Start-Sleep $Wait
	} elseif ($Wait -and $Quiet) {
		Start-Timeout -Timeout $Wait -Quiet
	} elseif ($Wait) {
		Start-Timeout -Timeout $Wait
	}
	
	# Build Parameters for Start-RemoteService
	$Parameters = @{
	    ServiceName = $ServiceName
	    ComputerName = $ComputerName
	}
	if($PSBoundParameters.ContainsKey("StartProgressBar")){ $Parameters.ProgressBar = $StopProgressBar }
	if($PSBoundParameters.ContainsKey("TimeOutStart")){ $Parameters.TimeOut = $TimeOutStart }
	if($PSBoundParameters.ContainsKey("Quiet")){ $Parameters.Quiet = $Quiet }
	
	# Start Remote Service
	Start-RemoteService @Parameters
	
}
# Tab-Completion for service names on the remote computer.
Register-ArgumentCompleter -CommandName Restart-RemoteService -ParameterName ServiceName -ScriptBlock {
    PARAM($CommandName, $ParameterName, $WordToComplete, $CommandAst, $FakeBoundParameters)
    if(!$FakeBoundParameters.ContainsKey('ComputerName')){ return }
    $ComputerName = $FakeBoundParameters['ComputerName']
    Get-WmiObject -Query "select Name from Win32_Service where Name like '$WordToComplete%'" -ComputerName $ComputerName |
        # if there's whitespace, wrap the name in quotes, otherwise just return the name.
        ForEach-Object { if($_.Name -match '\s'){ "'$($_.Name)'" } else { $_.Name } }
}

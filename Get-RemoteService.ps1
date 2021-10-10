<#
.SYNOPSIS
Get a service info from a remote machine.
.EXAMPLE
Get-RemoteService -ComputerName Server01 -ServiceName Spooler
Get the service info for Spooler on Server01
.OUTPUTS
ManagementObject with status and infomation for service
#>
function Get-RemoteService {
	Param(
		# The name of the computer.
		[Parameter(Mandatory, Position=0)][string]$ComputerName,
		# The name of the service.
		[Parameter(Mandatory, Position=1)][string]$ServiceName
	)
	$Service = get-wmiobject win32_service -ComputerName $ComputerName -Filter "Name = '$ServiceName'" -ErrorAction SilentlyContinue
	if (!$Service) {
		Write-Warning "Unable to get service info for $ServiceName on $ComputerName"
	}
	return $Service
}
# Tab-Completion for service names on the remote computer.
Register-ArgumentCompleter -CommandName Get-RemoteService -ParameterName ServiceName -ScriptBlock {
    PARAM($CommandName, $ParameterName, $WordToComplete, $CommandAst, $FakeBoundParameters)
    if(!$FakeBoundParameters.ContainsKey('ComputerName')){ return }
    $ComputerName = $FakeBoundParameters['ComputerName']
    Get-WmiObject -Query "select Name from Win32_Service where Name like '$WordToComplete%'" -ComputerName $ComputerName |
        # if there's whitespace, wrap the name in quotes, otherwise just return the name.
        ForEach-Object { if($_.Name -match '\s'){ "'$($_.Name)'" } else { $_.Name } }
}
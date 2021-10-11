# Remote-Tools
Powershell tools to make it easier to work with remote hosts and use in scripts for working with remote hosts with many options and flags to support many use cases.

## Current Tools
* Stop-RemoteService - Supports Force Killing the PID after a timeout, progressbar for that timeout, quiet mode for reduced output. This also can be used with 0 timeout to send the command and hope for the best mode. Inside a script this can be good for dealing with a large number of hosts.
* Start-RemoteService - Supports progressbar while waiting for service to start based on timeout, quiet mode for reduced output. Also supports the same 0 timeout use case as above.
* Restart-RemoteService - combines the stop, start and start-timeout commands while retaining all their options.
* Get-RemoteService - simple command used mainly to support the other commands with an option for keeping the service down for a set number of seconds.
* Start-Timeout - A native powershell replacement for timeout.exe. Basically a Start-Sleep where you can press q to skip the sleep if you want. Also supports a progressbar.

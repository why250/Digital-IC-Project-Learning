[CmdletBinding()]
param(
    [ValidateSet('sim', 'synth')]
    [string]$Action = 'sim',
    [string]$SshHost = 'IC_Server',
    [string]$RemoteDir = '/home/userone/AAAIC/test_tb/digital_ic_learning'
)
$ErrorActionPreference = 'Stop'
if ($SshHost -notmatch '^[A-Za-z0-9_.-]+$' -or
    $RemoteDir -notmatch '^/[A-Za-z0-9_./-]+$' -or $RemoteDir -match '(^|/)\.\.(/|$)') {
    throw 'Use a simple SSH alias and absolute remote directory.'
}
$script = if ($Action -eq 'sim') { 'run_sim.sh' } else { 'run_synth.sh' }
& ssh -T -o BatchMode=yes $SshHost "bash '$RemoteDir/lessons/01_spi_master/scripts/$script'"
if ($LASTEXITCODE -ne 0) { throw "Remote $Action failed with exit $LASTEXITCODE" }

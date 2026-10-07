[CmdletBinding()]
param(
    [string]$SshHost = 'IC_Server',
    [string]$RemoteDir = '/home/userone/AAAIC/test_tb/digital_ic_learning'
)
$ErrorActionPreference = 'Stop'
if ($SshHost -notmatch '^[A-Za-z0-9_.-]+$' -or
    $RemoteDir -notmatch '^/[A-Za-z0-9_./-]+$' -or $RemoteDir -match '(^|/)\.\.(/|$)') {
    throw 'Use a simple SSH alias and absolute remote directory.'
}
$projectDir = Split-Path $PSScriptRoot -Parent
Push-Location $projectDir
try {
    $allPaths = @(git ls-files --cached --others --exclude-standard)
    if ($LASTEXITCODE -ne 0) { throw 'Unable to list project files.' }
    # The frontend has its own Pages deployment and is not an EDA server input.
    $paths = @($allPaths | Where-Object { $_ -notlike 'web/*' })
    if ($paths.Count -eq 0) { throw 'Initialize Git before deployment.' }
    & ssh -T -o BatchMode=yes $SshHost "mkdir -p -- '$RemoteDir'"
    if ($LASTEXITCODE -ne 0) { throw 'Remote directory creation failed.' }
    foreach ($relative in $paths) {
        if ($relative -notmatch '^[A-Za-z0-9_./-]+$') { throw "Unsupported path: $relative" }
        $parent = Split-Path $relative -Parent
        $parent = $parent.Replace('\', '/')
        & ssh -T -o BatchMode=yes $SshHost "mkdir -p -- '$RemoteDir/$parent'"
        if ($LASTEXITCODE -ne 0) { throw "Remote parent creation failed: $relative" }
        & scp -o BatchMode=yes $relative "${SshHost}:$RemoteDir/$relative"
        if ($LASTEXITCODE -ne 0) { throw "scp failed: $relative" }
        $expected = (Get-FileHash -Algorithm SHA256 -LiteralPath $relative).Hash.ToLowerInvariant()
        $actual = & ssh -T -o BatchMode=yes $SshHost "sha256sum -- '$RemoteDir/$relative'"
        if ($LASTEXITCODE -ne 0 -or (($actual -split '\s+')[0] -ne $expected)) {
            throw "Transfer hash mismatch: $relative. Inspect before fallback."
        }
    }
    Write-Host "Verified deployment to ${SshHost}:$RemoteDir"
} finally { Pop-Location }

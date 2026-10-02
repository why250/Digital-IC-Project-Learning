[CmdletBinding()]
param(
    [string]$SshHost = 'IC_Server',
    [string]$RemoteDir = '/home/userone/AAAIC/test_tb/digital_ic_learning',
    [switch]$IncludeVcd
)
$ErrorActionPreference = 'Stop'
if ($SshHost -notmatch '^[A-Za-z0-9_.-]+$' -or
    $RemoteDir -notmatch '^/[A-Za-z0-9_./-]+$' -or $RemoteDir -match '(^|/)\.\.(/|$)') {
    throw 'Use a simple SSH alias and absolute remote directory.'
}
$projectDir = Split-Path $PSScriptRoot -Parent
$paths = @()
foreach ($divider in 1,3,25) {
    foreach ($name in 'sim.log','compile.log','spi_first_frame.svg') {
        $paths += "lessons/01_spi_master/results/sim/div$divider/$name"
    }
}
foreach ($name in 'area.rpt','gates.rpt','timing.rpt','timing_intent.rpt',
                   'design_check.rpt','mapped_design_check.rpt',
                   'mapped_timing_intent.rpt','mapped.v','mapped.sdc') {
    $paths += "lessons/01_spi_master/results/synth/$name"
}
if ($IncludeVcd) { $paths += 'lessons/01_spi_master/results/sim/div25/spi_master.vcd' }
foreach ($relative in $paths) {
    $localPath = Join-Path $projectDir $relative
    [System.IO.Directory]::CreateDirectory([System.IO.Path]::GetDirectoryName($localPath)) | Out-Null
    & scp -o BatchMode=yes "${SshHost}:$RemoteDir/$relative" $localPath
    if ($LASTEXITCODE -ne 0) { throw "Download failed: $relative" }
    $expected = & ssh -T -o BatchMode=yes $SshHost "sha256sum -- '$RemoteDir/$relative'"
    if ($LASTEXITCODE -ne 0) { throw "Remote hash failed: $relative" }
    $actual = (Get-FileHash -Algorithm SHA256 -LiteralPath $localPath).Hash.ToLowerInvariant()
    if (($expected -split '\s+')[0] -ne $actual) { throw "Download hash mismatch: $relative" }
}
Write-Host "Collected and hash-verified $($paths.Count) generated files."

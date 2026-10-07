[CmdletBinding()]
param([string]$SshHost='IC_Server', [switch]$IncludeVcd)
$ErrorActionPreference='Stop'
if ($SshHost -notmatch '^[A-Za-z0-9_.-]+$') { throw 'Use a simple SSH alias.' }
$taskRoot=Split-Path $PSScriptRoot -Parent
$taskLesson='lessons/adc_digital'
$taskRemote='/home/userone/AAAIC/test_tb/digital_ic_learning'
$taskPaths=@('results/models/experiments.json','results/models/models.log',
    'results/sim/architectures.log','results/sim/fixed.log','results/sim/fifo.log',
    'results/stream/spectrum.json','results/stream/verification.log','results/stream/sim.log',
    'results/stream/manifest.json','results/stream/stream.txt','results/stream/raw.txt','results/stream/coefficients.txt')
foreach ($taskCase in @('normal','random','missing','late','duplicate','wrong_lane','wrong_epoch',
    'wrong_id','sink','four_response','reset','reset_old','reset_request','reset_return',
    'reset_release','reset_correct','wrap_guard','version_guard')) {
    foreach ($taskName in @('sim.log','verification.log','verification.json','trace.txt')) {
        $taskPaths+="results/sim/ti_$taskCase/$taskName"
    }
}
foreach ($taskTop in @('sar_controller','flash_encoder','pipeline_align','dwa_encoder',
    'adc_fixed_correct','adc_async_fifo','ti_adc_backend')) {
    foreach ($taskName in @('mapped.v','mapped.sdc','area.rpt','gates.rpt','timing.rpt',
        'design_check.rpt','mapped_design_check.rpt','timing_intent.rpt','mapped_timing_intent.rpt','verification.json')) {
        $taskPaths+="results/synth/$taskTop/$taskName"
    }
}
if ($IncludeVcd) { $taskPaths+='results/sim/ti_normal/ti_adc.vcd' }
foreach ($taskPath in $taskPaths) {
    $taskRelative="$taskLesson/$taskPath"
    $taskDestination=Join-Path $taskRoot $taskRelative
    New-Item -ItemType Directory -Force -Path (Split-Path $taskDestination -Parent) | Out-Null
    & scp -o BatchMode=yes "${SshHost}:$taskRemote/$taskRelative" $taskDestination
    if ($LASTEXITCODE -ne 0) { throw "Collect failed: $taskRelative" }
    $taskExpected= & ssh -T -o BatchMode=yes $SshHost "sha256sum -- '$taskRemote/$taskRelative'"
    if ($LASTEXITCODE -ne 0) { throw "Remote hash failed: $taskRelative" }
    $taskActual=(Get-FileHash -Algorithm SHA256 -LiteralPath $taskDestination).Hash.ToLowerInvariant()
    if (($taskExpected -split '\s+')[0] -ne $taskActual) { throw "Hash mismatch: $taskRelative" }
}
Write-Output "ADC_RESULTS_COLLECTED_HASH_VERIFIED files=$($taskPaths.Count)"

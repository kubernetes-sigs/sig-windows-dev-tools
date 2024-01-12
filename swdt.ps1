Set-StrictMode -Version Latest

$SWDT_CLI_ROOT = './experiments/swdt'

Write-Host "[swdt.ps1] $args"

if (-not (Test-Path -Path 'go.work' -PathType Leaf)) {
  & go work init $SWDT_CLI_ROOT
}

$startTime = (Get-Date)
if ($args.Length -gt 0 -and $args[0] -eq 'test') {
  & go test -v $SWDT_CLI_ROOT/...
}
else {
  & go run -buildvcs=true $SWDT_CLI_ROOT/main.go $args | Out-Default
}
$runTime = (Get-Date) - $startTime

Write-Host ('[swdt.ps1] Run in {0:00}:{1:00}:{2:00} and exited with {3} code' `
    -f $runTime.Hours, $runTime.Minutes, $runTime.Seconds, $global:LASTEXITCODE)

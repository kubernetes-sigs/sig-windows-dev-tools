Write-Output "Checking for calico services ..."

Get-Service *ico*

Write-Output "Starting calico felix"

Start-Service -Name CalicoFelix
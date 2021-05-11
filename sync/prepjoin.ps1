if (Test-Path -Path C:\sync\kubejoin.ps1) {
    Remove-Item -Path C:\sync\kubejoin.ps1
}

$joinCommand = Get-Content C:\sync\join.txt
$joinCommand += "--cri-socket `"npipe:////./pipe/containerd-containerd`""

Set-Content C:\sync\kubejoin.ps1 -Value $joinCommand
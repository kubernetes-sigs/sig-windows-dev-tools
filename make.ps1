# Prepares and runs Kubernetes cluster on Windows host from PowerShell command line.
# This is supposed to offer euiqvalent functionality as the provided Makefile,
# but without requirement of GNU Make, that is, running the procedure from WSL.
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$script:startTime = (Get-Date)

#region Helper Fuctions
function script:Write-Log {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][string]$msg1
    )
    Begin {
        $savedForegroundColor = $host.UI.RawUI.ForegroundColor
        $timestamp = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')
    }
    Process {
        $host.UI.RawUI.ForegroundColor = 'DarkGreen'
        $scriptTag = (Split-Path -Path $PSCommandPath -Leaf)
        Write-Output ('{0} [{1}] {2}' -f $timestamp, $scriptTag, $msg1)
    }
    End {
        $host.UI.RawUI.ForegroundColor = $savedForegroundColor
    }
}

# Get-SettingsVaribale <setting property key>
function Get-SettingsVariable {
    $settingsFile = $env:VAGRANT_VARIABLES
    if (-not $settingsFile) {
        Write-Log 'WARNING: Environment variable VAGRANT_VARIABLES not defined'
        $settingsFile = Resolve-Path -Path '.\variables.yaml'
    }
    Get-Content -Path $settingsFile |
    Select-String -Pattern ('^{0}.*\:.+' -f $args[0]) |
    ForEach-Object { ($_ -Split ':').Trim().Trim('"') } |
    Select-Object -Last 1
}

function script:Set-PrivateKeyPermissions {
    Write-Log 'Fixing permissions of Vagrant SSH private keys'
    Get-ChildItem -Path (Get-Location) -Name 'private_key' -Recurse | ForEach-Object {
        New-Variable -Name Key -Value $_
        icacls $Key /c /t /Inheritance:d
        icacls $Key /c /t /Grant ${env:UserName}:F
        takeown /F $Key
        icacls $Key /c /t /Grant:r ${env:UserName}:F
        icacls $Key /c /t /Remove:g Administrator 'Authenticated Users' BUILTIN\Administrators BUILTIN Everyone System Users
        icacls $Key
        Remove-Variable -Name Key
    }
}

function script:Remove-VagrantEnv {
    Remove-Item -Path env:VAGRANT -ErrorAction SilentlyContinue
    Remove-Item -Path env:VAGRANT_VARIABLES -ErrorAction SilentlyContinue
}

function script:Set-VagrantEnv {
    script:Remove-VagrantEnv

    $v = (Get-Command -Name 'vagrant.exe' -ErrorAction Stop)
    Write-Log ('Running {0} from {1}' -f (& $v --version), $v.Source)

    # Select user-specific local variables, if present
    if (Test-Path -Path 'variables.local.yaml' -PathType Leaf) {
        $variablesFile = (Resolve-Path -Path 'variables.local.yaml')
    }
    else {
        $variablesFile = (Resolve-Path -Path 'variables.yaml' )
    }
    Set-Item -Path env:VAGRANT_VARIABLES -Value $variablesFile
    Write-Log "Setting Vagrant variables from $env:VAGRANT_VARIABLES"
}
#endregion Helper Fuctions

#region Command Functions
function script:Invoke-Clean {
    vagrant destroy --force
    @(
        '.\sync\linux\bin',
        '.\sync\windows\bin',
        '.\sync\shared\config',
        '.\sync\shared\kubeadm.yaml',
        '.\sync\shared\kubejoin.ps1',
        '.\sync\shared\variables.yaml',
        '.\.lock',
        '.\.vagrant'
    ) | ForEach-Object {
        if (Test-Path $_) {
            Write-Log "Cleaning $_"
            Remove-Item -Path "$_" -Recurse -Force
        }
    }
    Write-Log 'Log files have not been deleted, run: Remove-Item *.log'
}

function script:Invoke-Download {
    $kubernetesVersion = (Get-SettingsVariable 'kubernetes_version')
    Write-Log ('Downloading binaries of Kubernetes {0}' -f $kubernetesVersion)

    # This is only settings consistency check as this property does not really control the make.ps1 workflow.
    # That is becasue make.ps1 steps are invoked individually one-by-one (not like dependency-based Makefile targets).
    $buildFromSource = (Get-SettingsVariable 'build_from_source') -eq 'false' ? $false : $true
    if ($buildFromSource) {
        throw "Vagrant variables file declares 'build_from_source=true'. Modify the variable or run .\make.ps1 1-build-binaries instead."
    }

    Set-ExecutionPolicy Bypass -Scope Process -Force;
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072;
    $kubernetesVersion = (New-Object System.Net.WebClient).DownloadString(('https://storage.googleapis.com/k8s-release-dev/ci/latest-{0}.txt' -f $kubernetesVersion))
    $kubernetesTag = ($kubernetesVersion -split '+', 2, 'SimpleMatch' | Select-Object -First 1)
    $kubernetesSha = ($kubernetesVersion -split '+', 2, 'SimpleMatch' | Select-Object -Last 1)
    if (-not $kubernetesTag -or -not $kubernetesSha) {
        throw "Unknown Kubernetes tag and hash for version $kubernetesVersion"
    }
    Write-Log ('Downloading Kubernetes version {0}-{1} from upstream' -f $kubernetesTag, $kubernetesSha)
    
    $linuxBinDir = Join-Path -Path (Get-Location) -ChildPath '.\sync\Linux\bin'
    $windowsBinDir = Join-Path -Path (Get-Location) -ChildPath '.\sync\windows\bin'
    if (-not (Test-Path -Path $linuxBinDir -PathType Container)) {
        New-Item -Path $linuxBinDir -ItemType Directory -Force -ErrorAction Stop | Out-Null
    }
    if (-not (Test-Path -Path $windowsBinDir -PathType Container)) {
        New-Item -Path $windowsBinDir -ItemType Directory -Force -ErrorAction Stop | Out-Null
    }
    
    Set-ExecutionPolicy Bypass -Scope Process -Force;
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072;
    $webClient = New-Object System.Net.WebClient
    # Linux binaries
    @('kubeadm', 'kubectl', 'kubelet') | ForEach-Object {
        $bin = $_
        $url = ('https://storage.googleapis.com/k8s-release-dev/ci/{0}/bin/linux/amd64/{1}' -f $kubernetesVersion, $bin)
        Write-Log ('Downloading {0}' -f $url)
        $webClient.DownloadFile($url, (Join-Path -Path $linuxBinDir -ChildPath $bin))
        # NOTICE: controlplane.sh executes chmod +x
    }
    # Windows binaries
    @('kubeadm', 'kubelet', 'kube-proxy') | ForEach-Object {
        $bin = $_
        $url = ('https://storage.googleapis.com/k8s-release-dev/ci/{0}/bin/windows/amd64/{1}.exe' -f $kubernetesVersion, $bin)
        Write-Log ('Downloading {0}' -f $url)
        $webClient.DownloadFile($url, (Join-Path -Path $windowsBinDir -ChildPath ('{0}.exe' -f $bin)))
    }
}

function script:Invoke-Build {
    $kubernetesVersion = (Get-SettingsVariable 'kubernetes_version')
    Write-Log ('Building Kubernetes {0} from source' -f $kubernetesVersion)

    # This is only settings consistency check as this property does not really control the make.ps1 workflow.
    # That is becasue make.ps1 steps are invoked individually one-by-one (not like dependency-based Makefile targets).
    $buildFromSource = (Get-SettingsVariable 'build_from_source') -eq 'false' ? $false : $true
    if (-not $buildFromSource) {
        throw "Vagrant variables file declares 'build_from_source=false'. Modify the variable or run .\make.ps1 0-fetch-k8s instead."
    }

    throw "TODO: Building Kubernetes from sources on Windows host without make is not implemented yet"
}

function script:Invoke-Run {
    Write-Log 'Creating .\.lock directory'
    if (Test-Path '.\.lock') {
        Remove-Item -Path '.\.lock' -Recurse -Force | Out-Null
    }
    New-Item -Path '.\.lock' -ItemType Directory -Force | Out-Null
    Write-Log 'Creating .\sync\shared\kubejoin.ps1 mock file to keep Vagrantfile happy'
    New-Item -Path '.\sync\shared\kubejoin.ps1' -ItemType File -Force | Out-Null

    ###### Linux node
    Write-Log 'vagrant up controlplane'
    vagrant up controlplane
    if ($LASTEXITCODE -ne 0) { throw 'Vagrant error' }

    Write-Log 'vagrant status'
    vagrant status

    ###### Windows node
    $count = 1
    while ($true) {
        $vagrantStatus = $(vagrant status winw1 | Select-String -Pattern 'winw1' | ForEach-Object { $_ -split '\s{2,}' } | Select-Object -Last 1)
        Write-Log ('vagrant status winw1 - attempt {0} - status: {1}' -f $count, $vagrantStatus)
        if ($vagrantStatus -match 'running') {
            break
        }
        Write-Log ('vagrant up winw1 - attempt {0}' -f $count)
        vagrant up winw1
        $count += 1
    }

    # Correct SSH key files permissions, otherwise vagrant ssh will keep prompting
    # for password what defeats the non-interactive purpose of the whole procedure.
    Set-PrivateKeyPermissions

    $count = 1
    while ($true) {
        Write-Log ('kubectl get nodes | grep winw1 - attempt {0}' -f $count)
        if (vagrant ssh controlplane -c 'kubectl get nodes' | Select-String -SimpleMatch 'winw1') {
            break
        }
        Write-Log ('vagrant provision winw1 - attempt {0}' -f $count)
        vagrant provision winw1
        $count += 1
    }

    Write-Log 'Creating .\.lock\joined indicator for Vagrantfile'
    New-Item -Path '.\.lock\joined' -ItemType File -Force
    Write-Log ('vagrant provision winw1 - attempt {0}' -f $count)
    vagrant provision winw1

    Write-Log 'Creating .\.lock\cni indicator for Vagrantfile'
    New-Item -Path '.\.lock\cni' -ItemType File -Force

    Write-Log 'Cluster created'
    vagrant status
    vagrant ssh controlplane -c 'kubectl get nodes'
}

function script:Invoke-Status {
    Write-Log 'vagrant status'
    vagrant status
    
    Write-Log 'kubectl get nodes'
    vagrant ssh controlplane -c 'kubectl get nodes'
}

function script:Invoke-SmokeTest {
    Write-Log 'kubectl apply -f /var/sync/linux/smoke-test.yaml'
    vagrant ssh controlplane -c 'kubectl apply -f /var/sync/linux/smoke-test.yaml'
    Write-Log 'kubectl scale deployment whoami-windows --replicas 0'
    vagrant ssh controlplane -c 'kubectl scale deployment whoami-windows --replicas 0'
    Write-Log 'kubectl scale deployment whoami-windows --replicas 3'
    vagrant ssh controlplane -c 'kubectl scale deployment whoami-windows --replicas 3'
    vagrant ssh controlplane -c "kubectl wait --for=condition=Ready=true pod -l 'app=whoami-windows' --timeout=600s"
    Write-Log 'kubectl exec -it netshoot -- curl http://whoami-windows:80/'
    vagrant ssh controlplane -c 'kubectl exec -it netshoot -- curl http://whoami-windows:80/'
}

function script:Invoke-EndToEndTest {
    Write-Log 'Executing e2e.sh on controlplane'
    vagrant ssh controlplane -c "cd /var/sync/linux && chmod +x ./e2e.sh && ./e2e.sh"
}
#endregion Command Functions

#region Main Script
$commands = @{
    '0-fetch-k8s'      = 'Download Kubernetes binaries for Linux and Windows (set version in variables.yaml or variables.local.yaml)';
    '1-build-binaries' = 'Optionally, build Kubernetes from sources for Linux and Windows';
    '2-vagrant-up'     = 'Create and run two-node cluster';
    '3-smoke-test'     = 'Run smoke tests';
    '4-e2e-test'       = 'Run end-to-end tests';
    'status'           = 'Check state of Vagrant machines and Kubernetes nodes';
    'clean'            = 'Start fresh destroying any existing Vagrant machines';
    'help'             = 'Print this message';
}

if ($args.Count -eq 0 -or $commands.Keys -notcontains $args[0] -or $args[0] -contains 'help') {
    Write-Host 'Usage: .\make.ps1 <command>'
    Write-Host "`nRun commands one by one in the following order:"
    $commands.GetEnumerator() | Sort-Object -Property Name | Format-Table -HideTableHeaders -AutoSize
    Write-Host "`nDefault settings are defined in variables.yaml file."
    Write-Host "To tweak the defaults, make a copy as variables.local.yaml and edit.`n"
    exit
}

$command = $args[0]
Write-Log "Invoking command: $command"

script:Set-VagrantEnv

if ($command -eq 'clean') {
    script:Invoke-Clean
}
elseif ($command -eq 'status') {
    script:Invoke-Status
}
else {
    $logTime = (Get-Date -Date $script:startTime -UFormat '%Y%m%d%H%M%S')
    $logFile = (Join-Path -Path (Get-Location) -ChildPath ('make-{0}-{1}.log' -f $command, $logTime))
    Write-Log "Saving command output to $logFile"
    
    if ($command -eq '0-fetch-k8s') {
        script:Invoke-Download | Tee-Object -FilePath $logFile
    }
    elseif ($command -eq '1-build-binaries') {
        script:Invoke-Build | Tee-Object -FilePath $logFile
    }
    elseif ($command -eq '2-vagrant-up') {
        script:Invoke-Run | Tee-Object -FilePath $logFile
    }
    elseif ($command -eq '3-smoke-test') {
        script:Invoke-SmokeTest | Tee-Object -FilePath $logFile
    }
    elseif ($command -eq '4-e2e-test') {
        script:Invoke-EndToEndTest | Tee-Object -FilePath $logFile
    }
}

script:Remove-VagrantEnv

Write-Log ('Finished in {0:N2} minutes' -f ((Get-Date) - $startTime).TotalMinutes)
#endregion Main Script

# Testing SWDT CLI for Windows node on Windows host

This is a very early guide with step-by-step instructions for those who
want to try and test the SWDT CLI on Windows host targeting Windows VM
using PowerShell in order to set it up and join as Kubernetes cluster node,
that is, as SWDT CLI is being completed with new features.

> *IMPORTANT*:
> Run the presented PowerShell commands one by one in order as their are presented.
> If any command fails for you, please, report it.

## Prerequisites

- Windows host
- PowerShell 7 > Run as Administrator
- Downloaded [Windows Server 2022 VHD](https://www.microsoft.com/en-us/evalcenter/download-windows-server-2022)

## 1. Preparation

Check PowerShell on Windows host runs as Administrator:

```powershell
(New-Object Security.Principal.WindowsPrincipal $([Security.Principal.WindowsIdentity]::GetCurrent())).IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)
```

Enable Hyper-V on Windows host:

```powershell
Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V -All
```

## 2. Generate SSH key

Generate SSH key to be deployed to Windows VM for convenient password-less SSH communication:

```powershell
ssh-keygen -f .\experiments\swdt\samples\mloskot\ssh.id_rsa
```

and fix the private key file permissions:

```powershell
New-Variable -Name sshKey -Value ".\experiments\swdt\samples\mloskot\ssh.id_rsa"
icacls $sshKey /c /t /Inheritance:d
icacls $sshKey /c /t /Grant ${env:UserName}:F
takeown /F $sshKey
icacls $sshKey /c /t /Grant:r ${env:UserName}:F
icacls $sshKey /c /t /Remove:g Administrator "Authenticated Users" BUILTIN\Administrators BUILTIN Everyone System Users
Remove-Variable -Name sshKey
```

> *IMPORTANT:* The location of the SSH private key, relative to the project repository root folder,
is already present in the [winworker.yaml](winworker.yaml) configuration file.

## 3. Create Hyper-V NAT network

Run the following PowerShell commands on Windows host as Administrator.

Windows currently [allows to set up only one NAT network per host](https://learn.microsoft.com/en-us/virtualization/hyper-v-on-windows/user-guide/setup-nat-network),
hence a generic non-SWDT specific name is picked below:

```powershell
New-VMSwitch -SwitchName 'ClusterNatSwitch' -SwitchType Internal -Notes 'Virtual Switch with NAT used for networking between nodes of hybrid Kubernets cluster, with Internet access.'
```

```powershell
New-NetIPAddress -IPAddress 192.168.10.1 -PrefixLength 24 -InterfaceAlias 'vEthernet (ClusterNatSwitch)'
```

```powershell
New-NetNAT -Name 'ClusterNatNetwork' -InternalIPInterfaceAddressPrefix 192.168.10.0/24
```

```powershell
Add-Content -Path "$($Env:WinDir)\system32\Drivers\etc\hosts" -Value '192.168.10.1 gateway.cluster   gateway     # ClusterNatSwitch IP'
Add-Content -Path "$($Env:WinDir)\system32\Drivers\etc\hosts" -Value '192.168.10.2 master.cluster    master      # Kubernetes Linux node (control-plane)'
Add-Content -Path "$($Env:WinDir)\system32\Drivers\etc\hosts" -Value '192.168.10.3 winworker.cluster winworker   # Kubernetes Windows node'
```

## 4. Create Windows VM

The VHD requires VM generation 1, does not boot for VM generation 2.
Using the official Windows Server VHD to avoid walk through the manual
process of Windows installation from ISO. It will require to complete
initial configuration interactively (i.e. language and keyboard selection,
setting password for Administrator user - use `K8s@windows` as reasonable default).

```powershell
$vmName = 'winworker'
```

```powershell
$vmConfigPath = New-Item -Path ".\experiments\swdt\samples\mloskot" -Name $vmName -ItemType Directory -Force;
$vmVhdPath = Join-Path -Path $vmConfigPath -ChildPath 'os.vhdx';
Convert-VHD -Path "$($Env:UserProfile)\Downloads\20348.169.amd64fre.fe_release_svc_refresh.210806-2348_server_serverdatacentereval_en-us.vhd" -DestinationPath $vmVhdPath;
```

```powershell
New-VM -Name $vmName -Generation 1 -Switch 'ClusterNatSwitch' -Path $vmConfigPath;
Add-VMHardDiskDrive -VMName $vmName -Path $vmVhdPath -ControllerType IDE -ControllerNumber 0 -ControllerLocation 1;
Set-VMBios -VMName $vmName -StartupOrder @("IDE", "Floppy", "LegacyNetworkAdapter", "CD")
Set-VMMemory -VMName $vmName -DynamicMemoryEnabled $true -MinimumBytes 2GB -StartupBytes 4GB -MaximumBytes 8GB;
Set-VMProcessor -VMName $vmName -Count 2;
Set-VMProcessor -VMName $vmName -ExposeVirtualizationExtensions $true;
Get-VMNetworkAdapter -VMName $vmName | Connect-VMNetworkAdapter -SwitchName 'ClusterNatSwitch';
Get-VMNetworkAdapter -VMName $vmName | Set-VMNetworkAdapter -MacAddressSpoofing On;
Start-VM -Name $vmName;
vmconnect.exe $env:ComputerName $vmName;
```

The VM should start and Windows boot displaying `Hi there` screen where the initial configuration needs to be completed interactively:

1. Select region, language and keyboard layout.
2. Accept the licence terms.
3. Set the `Administrator` password, here are reasonable defaults:

    ```powershell
    $vmAdminUsername = "Administrator";
    $vmAdminPassword = "K8s@windows";
    ```

## 5. Configure Windows VM

The following PowerShell Direct commands are executed directly on the Windows VM.

*TODO(mloskot):* Run those commands from within dedicated SWDT CLI command.

```powershell
$vmAdminUsername = "Administrator";
$vmAdminPassword = "K8s@windows";
$vmAdminPasswordSecure = New-Object -TypeName System.Security.SecureString;
$vmAdminPassword.ToCharArray() | ForEach-Object { $vmAdminPasswordSecure.AppendChar($_) };
$vmAdminCredential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $vmAdminUsername, $vmAdminPasswordSecure;
```

```powershell
Invoke-Command -VMName $vmName -Credential $vmAdminCredential -ScriptBlock {
  Rename-Computer -NewName 'winworker'; # cannot access variable from outside script block
  New-NetIPAddress -IPAddress 192.168.10.3 -PrefixLength 24 -InterfaceAlias "Ethernet" -DefaultGateway 192.168.10.1;
  Set-DnsClientServerAddress -ServerAddresses 1.1.1.1,8.8.8.8 -InterfaceAlias "Ethernet";
}
```

> *NOTE:* The Windows VM IP address is already present in the [winworker.yaml](winworker.yaml) configuration file.

[Configure Windows Firewall](https://learn.microsoft.com/en-us/windows/security/operating-system-security/network-security/windows-firewall/configure-with-command-line?tabs=powershell)
to allow all traffic from Linux nodes, including ICMP - Lazy way:

```powershell
Invoke-Command -VMName $vmName -Credential $vmAdminCredential -ScriptBlock {
  Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled False;
}
```

Restart VM:

```powershell
Invoke-Command -VMName $vmName -Credential $vmAdminCredential -ScriptBlock {
  Restart-Computer  -Force;
}
```

Since, currently, SWDT CLI executes commands on remote host via SSH,
it is a good idea to [set up SSH on Windows VM](https://learn.microsoft.com/en-us/windows-server/administration/openssh/openssh_install_firstuse?tabs=powershell),
with key based authentication in the next steps:

```powershell
Invoke-Command -VMName $vmName -Credential $vmAdminCredential -ScriptBlock {
  $ProgressPreference = 'SilentlyContinue';
  Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0;
  Set-Service -Name sshd -StartupType 'Automatic';
  Start-Service sshd;
}
```

Fix broken configuration of SSH on Windows:

- <https://stackoverflow.com/a/77705199/151641>
- <https://github.com/PowerShell/Win32-OpenSSH/issues/1942#issuecomment-1868015179>

```powershell
Invoke-Command -VMName $vmName -Credential $vmAdminCredential -ScriptBlock {
  $content = Get-Content -Path $env:ProgramData\ssh\sshd_config;
  $content = $content -replace '.*Match Group administrators.*', '';
  $content = $content -replace '.*AuthorizedKeysFile.*__PROGRAMDATA__.*', '';
  Set-Content -Path $env:ProgramData\ssh\sshd_config -Value $content;
}
```

Use SSH to [deploy the public key](https://learn.microsoft.com/en-us/windows-server/administration/openssh/openssh_keymanagement#deploying-the-public-key) to Windows VM:

```powershell
ssh-keygen -R winworker;
$publicKey = Get-Content -Path '.\experiments\swdt\samples\mloskot\ssh.id_rsa.pub';
$remoteCmd = "powershell New-Item -Force -ItemType Directory -Path C:\Users\Administrator\.ssh; Add-Content -Force -Path C:\Users\Administrator\.ssh\authorized_keys -Value '$publicKey'; icacls.exe ""C:\Users\Administrator\.ssh\authorized_keys "" /inheritance:r /grant ""Administrators:F"" /grant ""SYSTEM:F""; Restart-Service sshd;";
ssh Administrator@winworker $remoteCmd
```

Test SSH authentication using the private key - no password prompt is expected:

```powershell
ssh -i '.\experiments\swdt\samples\mloskot\ssh.id_rsa' Administrator@winworker
```

## 6. Set up Windows node

```powershell
.\swdt.ps1 setup --config .\experiments\swdt\samples\mloskot\winworker.yaml
```

Assuming successful completion of the command above the Windows node
should now be provision with Chocolatey and some general purpose utilities.

Try it:

```powershell
ssh -i '.\experiments\swdt\samples\mloskot\ssh.id_rsa' Administrator@winworker "C:\ProgramData\chocolatey\bin\choco.exe --version"
```

*TODO(mloskot):* Keep this guide up to date as new SWDT CLI features are implemented

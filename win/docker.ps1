$ProgressPreference = 'SilentlyContinue'

Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201

Install-Module -Name DockerMsftProvider -Force

Install-Package Docker -Providername DockerMsftProvider -Force

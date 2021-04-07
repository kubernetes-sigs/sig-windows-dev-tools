run:
	rm ./win/config -f
	vagrant up
	
	cp ./master/config ./win/config

	vagrant winrm -c "Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force" winw1
	vagrant winrm -c "Install-Module -Name DockerMsftProvider -Force" winw1
	vagrant winrm -c "Install-Package Docker -Providername DockerMsftProvider -Force" winw1
	vagrant winrm -c "Restart-Computer" winw1

	vagrant winrm -c "Start-Service docker" winw1
	vagrant winrm -c "docker image pull mcr.microsoft.com/windows/nanoserver:1809" winw1
	vagrant winrm -c "docker image tag mcr.microsoft.com/windows/nanoserver:1809 microsoft/nanoserver:latest" winw1

#	vagrant winrm -c "powershell 'C:\sync\k.ps1'" winw1
	
plugins:
	vagrant plugin install vagrant-reload

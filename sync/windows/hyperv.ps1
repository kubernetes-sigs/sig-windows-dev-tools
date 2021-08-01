<#
Copyright 2021 The Kubernetes Authors.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
#>
Write-Output "#########################"
Write-Output "STARTING with 'hyperv.ps1'"

$ProgressPreference = 'SilentlyContinue'

Write-Output "### Installing Nuget"
Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201  -Force

Write-Output "### Using dism: enabling Hyper-V, so that we can use the HNS APIs"
Write-Output "### Using dism: SHOULD WE BE DISABLING THE HYPERVISOR ???"

dism -online -enable-feature -featurename:Microsoft-Hyper-V -all -NoRestart

Write-Output "### Installing Containers"
Install-WindowsFeature Containers

Write-Output "DONE with 'hyperv.ps1'"
Write-Output "#########################"
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

Param($task)

function DrawLine {
    Write-Information "######################################"
}

function Test {
    vagrant.exe ssh controlplane -c "kubectl scale deployment whoami-windows --replicas 0"
	vagrant.exe ssh controlplane -c "kubectl scale deployment whoami-windows --replicas 3"
	vagrant.exe ssh controlplane -c "kubectl get pods; sleep 5"
	vagrant.exe ssh controlplane -c "kubectl exec -it netshoot -- curl http://whoami-windows:80/"
}

function Up {
    Write-Output  "cleaning up semaphores..."
    foreach ($semaphore in ("up", "joined", "cni")) {
        if (Test-Path $semaphore) {
            Remove-Item $semaphore -Force
        }
    }

    Write-Output "installing vagrant vbguest plugin..."
	vagrant.exe plugin install vagrant-vbgues

    DrawLine
    Write-Output "Retry vagrant up if the first time the windows node failed"
	Write-Output "Starting the control plane"
    DrawLine
    vagrant.exe up controlplane
    
    DrawLine
    Write-Output "vagrant up first run done, ENTERING WINDOWS BRINGUP LOOP"
    while (vagrant.exe status | Select-String -Pattern winw1 | Select-String -Pattern "running" -Quiet -NotMatch) {
        vagrant.exe up winw1
    }
    New-Item -ItemType file joined    
    
    while (vagrant.exe ssh controlplane -c "kubectl get nodes" | Select-String -Pattern "winw1" -Quiet -NotMatch) {
        vagrant.exe provision winw1
    }
    New-Item -ItemType file joined
    
	vagrant.exe provision winw1
    New-Item -ItemType file cni
}

switch ($task)
{
    "up"    {Up}
    "2"     {Up}
    "test"  {Test}
    "3"     {Test}
}
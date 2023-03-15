# Copyright 2021 The Kubernetes Authors.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

VAGRANT?="vagrant"
PROVIDER?="qemu"

.SILENT: clean

all: 0-fetch-k8s 1-build-binaries 2-vagrant-up 3-smoke-test 4-e2e-test

0: 0-fetch-k8s
1: 1-build-binaries
2: 2-vagrant-up
3: 3-smoke-test
4: 4-e2e-test

0-fetch-k8s: clean
	@echo "clean"
	@chmod +x fetch.sh
	@./fetch.sh

1-build-binaries:
	@echo "build"
	@chmod +x build.sh
	@./build.sh $(PWD)/kubernetes

2-vagrant-up:
	@echo "vagrant phase"
	@rm -rf .lock/
	@mkdir -p .lock/
	@echo "making mock kubejoin file to keep Vagrantfile happy in sync/shared"
	@touch ./sync/shared/kubejoin.ps1
	@echo "######################################"
	@echo "Retry vagrant up if the first time the windows node failed"
	@echo "Starting the control plane"
	@echo "######################################"
	@$(VAGRANT) up --provider=$(PROVIDER) controlplane
	
	@echo "*********** vagrant up first run done ~~~~ ENTERING WINDOWS BRINGUP LOOP ***"
	@until `$(VAGRANT) status | grep winw1 | grep -q "running"` ; do $(VAGRANT) up winw1 --provider=$(PROVIDER) || echo failed_win_up ; done
	@until `$(VAGRANT) ssh controlplane -c "kubectl get nodes" | grep -q winw1` ; do $(VAGRANT) provision winw1 || echo failed_win_join; done
	@touch .lock/joined
	@$(VAGRANT) provision winw1
	@touch .lock/cni

3-smoke-test:
	@$(VAGRANT) ssh controlplane -c "kubectl apply -f /var/sync/linux/smoke-test.yaml"
	@$(VAGRANT) ssh controlplane -c "kubectl scale deployment whoami-windows --replicas 0"
	@$(VAGRANT) ssh controlplane -c "kubectl scale deployment whoami-windows --replicas 3"
	@$(VAGRANT) ssh controlplane -c "kubectl wait --for=condition=Ready=true pod -l 'app=whoami-windows' --timeout=600s"
	@$(VAGRANT) ssh controlplane -c "kubectl exec -it netshoot -- curl http://whoami-windows:80/"

4-e2e-test:
	@$(VAGRANT) ssh controlplane -c "cd /var/sync/linux && chmod +x ./e2e.sh && ./e2e.sh"

clean:
	@touch sync/shared/kubejoin.ps1
	$(VAGRANT) destroy --force
	rm -rf sync/linux/bin/
	rm -rf sync/windows/bin/
	rm -f sync/shared/config
	rm -f sync/shared/kubeadm.yaml
	rm -f sync/shared/kubejoin.ps1
	rm -rf .lock/

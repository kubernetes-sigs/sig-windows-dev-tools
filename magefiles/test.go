//go:build mage
// +build mage

package main

import (
	"log"

	"github.com/magefile/mage/mg"
	"github.com/magefile/mage/sh"
)

type Test mg.Namespace

// Run smoke tests.
func (Test) Smoke() error {
	mg.SerialDeps(startup, checkVagrant)

	var err error

	log.Printf("kubectl apply -f /var/sync/linux/smoke-test.yaml")
	err = sh.Run("vagrant", "ssh", "controlplane", "-c", "kubectl apply -f /var/sync/linux/smoke-test.yaml")
	if err != nil {
		return err
	}

	log.Printf("kubectl scale deployment whoami-windows --replicas 0")
	err = sh.Run("vagrant", "ssh", "controlplane", "-c", "kubectl scale deployment whoami-windows --replicas 0")
	if err != nil {
		return err
	}

	log.Printf("kubectl scale deployment whoami-windows --replicas 3")
	err = sh.Run("vagrant", "ssh", "controlplane", "-c", "kubectl scale deployment whoami-windows --replicas 3")
	if err != nil {
		return err
	}
	err = sh.Run("vagrant", "ssh", "controlplane", "-c", "kubectl wait --for=condition=Ready=true pod -l 'app=whoami-windows' --timeout=600s")
	if err != nil {
		return err
	}

	log.Printf("kubectl exec -it netshoot -- curl http://whoami-windows:80/")
	err = sh.Run("vagrant", "ssh", "controlplane", "-c", "kubectl exec -it netshoot -- curl http://whoami-windows:80/")
	if err != nil {
		return err
	}

	return nil
}

// Run end-to-end tests.
func (Test) EndToEnd() error {
	mg.SerialDeps(startup, checkVagrant)

	log.Printf("Running ./e2e.sh on controlplane")
	err := sh.Run("vagrant", "ssh", "controlplane", "-c", "cd /var/sync/linux && chmod +x ./e2e.sh && ./e2e.sh")
	if err != nil {
		return err
	}
	return nil
}

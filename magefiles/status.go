//go:build mage
// +build mage

package main

import (
	"log"

	"github.com/magefile/mage/mg"
	"github.com/magefile/mage/sh"
)

// Check state of Vagrant machines and Kubernetes nodes.
func Status() error {
	mg.SerialDeps(startup, checkVagrant)

	var err error

	log.Println("vagrant status winw1")
	err = sh.Run("vagrant", "status", "winw1")
	if err != nil {
		panic(err)
	}

	log.Println("kubectl get nodes")
	err = sh.Run("vagrant", "ssh", "controlplane", "-c", "kubectl get nodes")
	if err != nil {
		return err
	}

	logTargetRunTime("Status")
	return nil
}

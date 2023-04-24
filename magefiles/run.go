//go:build mage
// +build mage

package main

import (
	"fmt"
	"log"
	"os"
	"path/filepath"
	"regexp"
	"runtime"
	"strings"

	"github.com/magefile/mage/mg"
	"github.com/magefile/mage/sh"
)

// Create and run Kubernetes cluster with two nodes, Linux and Windows.
func Run() error {
	mg.SerialDeps(startup, checkVagrant)

	var err error

	log.Println("Creating .lock directory")
	_, err = os.Stat(".lock")
	if !os.IsNotExist(err) {
		err = os.RemoveAll(".lock")
		if err != nil {
			return err
		}
	}
	err = os.Mkdir(".lock", os.ModePerm)
	if err != nil {
		return err
	}

	// Linux node //////////////////////////////////////////////////////////////
	kubeJoinMockFile := filepath.Join("sync", "shared", "kubejoin.ps1")
	log.Printf("Creating %s mock file to keep Vagrantfile happy", kubeJoinMockFile)
	mustTouchFile(kubeJoinMockFile)

	log.Println("Creating control plane Linux node")
	err = sh.Run("vagrant", "up", "controlplane")
	if err != nil {
		return err
	}

	mustSetVagrantPrivateKeyPermissions()

	err = sh.Run("vagrant", "status")
	if err != nil {
		return err
	}

	// Windows node ////////////////////////////////////////////////////////////
	log.Println("Creating worker Windows node")
	log.Println("##########################################################")
	log.Println("Retry vagrant up if the first time the Windows node failed")
	log.Println("##########################################################")

	const maxAttempts = 10 // TODO: How many to allow? Make configurable via variables.yaml?
	for i := 1; i < maxAttempts; i++ {
		log.Printf("vagrant status winw1 - attempt %d of %d", i, maxAttempts)
		output, err := sh.Output("vagrant", "status", "winw1")
		if err != nil {
			return err
		}
		status := extractMachineStatus(output, "winw1")
		log.Println("winw1", status)
		if strings.Contains(status, "running") {
			break
		}
		log.Printf("vagrant up winw1 - attempt %d of %d", i, maxAttempts)
		err = sh.Run("vagrant", "up", "winw1")
		if err != nil {
			return err
		}
	}

	mustSetVagrantPrivateKeyPermissions()

	for i := 1; i < maxAttempts; i++ {
		log.Printf("kubectl get nodes | grep winw1  - attempt %d of %d", i, maxAttempts)
		output, err := sh.Output("vagrant", "ssh", "controlplane", "-c", "kubectl get nodes")
		if err != nil {
			return err
		}
		if strings.Contains(output, "winw1") {
			break
		}
		log.Printf("vagrant provision winw1 - attempt %d of %d", i, maxAttempts)
		err = sh.Run("vagrant", "provision", "winw1")
		if err != nil {
			return err
		}
	}

	// Cluster status //////////////////////////////////////////////////////////
	joinedFile := filepath.Join(".lock", "joined")
	log.Printf("Creating %s indicator file for Vagrantfile", joinedFile)
	mustTouchFile(joinedFile)

	cniFile := filepath.Join(".lock", "cni")
	log.Printf("Creating %s indicator file for Vagrantfile", cniFile)
	mustTouchFile(cniFile)

	log.Println("Cluster created")
	err = sh.Run("vagrant", "status")
	if err != nil {
		return err
	}
	err = sh.Run("vagrant", "ssh", "controlplane", "-c", "kubectl get nodes")
	if err != nil {
		return err
	}

	logTargetRunTime("Run")
	return nil
}

func extractMachineStatus(statusOutput string, machineName string) string {
	r := fmt.Sprintf(`(?m)^%s.*`, machineName)
	m := regexp.MustCompile(r)
	s := m.FindString(statusOutput)
	v := strings.Split(s, machineName)
	return strings.TrimSpace(v[1])
}

func mustTouchFile(filePath string) {
	file, err := os.OpenFile(filePath, os.O_CREATE|os.O_RDWR|os.O_TRUNC, 644)
	if err != nil {
		panic(err)
	}
	err = file.Close()
	if err != nil {
		panic(err)
	}
}

func mustSetVagrantPrivateKeyPermissions() {
	var keyFiles = [...]string{
		filepath.Join(".vagrant", "machines", "controlplane", "virtualbox", "private_key"),
		filepath.Join(".vagrant", "machines", "winw1", "virtualbox", "private_key"),
	}

	for _, keyFile := range keyFiles {
		_, err := os.Stat(filepath.Clean(keyFile))
		if os.IsNotExist(err) {
			continue // key file may not be created yet, skip for now
		}
		log.Printf("Setting SSH private key permissions for %s", keyFile)
		if runtime.GOOS != "windows" {
			err = os.Chmod(keyFile, 600)
			if err != nil {
				panic(err)
			}
		} else {
			err = sh.Run("icacls", keyFile, "/c", "/t", "/Inheritance:d")
			if err != nil {
				panic(err)
			}
			err = sh.Run("icacls", keyFile, "/c", "/t", "/Inheritance:d")
			if err != nil {
				panic(err)
			}
			user := fmt.Sprintf("%s:F", os.Getenv("USERNAME"))
			err = sh.Run("icacls", keyFile, "/c", "/t", "/Grant", user)
			if err != nil {
				panic(err)
			}
			err = sh.Run("icacls", keyFile, "/c", "/t", "/Grant:r", user)
			if err != nil {
				panic(err)
			}
			err = sh.Run("icacls", keyFile, "/c", "/t", "/Remove:g", "Administrator", "Authenticated Users", "BUILTIN\\Administrators", "BUILTIN", "Everyone", "System", "Users")
			if err != nil {
				panic(err)
			}
			err = sh.Run("icacls", keyFile)
			if err != nil {
				panic(err)
			}
		}
	}
}

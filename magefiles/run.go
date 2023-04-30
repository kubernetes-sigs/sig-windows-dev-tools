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

// Create and run Kubernetes cluster with Linux (control plane) and Windows (worker) nodes.
func Run() error {
	mg.SerialDeps(startup, checkClusterNotExist, Config.Settings, Config.Vagrant, preRun, runLinuxControlPlaneNode, runWindowsWorkerNode, postRun, Status)

	logTargetRunTime("Run")
	return nil
}

func runLinuxControlPlaneNode() error {
	var err error

	log.Println("Creating Linux control plane node")
	err = sh.Run("vagrant", "up", "controlplane")
	if err != nil {
		return err
	}

	err = setVagrantPrivateKeyPermissions()
	if err != nil {
		return err
	}

	log.Println("Checking status of Linux control plane node")
	err = sh.Run("vagrant", "status")
	if err != nil {
		return err
	}

	log.Println("Linux control plane node created")
	return nil
}

func runWindowsWorkerNode() error {

	log.Println("Creating Windows worker node")

	for i := 1; i < settings.Vagrant.WindowsMaxAttempts; i++ {
		log.Printf("vagrant status winw1 - attempt %d of %d", i, settings.Vagrant.WindowsMaxAttempts)
		output, err := sh.Output("vagrant", "status", "winw1")
		if err != nil {
			return err
		}
		status := extractMachineStatus(output, "winw1")
		log.Println("winw1", status)
		if strings.Contains(status, "running") {
			break
		}
		log.Printf("vagrant up winw1 - attempt %d of %d", i, settings.Vagrant.WindowsMaxAttempts)
		err = sh.Run("vagrant", "up", "winw1")
		if err != nil {
			return err
		}
	}

	err := setVagrantPrivateKeyPermissions()
	if err != nil {
		return err
	}

	// TODO: Is re-provisioning required? What problem does it actually solve? If boxes are usable then vagrant up above should be sufficient.
	log.Println("Provisioning Windows worker node")
	for i := 1; i < settings.Vagrant.WindowsMaxAttempts; i++ {
		log.Printf("kubectl get nodes | grep winw1  - attempt %d of %d", i, settings.Vagrant.WindowsMaxAttempts)
		output, err := sh.Output("vagrant", "ssh", "controlplane", "-c", "kubectl get nodes")
		if err != nil {
			return err
		}
		log.Println(output)
		if strings.Contains(output, "winw1") {
			break
		}
		log.Printf("vagrant provision winw1 - attempt %d of %d", i, settings.Vagrant.WindowsMaxAttempts)
		err = sh.Run("vagrant", "provision", "winw1")
		if err != nil {
			return err
		}
	}

	log.Println("Windows worker node created")
	return nil
}

func preRun() error {
	log.Println("Executing preRun target")

	log.Println("Creating .lock directory")
	_, err := os.Stat(".lock")
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
	return nil

	logTargetRunTime("preRun")
	return nil
}

func postRun() error {
	log.Println("Executing postRun target")

	joinedFile := filepath.Join(".lock", "joined")
	log.Printf("Creating %s indicator file for Vagrantfile", joinedFile)
	err := touchFile(joinedFile)
	if err != nil {
		return err
	}

	cniFile := filepath.Join(".lock", "cni")
	log.Printf("Creating %s indicator file for Vagrantfile", cniFile)
	err = touchFile(cniFile)
	if err != nil {
		return err
	}

	// Report cluster status
	log.Println("Cluster created")
	logTargetRunTime("postRun")
	return nil
}

// Check if cluster has not already been created.
// Run clean to delete existing cluster, before recreating it.
func checkClusterNotExist() error {

	// TODO: List of required indicators of completed cluster or just check single "joined" file?
	var indicatorFiles = [...]string{
		filepath.Join(".lock", "joined"),
		filepath.Join(".lock", "cni"),
		filepath.Join(".lock"),
	}

	var found = []string{}

	for _, path := range indicatorFiles {
		_, err := os.Stat(filepath.Clean(path))
		if !os.IsNotExist(err) {
			found = append(found, path)
		}
	}

	if len(found) > 0 {
		log.Fatalln("Cluster already exists. Run `mage clean` first to delete it and start over.")
	}

	return nil
}

func setVagrantPrivateKeyPermissions() error {

	// TODO: Fixed list is to control what file is processed,
	// but may be better to turn all search for all private_key in .vagrant,
	// e.g. in case machines are renamed.
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
				return err
			}
			continue
		}

		err = sh.Run("icacls", keyFile, "/c", "/t", "/Inheritance:d")
		if err != nil {
			return err
		}
		user := fmt.Sprintf("%s:F", os.Getenv("USERNAME"))
		err = sh.Run("icacls", keyFile, "/c", "/t", "/Grant", user)
		if err != nil {
			return err
		}
		err = sh.Run("takeown", "/F", keyFile)
		if err != nil {
			return err
		}
		err = sh.Run("icacls", keyFile, "/c", "/t", "/Grant:r", user)
		if err != nil {
			return err
		}
		err = sh.Run("icacls", keyFile, "/c", "/t", "/Remove:g", "Administrator", "Authenticated Users", "BUILTIN\\Administrators", "BUILTIN", "Everyone", "System", "Users")
		if err != nil {
			return err
		}
		err = sh.Run("icacls", keyFile)
		if err != nil {
			return err
		}
	}

	return nil
}

func extractMachineStatus(statusOutput string, machineName string) string {
	r := fmt.Sprintf(`(?m)^%s.*`, machineName)
	m := regexp.MustCompile(r)
	s := m.FindString(statusOutput)
	v := strings.Split(s, machineName)
	return strings.TrimSpace(v[1])
}

func touchFile(filePath string) error {
	file, err := os.OpenFile(filePath, os.O_CREATE|os.O_RDWR|os.O_TRUNC, 644)
	if err != nil {
		return err
	}
	err = file.Close()
	if err != nil {
		return err
	}
	return nil
}

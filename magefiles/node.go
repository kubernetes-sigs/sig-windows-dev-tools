//go:build mage
// +build mage

package main

import (
	"fmt"
	"log"
	"strings"

	"github.com/magefile/mage/mg"
	"github.com/magefile/mage/sh"
)

// Exported targets namespace
type Node mg.Namespace

// Create new Vagrant machine of named cluster node.
func (Node) Create(nodeName string) error {
	nodeName = strings.TrimSpace(nodeName)
	if nodeName == "" {
		log.Fatalln("Node name is empty")
	}

	mg.SerialDeps(startup, checkClusterNotExist, Config.Settings, Config.Vagrant)

	// Validate the node is known to Vagrant
	_, err := sh.Output("vagrant", "status", nodeName)
	if err != nil {
		return err
	}

	if nodeName == "controlplane" {
		mg.SerialDeps(runLinuxControlPlaneNode)
		return nil
	}

	if nodeName == "winworker" {
		mg.SerialDeps(runWindowsWorkerNode)
		return nil
	}

	return fmt.Errorf("Node '%s' is unknown", nodeName)
}

// Destroy Vagrant machine of named cluster node.
func (Node) Destroy(nodeName string) error {
	nodeName = strings.TrimSpace(nodeName)
	if nodeName == "" {
		log.Fatalln("Node name is empty")
	}

	mg.SerialDeps(Config.Vagrant)

	var err error

	// Validate the node is known to Vagrant
	_, err = sh.Output("vagrant", "status", nodeName)
	if err != nil {
		return err
	}

	err = sh.Run("vagrant", "destroy", "--force", nodeName)
	if err != nil {
		return err
	}

	return nil
}

// Start Vagrant machine of existing named cluster node, without running provisioners.
func (Node) Start(nodeName string) error {
	nodeName = strings.TrimSpace(nodeName)
	if nodeName == "" {
		log.Fatalln("Node name is empty")
	}

	mg.SerialDeps(Config.Vagrant)

	var err error

	// Validate the node is known to Vagrant
	_, err = sh.Output("vagrant", "status", nodeName)
	if err != nil {
		return err
	}

	err = sh.Run("vagrant", "up", "--no-provision", nodeName)
	if err != nil {
		return err
	}

	logTargetRunTime("Clean")
	return nil
}

// Stop Vagrant machine of existing named cluster node.
func (Node) Stop(nodeName string) error {
	nodeName = strings.TrimSpace(nodeName)
	if nodeName == "" {
		log.Fatalln("Node name is empty")
	}

	mg.SerialDeps(Config.Vagrant)

	var err error

	// Validate the node is known to Vagrant
	_, err = sh.Output("vagrant", "status", nodeName)
	if err != nil {
		return err
	}

	err = sh.Run("vagrant", "halt", nodeName)
	if err != nil {
		return err
	}

	logTargetRunTime("Clean")
	return nil
}

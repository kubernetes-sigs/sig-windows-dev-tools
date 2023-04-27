//go:build mage
// +build mage

package main

import (
	"log"
	"os"

	"github.com/magefile/mage/mg"
)

// Build Kubernetes from sources for Linux and Windows.
// This step is optional, an alternative to fetch command.
func Build() error {
	mg.SerialDeps(startup, checkVagrant)

	log.Println("TODO: Building Kubernetes from sources on Windows host without make is not implemented yet")

	if Settings["build_from_source"] == "false" {
		log.Printf("File %s declares 'build_from_source=%v'. Skipping.", os.Getenv("VAGRANT_VARIABLES"), Settings["build_from_source"])
		return nil
	}

	logTargetRunTime("Build")
	return nil
}

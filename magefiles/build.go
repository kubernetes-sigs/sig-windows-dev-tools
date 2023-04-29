//go:build mage
// +build mage

package main

import (
	"log"
	"os"

	"github.com/magefile/mage/mg"
)

// Clone and build Kubernetes from source (on Windows native host use fetch).
// This step is optional, an alternative to fetch command.
func Build() error {
	mg.SerialDeps(startup, Config.Settings)

	log.Println("TODO: Building Kubernetes from sources on Windows host without make is not implemented yet")

	if !settings.Kubernetes.BuildFromSource {
		log.Printf("File %s declares 'kubernetes_build_from_source=%v'. Skipping.", os.Getenv("SWDT_SETTINGS_FILE"), settings.Kubernetes.BuildFromSource)
		return nil
	}

	logTargetRunTime("Build")
	return nil
}

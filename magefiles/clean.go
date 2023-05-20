//go:build mage
// +build mage

package main

import (
	"log"
	"os"
	"path/filepath"

	"github.com/magefile/mage/mg"
)

// Destroy cluster, destroying existing Vagrant machines
// delete downloaded and built binaries, to start fresh.
func Clean() error {
	mg.SerialDeps(startup, Config.Settings, Config.Vagrant, Cluster.Destroy)

	var volatilePaths = [...]string{
		filepath.Join("sync", "linux", "download"),
		filepath.Join("sync", "windows", "download"),
		filepath.Join(".vagrant"),
	}

	for _, path := range volatilePaths {
		_, err := os.Stat(filepath.Clean(path))
		if !os.IsNotExist(err) {
			log.Println("Cleaning", path)
			err := os.RemoveAll(path)
			if err != nil {
				return err
			}
		}
	}

	logTargetRunTime("Clean")
	return nil
}

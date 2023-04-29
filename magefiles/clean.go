//go:build mage
// +build mage

package main

import (
	"log"
	"os"
	"path/filepath"

	"github.com/magefile/mage/mg"
	"github.com/magefile/mage/sh"
)

// Delete cluster and start fresh destroying existing Vagrant machines.
func Clean() error {
	mg.SerialDeps(startup, Config.Settings, Config.Vagrant)

	// ignore errors and continue
	sh.Run("vagrant", "destroy", "--force")

	var volatilePaths = [...]string{
		filepath.Join("sync", "linux", "bin"),
		filepath.Join("sync", "windows", "bin"),
		filepath.Join("sync", "shared", "config"),
		filepath.Join("sync", "shared", "kubeadm.yaml"),
		filepath.Join("sync", "shared", "kubejoin.ps1"),
		filepath.Join("sync", "shared", "settings.yaml"),
		filepath.Join(".lock"),
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

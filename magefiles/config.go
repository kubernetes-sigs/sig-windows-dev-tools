//go:build mage
// +build mage

package main

import (
	"fmt"
	"io/ioutil"
	"log"
	"os"
	"os/exec"
	"strings"

	"github.com/magefile/mage/mg"
	"github.com/magefile/mage/sh"
	"gopkg.in/yaml.v3"
)

// Exported targets namespace
type Config mg.Namespace

// Load configuration settings from default settings.yaml or user-specific settings.local.yaml.
// First, checks for variables file set via SWDT_SETTINGS_FILE environment variables,
// then user-specific settings.local.yaml, falling back to default varaibles.yaml.
// Every public target must depend on Configure target.
func (Config) Settings() error {
	mg.SerialDeps(startup)

	settingsFile, err := findSettingsFile()
	if err != nil {
		return err
	}

	err = readSettingsFromFile(settingsFile)
	if err != nil {
		return err
	}

	settingsDump, err := yaml.Marshal(settings)
	if err != nil {
		return err
	}

	log.Printf("--- Begin of configuration from %s ------------", settingsFile)
	fmt.Print(string(settingsDump))
	log.Printf("--- End of configuration from %s   ------------", settingsFile)

	logTargetRunTime("Settings")
	return nil
}

// Check Vagrant installation.
// Every target that runs vagrant must depend on Vagrant target.
func (Config) Vagrant() error {
	mg.SerialDeps(startup, Config.Settings)

	var err error = nil

	_, err = exec.LookPath("vagrant")
	if err != nil {
		return err
	}

	out, err := sh.Output("vagrant", "--version")
	if err != nil {
		return err
	}
	log.Println("Using", out)

	// TODO: Add checks of required Vagrant plugins

	err = sh.Run("vagrant", "validate")
	if err != nil {
		return err
	}

	logTargetRunTime("Config")
	return nil
}

// Run-time settings loaded from settings.yaml or settings.local.yaml
// or file passed via SWDT_SETTINGS_FILE environment variable.
var settings Settings

type Settings struct {
	Calico     Calico
	containerd containerd
	Kubernetes Kubernetes
	Network    Network
	Vagrant    Vagrant
}

type Calico struct {
	Version string `yaml:"calico_version"`
}

type containerd struct {
	Version string `yaml:"containerd_version"`
}

type Kubernetes struct {
	BuildFromSource bool   `yaml:"kubernetes_build_from_source"`
	Version         string `yaml:"kubernetes_version"`
}

type Network struct {
	CNI           string `yaml:"cni"`
	LinuxNodeIP   string `yaml:"linux_node_ip"`
	WindowsNodeIP string `yaml:"windows_node_ip"`
	PodCIDR       string `yaml:"pod_cidr"`
}

// There are two types of Vagrant machines: Linux or Windows
type Vagrant struct {
	LinuxBox                   string `yaml:"vagrant_linux_box"`
	LinuxBoxVersion            string `yaml:"vagrant_linux_box_version"`
	LinuxCPU                   int    `yaml:"vagrant_linux_cpus"`
	LinuxRAM                   int    `yaml:"vagrant_linux_ram"`
	WindowsBox                 string `yaml:"vagrant_windows_box"`
	WindowsBoxVersion          string `yaml:"vagrant_windows_box_version"`
	WindowsCPU                 int    `yaml:"vagrant_windows_cpus"`
	WindowsRAM                 int    `yaml:"vagrant_windows_ram"`
	WindowsMaxAttempts         int    `yaml:"vagrant_windows_max_provision_attempts"`
	VBGuestAdditionsAutoUpdate bool   `yaml:"vagrant_vbguest_auto_update"`
}

func findSettingsFile() (string, error) {
	// User may have already defined SWDT_SETTINGS_FILE environment variable
	settingsFile := strings.TrimSpace(os.Getenv("SWDT_SETTINGS_FILE"))
	if settingsFile != "" {
		_, err := os.Stat(settingsFile)
		if os.IsNotExist(err) {
			settingsFile = ""
		}
	}
	// Alternatively, user may have created local variables file
	if settingsFile == "" {
		_, err := os.Stat("settings.local.yaml")
		if !os.IsNotExist(err) {
			settingsFile = "settings.local.yaml"
		}
		if settingsFile != "" {
			log.Printf("Setting environment variable SWDT_SETTINGS_FILE=%v", settingsFile)
			err = os.Setenv("SWDT_SETTINGS_FILE", settingsFile)
			if err != nil {
				return "", err
			}
		}
	}
	// Othwerise, fallback to default variable file
	if strings.TrimSpace(os.Getenv("SWDT_SETTINGS_FILE")) == "" {
		_, err := os.Stat("settings.yaml")
		if os.IsNotExist(err) {
			return "", err
		}
		settingsFile = "settings.yaml"
	}
	return settingsFile, nil
}

func readSettingsFromFile(settingsFile string) error {
	data, err := ioutil.ReadFile(settingsFile)
	if err != nil {
		return err
	}
	err = yaml.Unmarshal(data, &settings.Calico)
	if err != nil {
		return err
	}
	err = yaml.Unmarshal(data, &settings.containerd)
	if err != nil {
		return err
	}
	err = yaml.Unmarshal(data, &settings.Kubernetes)
	if err != nil {
		return err
	}
	err = yaml.Unmarshal(data, &settings.Network)
	if err != nil {
		return err
	}
	err = yaml.Unmarshal(data, &settings.Vagrant)
	if err != nil {
		return err
	}
	return nil
}

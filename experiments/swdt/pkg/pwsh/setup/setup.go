package setup

import (
	"fmt"

	"github.com/fatih/color"
	"k8s.io/klog/v2"
)

var (
	mainc = color.New(color.FgHiBlack).Add(color.Underline)
	resc  = color.New(color.FgHiGreen).Add(color.Bold)
	errc  = color.New(color.FgHiRed)
)

const (
	CHOCO_PATH    = "C:\\ProgramData\\chocolatey\\bin\\choco.exe"
	CHOCO_INSTALL = "choco install --accept-licenses --yes"
)

// Runner holds the executor functions for running remote commands
type Runner struct {
	Run  func(args string) (string, error)
	Copy func(local, remote, perm string) error
}

// InstallChoco proceed to install choco in the default ProgramData folder.
func (r *Runner) InstallChoco() error {
	klog.Info(mainc.Sprint("Installing Choco with PowerShell"))

	if r.ChocoExists() {
		klog.Info(resc.Sprintf("Choco already exists, skipping installation..."))
		return nil
	}

	// Proceed to install choco package manager.
	output, err := r.Run(`Set-ExecutionPolicy Bypass -Scope Process -Force;
		[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; 
		iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))`)
	if err != nil {
		return err
	}
	klog.Info(resc.Sprintf("Installed Choco with: %s", output))

	return nil
}

// InstallChocoPackages iterate on a list of packages and execute the installation.
func (r *Runner) InstallChocoPackages(packages []string) error {
	if !r.ChocoExists() {
		return fmt.Errorf("choco not installed. Skipping package installation")
	}
	for _, pkg := range packages {
		output, err := r.Run(fmt.Sprintf("%s %s", CHOCO_INSTALL, pkg))
		if err != nil {
			return err
		}
		klog.Info(resc.Sprintf("Installed package %s: %s", pkg, output))
	}
	return nil
}

// ChocoExists check if choco is already installed in the system.
// todo(knabben) - fix the error granularity and find the correct stderr
func (r *Runner) ChocoExists() bool {
	_, err := r.Run(fmt.Sprintf("%s --version", CHOCO_PATH))
	return err == nil
}

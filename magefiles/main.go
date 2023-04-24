//go:build mage
// +build mage

package main

import (
	"fmt"
	"io/ioutil"
	"log"
	"os"
	"os/exec"
	"sort"
	"strings"
	"time"

	"github.com/magefile/mage/mg"
	"github.com/magefile/mage/sh"
	"gopkg.in/yaml.v2"
)

// Mage default target.
var Default = All

// Content loaded from variables.yaml or variables.local.yaml
// or file passed via VAGRANT_VARIABLES environment variable.
var Settings map[string]string

// Aliases based on original Makefile targets.
// Use mage -h <target> to see available aliases.
var Aliases = map[string]interface{}{
	"1-build-binaries": Build,
	"2-vagrant-up":     Run,
	"3-smoke-test":     Test.Smoke,
	"4-e2e-test":       Test.EndToEnd,
}

// All logs from Magefiles are prefixed with this tag (e.g. for easy search)
const LogPrefix = "[swdt-mage] "

// Run complete sequence of targets according to configuration in variables.yaml or variables.local.yaml.
func All() error {
	mg.SerialDeps(startup, Fetch, Run, Test.Smoke, Test.EndToEnd)

	logTargetRunTime("All")
	return nil
}

// Every public target must depend on startup.
func startup() error {
	startTime = time.Now()
	log.SetFlags(log.Ldate | log.Ltime | log.Lshortfile | log.LUTC | log.Lmsgprefix)
	log.SetOutput(os.Stdout) // simplify use of tee
	log.SetPrefix(LogPrefix)

	// User may have already defined VAGRANT_VARIABLES environment variable
	variablesFile := strings.TrimSpace(os.Getenv("VAGRANT_VARIABLES"))
	if variablesFile != "" {
		_, err := os.Stat(variablesFile)
		if os.IsNotExist(err) {
			variablesFile = ""
		}
	}
	// Alternatively, user may have created local variables file
	if variablesFile == "" {
		_, err := os.Stat("variables.local.yaml")
		if !os.IsNotExist(err) {
			variablesFile = "variables.local.yaml"
		}
		if variablesFile != "" {
			log.Printf("Setting environment variable VAGRANT_VARIABLES=%v", variablesFile)
			os.Setenv("VAGRANT_VARIABLES", variablesFile)
		}
	}
	// Othwerise, fallback to default variable file
	if variablesFile == "" && strings.TrimSpace(os.Getenv("VAGRANT_VARIABLES")) == "" {
		_, err := os.Stat("variables.yaml")
		if os.IsNotExist(err) {
			return err
		}
		variablesFile = "variables.yaml"
	}

	variablesData, err := ioutil.ReadFile(variablesFile)
	if err != nil {
		return err
	}
	settings := make(map[string]string)
	err = yaml.Unmarshal(variablesData, &settings)
	if err != nil {
		return err
	}

	// The internal startup target is a dependency of number of public targets and,
	// most likely, Mage will never re-run it more than once for bulk of targets e.g. All,
	// so this check is likely a superfluous check. Still learning Mage though.
	if len(Settings) == 0 {
		// Assume variables YAML is always a flat map
		variables := make([]string, 0, len(settings))
		for k := range settings {
			variables = append(variables, k)
		}
		sort.Strings(variables)

		log.Println("--- Settings ------------")
		for _, key := range variables {
			fmt.Println(key, ": ", settings[key])
		}
		log.Println("-------------------------")
	}
	Settings = settings
	return nil
}

// Every public target that runs vagrant must depend on checkVagrant.
func checkVagrant() error {
	_, err := exec.LookPath("vagrant")
	if err != nil {
		return err
	}
	out, err := sh.Output("vagrant", "--version")
	if err != nil {
		return err
	}
	log.Println("Using", out)
	return nil
}

var startTime time.Time // used to calculate target run time

func logTargetRunTime(target string) {
	elapsed := time.Since(startTime)
	log.Printf("Target %s finished in %.2f minutes", target, elapsed.Minutes())
}

func init() {
	var err error

	err = os.Setenv("MAGEFILE_ENABLE_COLOR", "1")
	if err != nil {
		panic(err)
	}

	// Always display output from vagrant and other commands,
	// regardless of mage -v option.
	os.Setenv("MAGEFILE_VERBOSE", "1")
	if err != nil {
		panic(err)
	}
}

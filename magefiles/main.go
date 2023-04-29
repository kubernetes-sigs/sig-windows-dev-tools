//go:build mage
// +build mage

package main

import (
	"log"
	"os"
	"time"

	"github.com/magefile/mage/mg"
)

// Mage default target.
var Default = All

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

// Run complete workflow: download Kubernetes, create cluster, execute tests.
func All() error {
	mg.SerialDeps(startup, Config.Settings, Fetch, Run, Test.Smoke, Test.EndToEnd)

	logTargetRunTime("All")
	return nil
}

// Log utility called at the exit of every target routine.
func logTargetRunTime(target string) {
	elapsed := time.Since(startTime)
	log.Printf("Target %s finished in %.2f minutes", target, elapsed.Minutes())
}

// Environment and logger initialization
var startTime time.Time // used to calculate target run time

func startup() error {
	startTime = time.Now()
	log.SetFlags(log.Ldate | log.Ltime | log.Lshortfile | log.LUTC | log.Lmsgprefix)
	log.SetOutput(os.Stdout) // simplify use of tee
	log.SetPrefix(LogPrefix)
	return nil
}

func init() {
	var err error

	err = os.Setenv("MAGEFILE_ENABLE_COLOR", "1")
	if err != nil {
		panic(err)
	}

	// Always display output from vagrant and other commands,
	// regardless of mage -v option.
	err = os.Setenv("MAGEFILE_VERBOSE", "1")
	if err != nil {
		panic(err)
	}
}

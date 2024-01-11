/*
Copyright 2024 The Kubernetes Authors.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/

package cmd

import (
	"swdt/pkg/config"
	"swdt/pkg/connections"
	"swdt/pkg/pwsh/setup"

	"github.com/spf13/cobra"
)

var configFile, password string

func init() {
	rootCmd.AddCommand(setupCmd)
	setupCmd.Flags().StringVarP(&configFile, "config", "c", "samples/config.yaml", "Configuration file path.")
	setupCmd.Flags().StringVarP(&password, "password", "p", "", "SSH Password -- should read from stdin.")
}

// setupCmd represents the setup command
var setupCmd = &cobra.Command{
	Use:   "setup",
	Short: "Bootstrap the node via basic unit setup.",
	Long:  `Bootstrap the node via basic unit setup.`,
	RunE:  Run,
}

func Run(cmd *cobra.Command, args []string) error {
	configuration, err := config.LoadConfigFromFile(configFile)
	if err != nil {
		return err
	}

	sshConnection := connections.NewConnection(password, configuration.Spec.Cred)
	defer sshConnection.Close()

	if err := sshConnection.Connect(); err != nil {
		return err
	}

	return runSteps(sshConnection)
}

func runSteps(conn connections.Connection) error {
	runner := setup.Runner{Run: conn.Run, Copy: conn.Copy}
	return runner.InstallChoco()
}

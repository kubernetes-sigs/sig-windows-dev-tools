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
	"github.com/spf13/cobra"
	"os"
	"swdt/apis/config/v1alpha1"
	"swdt/pkg/config"
)

func init() {
	rootCmd.PersistentFlags().StringP("config", "c", "samples/config.yaml", "Configuration file path.")
}

// rootCmd represents the base command
var rootCmd = &cobra.Command{
	Use:   "swdt",
	Short: "SIG Windows Development Tools",
	Long: `Auxiliary program for Windows nodes installation and initial setup.
	Check the subcommands.`,
}

// loadConfiguration marshal the YAML configuration in an internal struct
func loadConfiguration() (*v1alpha1.Node, error) {
	return config.LoadConfigNodeFromFile(rootCmd.Flag("config").Value.String())
}

func Execute() {
	err := rootCmd.Execute()
	if err != nil {
		os.Exit(1)
	}
}

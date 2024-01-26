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
	"swdt/apis/config/v1alpha1"
	"swdt/pkg/config"

	"github.com/spf13/cobra"

	"k8s.io/component-base/featuregate"
	logsapi "k8s.io/component-base/logs/api/v1"
)

var featureGate = featuregate.NewFeatureGate()

// NewRootCommand creates the `swdt` command and its nested children.
func NewRootCommand() *cobra.Command {
	logscfg := logsapi.NewLoggingConfiguration()
	if err := logsapi.AddFeatureGates(featureGate); err != nil {
		panic(err)
	}
	if err := logsapi.ValidateAndApply(logscfg, featureGate); err != nil {
		panic(err)
	}

	cmd := &cobra.Command{
		Use:   "swdt",
		Short: "SIG Windows Development Tools",
		Long: `Auxiliary program for Windows nodes installation and initial setup.
	Check the subcommands.`,
	}

	featureGate.AddFlag(cmd.Flags())
	logsapi.AddFlags(logscfg, cmd.Flags())

	cmd.PersistentFlags().StringP("config", "c", "samples/config.yaml", "Configuration file path.")

	cmd.AddCommand(setupCmd)
	cmd.AddCommand(kubernetesCmd)

	return cmd
}

// loadConfiguration marshal the YAML configuration in an internal struct
func loadConfiguration(cmd *cobra.Command) (*v1alpha1.Node, error) {
	return config.LoadConfigNodeFromFile(cmd.Flag("config").Value.String())
}

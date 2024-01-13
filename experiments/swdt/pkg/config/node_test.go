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

package config

import (
	"testing"

	"github.com/stretchr/testify/assert"
)

const (
	SAMPLE_FILE    = "../../samples/config.yaml"
	SAMPLE_DEFAULT = `apiVersion: windows.k8s.io/v1alpha1
kind: Node
metadata:
  name: sample
spec:`
)

func TestLoadConfigNodeDefaults(t *testing.T) {
	config, err := loadConfigNode([]byte(SAMPLE_DEFAULT))
	config.Spec.Defaults()
	assert.Nil(t, err)

	assert.True(t, *config.Spec.Setup.EnableRDP)
	assert.Len(t, *config.Spec.Setup.ChocoPackages, 0)
}

func TestLoadConfigNode(t *testing.T) {
	config, err := LoadConfigNodeFromFile(SAMPLE_FILE)
	assert.Nil(t, err)

	assert.True(t, *config.Spec.Setup.EnableRDP)
	assert.Equal(t, len(*config.Spec.Setup.ChocoPackages), 2)

	deploys := config.Spec.Kubernetes.Deploys
	assert.Len(t, deploys, 2)

	for _, d := range deploys {
		assert.GreaterOrEqual(t, len(d.SourceURL), 2)
		assert.GreaterOrEqual(t, len(d.Destination), 4)
	}
}

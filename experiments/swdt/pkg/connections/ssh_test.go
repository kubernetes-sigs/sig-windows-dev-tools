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

package connections

import (
	"swdt/pkg/connections/tests"
	"testing"

	"github.com/stretchr/testify/assert"
	"swdt/apis/config/v1alpha1"
)

func TestRunWithoutConnect(t *testing.T) {
	credentials := v1alpha1.CredentialsSpec{}
	conn := NewConnection(credentials)
	assert.NotEqual(t, conn, nil)
	out, err := conn.Run("ls")
	assert.NotNil(t, err)
	assert.Equal(t, out, "")
}

func TestConnect(t *testing.T) {
	var (
		out      string
		err      error
		expected = "Running kubelet Kubelet"
		cmd      = "get-service -name kubelet"
	)

	// start a fake SSH server
	hostname := tests.GetHostname("2023")
	tests.NewServer(hostname, expected)

	credentials := v1alpha1.CredentialsSpec{
		Hostname: hostname,
		Username: tests.Username,
		Password: tests.FakePassword,
	}

	conn := NewConnection(credentials)
	assert.NotEqual(t, conn, nil)
	err = conn.Connect()
	assert.Nil(t, err)
	out, err = conn.Run(cmd)
	assert.Nil(t, err)
	assert.Equal(t, out, expected)
}

package kubernetes

import (
	"fmt"
	"github.com/stretchr/testify/assert"
	"swdt/apis/config/v1alpha1"
	"testing"
)

var (
	calls = []string{}
)

func validateRun(args string) (string, error) {
	calls = append(calls, args)
	return "cmd stdout", nil
}

func validateCopy(l, r, p string) error {
	return nil
}

func TestInstallProvisioners(t *testing.T) {
	r := KubernetesRunner{run: validateRun, copy: validateCopy}
	serviceName := "containerd"
	provisioners := []v1alpha1.ProvisionerSpec{{Name: serviceName}}
	assert.Nil(t, r.InstallProvisioners(provisioners))
	assert.Len(t, calls, 2)
	assert.Equal(t, calls[0], fmt.Sprintf("Stop-Service -name %s -Force", serviceName))
	assert.Equal(t, calls[1], fmt.Sprintf("Start-Service -name %s", serviceName))
}

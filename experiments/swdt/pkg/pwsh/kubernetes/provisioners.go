package kubernetes

import (
	"fmt"
	"github.com/fatih/color"
	"k8s.io/klog/v2"
	"swdt/apis/config/v1alpha1"
	"swdt/pkg/connections"
)

var (
	resc       = color.New(color.FgHiGreen).Add(color.Bold)
	permission = "0755"
)

type KubernetesRunner struct {
	conn connections.Connection
	run  func(args string) (string, error)
	copy func(local, remote, perm string) error
}

func (r *KubernetesRunner) SetConnection(conn *connections.Connection) {
	r.conn = *conn
	r.run = r.conn.Run
	r.copy = r.conn.Copy
}

func (r *KubernetesRunner) InstallProvisioners(provisioners []v1alpha1.ProvisionerSpec) error {
	for _, provisioner := range provisioners {
		source, destination := provisioner.SourceURL, provisioner.Destination
		name := provisioner.Name

		klog.Info(resc.Sprintf("Service %s binary replacement, trying to stop service...", name))
		_, err := r.run(fmt.Sprintf("Stop-Service -name %s -Force", name))
		if err != nil {
			klog.Error(err)
			continue
		}
		klog.Infof("Service stopped. Copying file %s to remote %s...", source, destination)
		if err = r.copy(source, destination, permission); err != nil {
			klog.Error(err)
			continue
		}
		klog.Infof("starting service %s again...", name)
		_, err = r.run(fmt.Sprintf("Start-Service -name %s", name))
		if err != nil {
			klog.Error(err)
			continue
		}
		klog.Info(resc.Sprintf("Service started.\n"))
	}
	return nil
}

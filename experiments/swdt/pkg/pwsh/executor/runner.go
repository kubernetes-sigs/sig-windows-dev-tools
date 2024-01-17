package executor

import (
	"swdt/apis/config/v1alpha1"
	"swdt/pkg/connections"
	"swdt/pkg/pwsh/kubernetes"
	"swdt/pkg/pwsh/setup"
)

type RunnerInterface interface {
	*setup.SetupRunner | *kubernetes.KubernetesRunner
	SetConnection(conn *connections.Connection)
}

type Runner[R RunnerInterface] struct {
	Inner R
	Conn  connections.Connection
}

// SetConnection forward the object to the inner runner
func (r *Runner[R]) SetConnection(conn *connections.Connection) {
	r.Conn = *conn
	r.Inner.SetConnection(conn)
}

// CloseConnection finished the remote connection from runner
func (r *Runner[R]) CloseConnection() error {
	return r.Conn.Close()
}

// NewRunner returns a new encapsulated Runner to be reused on specialized commands.
func NewRunner[R RunnerInterface](nodeConfig *v1alpha1.Node, run R) (*Runner[R], error) {
	conn := connections.NewConnection(nodeConfig.Spec.Cred)
	if err := conn.Connect(); err != nil {
		return nil, err
	}
	runner := Runner[R]{Inner: run}
	runner.SetConnection(&conn)
	return &runner, nil
}

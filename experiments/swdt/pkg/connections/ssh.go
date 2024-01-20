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
	"bytes"
	"context"
	"errors"
	"fmt"
	"io"
	"os"
	"path"
	"regexp"
	"swdt/apis/config/v1alpha1"
	"sync"
	"time"

	scp "github.com/bramvdbogaerde/go-scp"
	"golang.org/x/crypto/ssh"
	"k8s.io/klog/v2"
)

const (
	TCP_TYPE                 = "tcp"
	SCP_BINARY               = "C:\\Windows\\System32\\OpenSSH\\scp.exe"
	timeout    time.Duration = 30 * time.Second
)

type SSHConnection struct {
	credentials *v1alpha1.CredentialsSpec
	client      *ssh.Client
}

// fetchAuthMethod fetches all available authentication methods
func (c *SSHConnection) fetchAuthMethod() (authMethod []ssh.AuthMethod, err error) {
	var (
		file       *os.File
		privateKey = c.credentials.PrivateKey
		password   = c.credentials.Password
		content    []byte
		signer     ssh.Signer
	)
	if privateKey != "" {
		file, err = os.Open(privateKey)
		if err != nil {
			return
		}
		content, err = io.ReadAll(file)
		if err != nil {
			return
		}
		signer, err = ssh.ParsePrivateKey(content)
		if err != nil {
			return
		}
		authMethod = append(authMethod, ssh.PublicKeys(signer))
	}
	if password != "" {
		authMethod = append(authMethod, ssh.Password(password))
	}

	return
}

// Connect creates the client connection object
func (c *SSHConnection) Connect() error {
	klog.V(1).Infof("SSH connecting to %s as %s", c.credentials.Hostname, c.credentials.Username)

	authMethod, err := c.fetchAuthMethod()
	if err != nil {
		return err
	}

	client, err := ssh.Dial(TCP_TYPE, c.credentials.Hostname, &ssh.ClientConfig{
		User:            c.credentials.Username,
		Auth:            authMethod,
		HostKeyCallback: ssh.InsecureIgnoreHostKey(),
	})
	if err != nil {
		return fmt.Errorf("failed to dial: %s", err)
	}
	c.client = client
	return nil
}

// Run a powershell command passed in the argument
func (c *SSHConnection) Run(args string) (string, error) {
	if c.client == nil {
		return "", fmt.Errorf("client is empty, call Connect() first")
	}

	var (
		err     error
		session *ssh.Session
		b       bytes.Buffer
	)
	if session, err = c.client.NewSession(); err != nil {
		return "", err
	}
	defer session.Close()
	session.Stdout = &b

	// Multiline PowerShell commands over SSH trip over newlines - only first one is executed
	args = regexp.MustCompile(`\r?\n`).ReplaceAllLiteralString(args, ";")
	cmd := fmt.Sprintf("powershell -nologo -noprofile -c { %s }", args)

	// TODO(mloskot): Why this is not printed?
	klog.V(1).Infof("SSH executing command: %s", cmd)

	if err := session.Run(cmd); err != nil {
		return "", err
	}

	return b.String(), nil
}

// Copy a file from local to remote setting the permissions
func (c *SSHConnection) Copy(local, remote, perm string) error {
	file, err := os.Open(local)
	if err != nil {
		return err
	}
	var contents []byte
	contents, err = io.ReadAll(file)
	if err != nil {
		return fmt.Errorf("failed to read all data from reader: %w", err)
	}
	return c.CopyPassThru(bytes.NewReader(contents), remote, perm, int64(len(contents)))
}

// CopyPassThru is an auxiliary function for Copy
func (c *SSHConnection) CopyPassThru(reader io.Reader, remote string, permissions string, size int64) error {
	var (
		ctx      = context.Background()
		filename = path.Base(remote)
	)

	session, err := c.client.NewSession()
	if err != nil {
		return err
	}
	defer session.Close()

	stdout, err := session.StdoutPipe()
	if err != nil {
		return err
	}
	writer, err := session.StdinPipe()
	if err != nil {
		return err
	}
	defer writer.Close()

	wg := sync.WaitGroup{}
	wg.Add(2)

	errCh := make(chan error, 2)

	go func() {
		defer wg.Done()
		defer writer.Close()

		_, err := fmt.Fprintln(writer, "C"+permissions, size, filename)
		if err != nil {
			errCh <- err
			return
		}

		if err = checkResponse(stdout); err != nil {
			errCh <- err
			return
		}
		_, err = io.Copy(writer, reader)
		if err != nil {
			errCh <- err
			return
		}

		_, err = fmt.Fprint(writer, "\x00")
		if err != nil {
			errCh <- err
			return
		}
		if err = checkResponse(stdout); err != nil {
			errCh <- err
			return
		}
	}()

	go func() {
		defer wg.Done()
		err := session.Start(fmt.Sprintf("%s -qt %q", SCP_BINARY, remote))
		if err != nil {
			errCh <- err
			return
		}
	}()

	if timeout > 0 {
		var cancel context.CancelFunc
		ctx, cancel = context.WithTimeout(ctx, timeout)
		defer cancel()
	}

	if err := wait(&wg, ctx); err != nil {
		return err
	}

	close(errCh)
	for err := range errCh {
		if err != nil {
			return err
		}
	}
	return nil
}

// wait waits for the waitgroup for the specified max timeout.
// Returns true if waiting timed out.
func wait(wg *sync.WaitGroup, ctx context.Context) error {
	c := make(chan struct{})
	go func() {
		defer close(c)
		wg.Wait()
	}()

	select {
	case <-c:
		return nil

	case <-ctx.Done():
		return ctx.Err()
	}
}

// Close finishes the connection
func (c *SSHConnection) Close() error {
	if c.client == nil {
		return nil
	}
	return c.client.Close()
}

func checkResponse(r io.Reader) error {
	response, err := scp.ParseResponse(r)
	if err != nil {
		return err
	}
	if response.IsFailure() {
		return errors.New(response.GetMessage())
	}
	return nil
}

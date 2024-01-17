package tests

import (
	"fmt"
	"golang.org/x/crypto/ssh"
	"golang.org/x/term"
	"log"
	"net"
)

var (
	Username     = "Administrator"
	FakePassword = "fakepassword"

	privateKey = []byte(`
-----BEGIN OPENSSH PRIVATE KEY-----
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
-----END OPENSSH PRIVATE KEY-----`)
)

func NewServer(hostname, expected string) {
	var err error
	config := &ssh.ServerConfig{PasswordCallback: passwordCallback}
	if err = parsePrivateKey(config, privateKey); err != nil {
		log.Fatal(err)
	}

	listener, err := net.Listen("tcp", hostname)
	if err != nil {
		log.Fatal("failed on listener: ", err)
	}

	go acceptConnection(listener, config, expected)
}

func acceptConnection(listener net.Listener, config *ssh.ServerConfig, result string) {
	for {
		conn, err := listener.Accept()
		if err != nil {
			log.Fatal("failed to accept conn: ", err)
		}
		_, channels, _, err := ssh.NewServerConn(conn, config)
		if err != nil {
			log.Fatal("failed to handshake: ", err)
		}

		for channel := range channels {
			channel, requests, err := channel.Accept() // accept channel
			if err != nil {
				log.Fatalf("error accepting channel: %v", err)
			}

			go handleRequest(requests, channel)

			t := term.NewTerminal(channel, "")
			_, err = t.Write([]byte(result))
			if err != nil {
				log.Fatalf("error writing channel: %v", err)
			}
			t.ReadLine()    // nolint
			channel.Close() // nolint
		}
	}
}

func handleRequest(in <-chan *ssh.Request, channel ssh.Channel) {
	for req := range in {
		switch req.Type {
		case "exec":
			channel.SendRequest("exit-status", false, []byte{0, 0, 0, 0}) // nolint
		}
		req.Reply(req.Type == "exec", nil) // nolint
	}
}

func passwordCallback(meta ssh.ConnMetadata, pass []byte) (*ssh.Permissions, error) {
	if meta.User() == Username && string(pass) == FakePassword {
		return nil, nil
	}
	return nil, fmt.Errorf("invalid password")
}

func GetHostname(port string) string {
	if port == "" {
		port = "2022"
	}
	return fmt.Sprintf("%s:%s", "127.0.0.1", port)
}

func parsePrivateKey(config *ssh.ServerConfig, key []byte) (err error) {
	var signer ssh.Signer
	signer, err = ssh.ParsePrivateKey(key)
	if err != nil {
		return err
	}
	config.AddHostKey(signer)
	return nil
}

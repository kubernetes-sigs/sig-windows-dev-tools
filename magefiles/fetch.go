//go:build mage
// +build mage

package main

import (
	"fmt"
	"io"
	"io/ioutil"
	"log"
	"net/http"
	"os"
	"path/filepath"
	"strings"

	"github.com/magefile/mage/mg"
)

// Download Kubernetes binaries.
// Default Kubernetes version is declared in settings.yaml.
// User can declare custom version in settings.local.yaml,
// a user-specific copy of settings.yaml
func Fetch() error {
	mg.SerialDeps(startup, Config.Settings)

	if settings.Kubernetes.BuildFromSource {
		log.Println("TODO: Building Kubernetes from sources on Windows host without make is not implemented yet")
		log.Printf("File %s declares 'kubernetes_build_from_source=%v'. Skipping.", os.Getenv("SWDT_SETTINGS_FILE"), settings.Kubernetes.BuildFromSource)
		return nil
	}

	// Fetch Kubernetes version manifest
	manifestUrl := fmt.Sprintf("https://storage.googleapis.com/k8s-release-dev/ci/latest-%s.txt", settings.Kubernetes.Version)
	log.Println("Downloading manifest", manifestUrl)
	kubernetesGitVersion, _, _ := downloadKubernetesVersion(manifestUrl)
	if kubernetesGitVersion == "" {
		log.Fatalf("Failed to determined Kubernetes tag and hash from version %s", kubernetesGitVersion)
	}

	log.Printf("Downloading binaries of Kubernetes %s", kubernetesGitVersion)

	// Download Linux binaries
	binPath := filepath.Join("sync", "linux", "bin")
	mustCreateDirectory(binPath)

	for _, exe := range []string{"kubeadm", "kubectl", "kubelet"} {
		downloadPath := filepath.Join(binPath, exe)
		url := fmt.Sprintf("https://storage.googleapis.com/k8s-release-dev/ci/%s/bin/linux/amd64/%s", kubernetesGitVersion, exe)
		log.Printf("Downloading %s from %s", downloadPath, url)
		_, err := os.Stat(downloadPath)
		if os.IsNotExist(err) {
			downloadFile(url, downloadPath)
		} else {
			log.Println("File exists. Skipping.")
		}
	}

	// Download Windows binaries
	binPath = filepath.Join("sync", "windows", "bin")
	mustCreateDirectory(binPath)

	for _, exe := range []string{"kubeadm.exe", "kubelet.exe", "kube-proxy.exe"} {
		downloadPath := filepath.Join(binPath, exe)
		url := fmt.Sprintf("https://storage.googleapis.com/k8s-release-dev/ci/%s/bin/windows/amd64/%s", kubernetesGitVersion, exe)
		log.Printf("Downloading %s from %s", downloadPath, url)
		_, err := os.Stat(downloadPath)
		if os.IsNotExist(err) {
			downloadFile(url, downloadPath)
		} else {
			log.Println("File exists. Skipping.")
		}
	}

	logTargetRunTime("Fetch")
	return nil
}

func mustCreateDirectory(path string) {
	_, err := os.Stat(path)
	if os.IsNotExist(err) {
		err := os.Mkdir(path, os.ModePerm)
		if err != nil {
			panic(err)
		}
	}
}

func downloadFile(url string, outputFile string) {
	resp, err := http.Get(url)
	if err != nil {
		panic(err)
	}
	defer resp.Body.Close()

	out, err := os.Create(outputFile)
	if err != nil {
		panic(err)
	}
	defer out.Close()

	_, err = io.Copy(out, resp.Body)
	if err != nil {
		panic(err)
	}
}

func downloadKubernetesVersion(manifestUrl string) (string, string, string) {
	resp, err := http.Get(manifestUrl)
	if err != nil {
		panic(err)
	}
	defer resp.Body.Close()

	body, err := ioutil.ReadAll(resp.Body)
	if err != nil {
		panic(err)
	}

	version := string(body)
	parts := strings.Split(version, "+")
	tag := strings.TrimSpace(parts[0])
	sha := strings.TrimSpace(parts[1])
	return version, tag, sha
}

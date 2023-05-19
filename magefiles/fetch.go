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

// Download Kubernetes, Calico binaries according to versions declared in settings.yaml.
// User can declare custom version in settings.local.yaml, a user-specific copy of settings.yaml.
func Fetch() error {
	mg.SerialDeps(startup, Config.Settings)

	syncPathLinux := filepath.Join("sync", "linux", "download")
	mustCreateDirectory(syncPathLinux)
	syncPathWindows := filepath.Join("sync", "windows", "download")
	mustCreateDirectory(syncPathWindows)

	var err error = nil

	err = downloadCalico(syncPathLinux)
	if err != nil {
		return err
	}

	err = downloadContainerd(syncPathWindows)
	if err != nil {
		return err
	}

	err = downloadCriCtl(syncPathWindows)
	if err != nil {
		return err
	}

	err = downloadKubernetes(syncPathLinux, syncPathWindows)
	if err != nil {
		return err
	}

	logTargetRunTime("Fetch")
	return nil
}

func downloadCalico(syncPathLinux string) error {
	log.Printf("Downloading binaries of Calico %s", settings.Calico.Version)

	for _, exe := range []string{"calicoctl"} {
		downloadPath := filepath.Join(syncPathLinux, exe)
		url := fmt.Sprintf("https://github.com/projectcalico/calico/releases/download/v%s/%s-linux-amd64", settings.Calico.Version, exe)
		log.Printf("Downloading %s from %s", downloadPath, url)
		_, err := os.Stat(downloadPath)
		if os.IsNotExist(err) {
			downloadFile(url, downloadPath)
		} else {
			log.Println("File exists. Skipping.")
		}
	}

	return nil
}

func downloadContainerd(syncPathWindows string) error {
	log.Printf("Downloading binaries of ContainerD %s", settings.Calico.Version)

	versionParts := strings.Split(settings.Calico.Version, ".")
	versionMajor := strings.TrimSpace(versionParts[0])
	versionMinor := strings.TrimSpace(versionParts[1])

	downloadPath := filepath.Join(syncPathWindows, "Install-Containerd.ps1")
	url := fmt.Sprintf("https://docs.tigera.io/calico/%s.%s/scripts/Install-Containerd.ps1", versionMajor, versionMinor)
	log.Printf("Downloading %s from %s", downloadPath, url)
	_, err := os.Stat(downloadPath)
	if os.IsNotExist(err) {
		downloadFile(url, downloadPath)
	} else {
		log.Println("File exists. Skipping.")
	}

	return nil
}

func downloadCriCtl(syncPathWindows string) error {

	versionParts := strings.Split(settings.Kubernetes.Version, ".")
	versionMajor := strings.TrimSpace(versionParts[0])
	versionMinor := strings.TrimSpace(versionParts[1])
	crictlVersion := fmt.Sprintf("%s.%s", versionMajor, versionMinor)

	log.Printf("Downloading binaries of crictl %s", crictlVersion)

	targzName := fmt.Sprintf("crictl-v%s-windows-amd64.tar.gz", crictlVersion)
	downloadPath := filepath.Join(syncPathWindows, targzName)
	url := fmt.Sprintf("https://github.com/kubernetes-sigs/cri-tools/releases/download/v%s/crictl-v%s-windows-amd64.tar.gz", crictlVersion, crictlVersion)
	log.Printf("Downloading %s from %s", downloadPath, url)
	_, err := os.Stat(downloadPath)
	if os.IsNotExist(err) {
		downloadFile(url, downloadPath)
	} else {
		log.Println("File exists. Skipping.")
	}

	return nil
}

func downloadKubernetes(targetPathLinux string, targetPathWindows string) error {
	if settings.Kubernetes.BuildFromSource {
		log.Println("TODO: Building Kubernetes from sources on Windows host without make is not implemented yet")
		log.Printf("File %s declares 'kubernetes_build_from_source=%v'. Skipping.", os.Getenv("SWDT_SETTINGS_FILE"), settings.Kubernetes.BuildFromSource)
		return nil
	}
	log.Printf("Downloading binaries of Kubernetes %s", settings.Kubernetes.Version)

	// Fetch Kubernetes version manifest
	manifestUrl := fmt.Sprintf("https://storage.googleapis.com/k8s-release-dev/ci/latest-%s.txt", settings.Kubernetes.Version)
	log.Println("Downloading manifest", manifestUrl)
	kubernetesGitVersion, _, _ := downloadKubernetesVersion(manifestUrl)
	if kubernetesGitVersion == "" {
		log.Fatalf("Failed to determined Kubernetes tag and hash from version %s", kubernetesGitVersion)
	}

	// Download Kubernetes Linux binaries
	for _, exe := range []string{"kubeadm", "kubectl", "kubelet"} {
		downloadPath := filepath.Join(targetPathLinux, exe)
		url := fmt.Sprintf("https://storage.googleapis.com/k8s-release-dev/ci/%s/bin/linux/amd64/%s", kubernetesGitVersion, exe)
		log.Printf("Downloading %s from %s", downloadPath, url)
		_, err := os.Stat(downloadPath)
		if os.IsNotExist(err) {
			downloadFile(url, downloadPath)
		} else {
			log.Println("File exists. Skipping.")
		}
	}

	// Download Kubernetes Windows binaries
	for _, exe := range []string{"kubeadm.exe", "kubectl.exe", "kubelet.exe", "kube-proxy.exe"} {
		downloadPath := filepath.Join(targetPathWindows, exe)
		url := fmt.Sprintf("https://storage.googleapis.com/k8s-release-dev/ci/%s/bin/windows/amd64/%s", kubernetesGitVersion, exe)
		log.Printf("Downloading %s from %s", downloadPath, url)
		_, err := os.Stat(downloadPath)
		if os.IsNotExist(err) {
			downloadFile(url, downloadPath)
		} else {
			log.Println("File exists. Skipping.")
		}
	}

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

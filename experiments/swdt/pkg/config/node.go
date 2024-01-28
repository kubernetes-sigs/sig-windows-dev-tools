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
	"fmt"
	"os"

	"swdt/apis/config/v1alpha1"

	"k8s.io/apimachinery/pkg/runtime"
	"k8s.io/apimachinery/pkg/runtime/serializer"
	utilruntime "k8s.io/apimachinery/pkg/util/runtime"
	klog "k8s.io/klog/v2"
)

var (
	scheme = runtime.NewScheme()
	codecs = serializer.NewCodecFactory(scheme, serializer.EnableStrict)
)

func init() {
	utilruntime.Must(v1alpha1.AddToScheme(scheme))
}

// LoadConfigNodeFromFile LoadConfigFromFile returns the marshalled Node configuration object
func LoadConfigNodeFromFile(file string) (*v1alpha1.Node, error) {
	klog.V(2).Infof("Loading node configuration from '%s'", file)

	data, err := os.ReadFile(file)
	if err != nil {
		return nil, err
	}
	return loadConfigNode(data)
}

// loadConfig decode the input read YAML into a configuration object
func loadConfigNode(data []byte) (*v1alpha1.Node, error) {
	var deserializer = codecs.UniversalDeserializer()
	configObj, gvk, err := deserializer.Decode(data, nil, nil)
	if err != nil {
		return nil, err
	}
	config, ok := configObj.(*v1alpha1.Node)
	if !ok {
		return nil, fmt.Errorf("got unexpected config type: %v", gvk)
	}
	config.Spec.Defaults()
	return config, nil
}

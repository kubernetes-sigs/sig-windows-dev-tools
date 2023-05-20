# Usage

For basic usage instructions refer to [Quick Start](../README.md#quick-start).

Run `mage -l` to list all available targets.

## Fetch kubeconfig

In order to connect to using a Kubernetes client from the host to the cluster,
you need to download kubeconfig form the `controlplane` node:

```console
vagrant plugin install vagrant-scp
vagrant scp controlplane:~/.kube/config ./swdt-kubeconfig
```

then use the downloaded kubeconfig to connect to the Kubernetes:

```console
kubectl --kubeconfig=./swdt-kubeconfig get nodes
```

Alternatively, run `vagrant ssh controlplane`, then copy `~/.kube/config` to `/var/sync/shared/swdt-kubeconfig`
which is mounted from local `sync/shared` directory, then

```console
kubectl --kubeconfig=./sync/shared/swdt-kubeconfig get nodes
```

to see your running two-node dual-OS Linux+Windows k8s cluster.

## Customize Settings

By default, configuration settings used to run and manage the cluster is read from the `settings.yaml` file.

Advanced users can overwrite the defaults with user-specific copy of the file with the defaults:

1. Copy `settings.yaml` with  to `settings.local.yaml`
2. Edit the `settings.local.yaml` modifying the settings as you desire.

For example, advanced users can tweak:

- RAM and CPUs allocated for Vagrant machines
- update Kubernetes version
- use custom Vagrant boxes

and more.

## Control Cluster

Once Kubernetes binaries have been built or downloaded together with binaries of other tools, for example:

```console
mage binaries:download
```

it is possible to create and destroy cluster repeatedly:

```console
mage cluster:create
mage cluster:destroy
```

## Control Nodes

There is a set of `mage` targets dedicated to testers who may appreciate fine-grained
control of nodes lifetime:

1. Create individual node

    ```console
    mage node:create controlplane
    mage node:create winw1
    ```

2. Stop individual node

    ```console
    mage node:stop controlplane
    mage node:stop winw1
    ```

3. Start individual node

    ```console
    mage node:start controlplane
    mage node:start winw1
    ```

4. Destroy individual node

    ```console
    mage node:destroy winw1
    mage node:destroy controlplane
    ```

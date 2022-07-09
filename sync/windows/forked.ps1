Param(
    [parameter(HelpMessage="Kubernetes Version")]
    [string] $kubernetesVersion=""
)

# Force Kubernetes folder
mkdir -Force C:/k/

# Copy a clean StartKubelet.ps1 configuration for 1.24+
If ([int]$kubernetesVersion.split(".",2)[1] -gt 23) {
    cp C:/forked/StartKubelet.ps1 c:\k\StartKubelet.ps1
}

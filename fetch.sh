if [[ -d kubernetes ]] ; then
	echo "kubernetes/ exists, doing nothing..."
	exit 0
fi

echo "clone kubernetes..."
git clone https://github.com/kubernetes/kubernetes.git

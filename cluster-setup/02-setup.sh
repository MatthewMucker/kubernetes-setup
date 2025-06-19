if [[ $EUID -eq 0 ]]; then
   echo "This script must not be run as root" 
   exit 1
fi

set -x

#Make node1 a worker node
kubectl label node $(uname -n) node-role.kubernetes.io/worker=worker

#Install Flannel CNI
kubectl apply -f kube-flannel.yaml

#Install gateway CRDs
kubectl apply -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.3.0/standard-install.yaml

#Allow the control plan node to run pods
kubectl taint nodes --all node-role.kubernetes.io/control-plane:NoSchedule-

# Start MetalLM installation
# actually apply the changes, returns nonzero returncode on errors only
kubectl get configmap kube-proxy -n kube-system -o yaml | \
sed -e "s/strictARP: false/strictARP: true/" | \
kubectl apply -f - -n kube-system

kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.15.2/config/manifests/metallb-native.yaml

# Install the istio Gateway
curl -L https://istio.io/downloadIstio | sh -
cd istio-1.26.1
export PATH=$PWD/bin:$PATH
istioctl version
istioctl install --set profile=ambient --skip-confirmation 
kubectl get crd gateways.gateway.networking.k8s.io &> /dev/null || kubectl apply -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.3.0/standard-install.yaml
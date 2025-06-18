#Make node1 a worker node
kubectl label node $(uname -n) node-role.kubernetes.io/worker=worker

#Install Flannel CNI
kubectl apply -f kube-flannel.yaml

#Install gateway CRDs
kubectl apply -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.3.0/standard-install.yaml
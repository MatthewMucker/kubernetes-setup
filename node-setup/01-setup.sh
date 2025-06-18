if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 
   exit 1
fi

set -x

#Install containerd
wget https://github.com/containerd/containerd/releases/download/v2.1.2/containerd-2.1.2-linux-amd64.tar.gz
tar Cxzvf /usr/local containerd-2.1.2-linux-amd64.tar.gz
wget https://raw.githubusercontent.com/containerd/containerd/main/containerd.service
mv containerd.service /lib/systemd/system/
systemctl daemon-reload
systemctl enable --now containerd

#Install runc
wget https://github.com/opencontainers/runc/releases/download/v1.3.0/runc.amd64
install -m 755 runc.amd64 /usr/local/sbin/runc

#Install CNI plugins
wget https://github.com/containernetworking/plugins/releases/download/v1.7.1/cni-plugins-linux-amd64-v1.7.1.tgz
mkdir -p /opt/cni/bin
tar Cxzvf /opt/cni/bin cni-plugins-linux-amd64-v1.7.1.tgz

#INSTALL kubeadm, kubelet, kubectl (v. 1.33)
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.33/deb/Release.key | gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.33/deb/ /' | tee /etc/apt/sources.list.d/kubernetes.list
apt-get update
apt-get install -y kubelet kubeadm kubectl
apt-mark hold kubelet kubeadm kubectl

#Configure cgroup driver to systemd

# Create kubeadm config file
# Replace <<HOSTNAME>> with the actual hostname of the node
sed -i "s/<<HOSTNAME>>/$(uname -n)/g" kubeadm-config.yaml

# Replace <<IP_ADDRESS>> with the actual IP address of the node
sed -i "s/<<IP_ADDRESS>>/$(hostname -I | awk '{print $1}')/g" kubeadm-config.yaml

#Create a cluster
kubeadm init --config kubeadm-config.yaml

# Copy kubeconfig to the user's home directory
export USER_HOME=$(getent passwd $SUDO_USER | cut -d: -f6)
mkdir -p $USER_HOME/.kube
cp -i /etc/kubernetes/admin.conf $USER_HOME/.kube/config
chown $(id -u):$(id -g) $USER_HOME/.kube/config

echo "please run 02-setup.sh WITHOUT SUDO to continue the setup."
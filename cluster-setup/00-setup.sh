if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 
   exit 1
fi

set -x

#Update the OS
apt-get update && sudo apt-get -y upgrade

# Install necessary packages
apt-get install -y apt-transport-https ca-certificates curl gpg

# Disable swap
sed -i 's|/swap.img|#&|' /etc/fstab

# Enable IPv4 forwarding
sed -i '/ip_forward/s/^#//g' /etc/sysctl.conf

# Enable br_netfilter
echo "br_netfilter" > /etc/modules-load.d/br_netfilter.conf


echo "Reboot the system and run 01-setup.sh to continue the setup."
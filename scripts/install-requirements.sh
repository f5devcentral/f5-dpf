#!/usr/bin/env bash

set -e

sudo apt-get update
sudo apt-get install -y curl ca-certificates make htop btop jq tmux mosh net-tools \
  bwm-ng tcpdump python3-pip unzip ipmitool nfs-common pv software-properties-common \
  locales qemu-guest-agent

sudo apt autoremove -y

# use newer version of mosh
#sudo add-apt-repository ppa:keithw/mosh-dev -y
#sudo apt update
#sudo apt list --upgradable
#sudo apt upgrade mosh -y
#sudo locale-gen en_US.UTF-8
#sudo update-locale LANG=en_US.UTF-8

echo ""
echo "installing k9s ..."
VERSION=$(curl -s https://api.github.com/repos/derailed/k9s/releases/latest | grep tag_name | cut -d '"' -f 4)
curl -Lo k9s.tar.gz "https://github.com/derailed/k9s/releases/download/${VERSION}/k9s_Linux_amd64.tar.gz"
tar -xzf k9s.tar.gz k9s
sudo mv k9s /usr/local/bin/
rm k9s.tar.gz

echo ""
echo "installing helm & kubectl ..."
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl
curl -sL https://get.helm.sh/helm-v3.17.3-linux-amd64.tar.gz | tar -xz --strip-components=1 linux-amd64/helm
sudo mv kubectl helm /usr/local/bin/
echo "removing ~/.local/share/helm cache ..."
rm -rf ~/.local/share/helm

echo ""
echo "installing Helmfile ..."
# Get latest release number
#VERSION=$(curl -s https://api.github.com/repos/helmfile/helmfile/releases/latest | grep tag_name | cut -d '"' -f4)
VERSION=1.1.2

# Download and install
curl -L "https://github.com/helmfile/helmfile/releases/download/v${VERSION}/helmfile_${VERSION#v}_linux_amd64.tar.gz" -o helmfile.tar.gz
tar -xzf helmfile.tar.gz helmfile
sudo mv helmfile /usr/local/bin/
rm helmfile.tar.gz

sudo snap install yq

#!/bin/sh


LB_IP=$(dig controlplane +short)

if [ -n "$LB_IP" ];
 then
    echo "";
 else
    echo "Could not find LB_IP from hostname 'controlplane' trying using hostname command now";
    LB_IP=$(hostname -I | cut -d " " -f 1)
fi

LB_PORT=9443

apt-get update && apt-get install -y kubeadm=1.19.0-00
apt-get install -y kubelet=1.19.0-00 kubectl=1.19.0-00

echo "Starting to install kubernetes"
echo "Command is [sudo kubeadm init --control-plane-endpoint $LB_IP:$LB_PORT --upload-certs --pod-network-cidr=10.244.0.0/16]"

sudo kubeadm init --control-plane-endpoint "$LB_IP:$LB_PORT" --upload-certs --pod-network-cidr=10.244.0.0/16

mkdir -p "$HOME/.kube sudo"
cp -i /etc/kubernetes/admin.conf "$HOME/.kube/config"
sudo chown $(id -u):$(id -g) "$HOME/.kube/config"

curl https://docs.projectcalico.org/manifests/canal.yaml -O
kubectl apply -f canal.yaml

kubectl get nodes 

ssh node01 apt-get update && apt-get install -y kubeadm=1.19.0-00
ssh node01 apt-get install -y kubelet=1.19.0-00 kubectl=1.19.0-00

CERT_KEY=$(kubeadm alpha certs certificate-key)
JOIN_COMMAND=$(kubeadm token create --print-join-command --certificate-key "$CERT_KEY")

echo "JOIN COMMAND is $JOIN_COMMAND"
ssh node01 "$JOIN_COMMAND"






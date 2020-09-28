#!/bin/sh


LB_IP=$(dig controlplane +short)
LB_PORT=9443

sudo kubeadm init --control-plane-endpoint "$LB_IP:$LB_PORT" --upload-certs --pod-network-cidr=10.244.0.0/16

mkdir -p $HOME/.kube sudo
cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

curl https://docs.projectcalico.org/manifests/canal.yaml -O
kubectl apply -f canal.yaml




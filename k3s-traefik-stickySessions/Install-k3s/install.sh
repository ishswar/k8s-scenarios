#!/usr/bin/env bash

curl -sfL https://get.k3s.io | sh -
mkdir ~/.kube
cp /etc/rancher/k3s/k3s.yaml ~/.kube/config

kubectl get nodes

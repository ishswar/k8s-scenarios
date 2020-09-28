#!/bin/bash

# This script is to install Kubernetes in Hight avalabllity setup
# This script assumes you have working load balanacer setup
# This script assumes load balanacer and first kubernetes controle plane will be runnig on same machine
# This script assumes second master node / controle-plane will be on machine name node01 and we can SSH to that server without any credentails


FIRST_MACHINE_NAME=controlplane
SECOND_MACHINE_NAME=node01
KUBERNETES_VERSION=1.19.0-00

LB_PORT=9443
LB_IP=$(dig $FIRST_MACHINE_NAME +short)


if [ -n "$LB_IP" ];
 then
    echo "";
 else
    echo "Could not find LB_IP from hostname '$FIRST_MACHINE_NAME' trying using hostname command now";
    LB_IP=$(hostname -I | cut -d " " -f 1)
fi



nc -z "$LB_IP" $LB_PORT || { echo "Issue connectiong to load balanacer @ $LB_IP:$LB_PORT - this needs to be invastigated"; exit 1; }

# Optional if you need to update kubeadm,kubelet use these two lines (as of now 1.19)
#apt-get update && apt-get install -y kubeadm=$KUBERNETES_VERSION
#apt-get install -y kubelet=$KUBERNETES_VERSION kubectl=$KUBERNETES_VERSION

echo "Starting to install kubernetes"
echo "Command is [sudo kubeadm init --control-plane-endpoint $LB_IP:$LB_PORT --upload-certs --pod-network-cidr=10.244.0.0/16]"

#sudo kubeadm init --control-plane-endpoint "$LB_IP:$LB_PORT" --pod-network-cidr=10.244.0.0/16 || { echo "kubeadm init failed ... need to invastiated"; exit 1; }
sudo kubeadm init --control-plane-endpoint "$LB_IP:$LB_PORT" --upload-certs --pod-network-cidr=10.244.0.0/16 || { echo "kubeadm init failed ... need to invastiated"; exit 1; }

echo "Setting configuration for kubectl"
echo ""
mkdir -p "$HOME/.kube"
cp -i /etc/kubernetes/admin.conf "$HOME/.kube/config"
sudo chown $(id -u):$(id -g) "$HOME/.kube/config"

kubectl version --short || { echo "kubectl configuration issue .. need to be invastigated"; exit 1; }
echo ""

echo "Installing CNI for cluster"
echo ""

curl https://docs.projectcalico.org/manifests/canal.yaml -O
kubectl apply -f canal.yaml

echo "Will wait for Node $(hostname) to post for Ready"
SECONDS=0
while : ;
 do
  if [ $(kubectl get nodes $(hostname) -o jsonpath='{range .items[*].status.conditions[?(@.type=="Ready")]}{.reason}{end}') != "KubeletReady" ]; then
  echo "Node/kubelet on Host $(hostname) is not yet Ready ... waited $SECONDS(seconds)";

  if [ $(( $SECONDS % 2 )) -eq 0 ]; then
      echo "Reason for not ready :"
      kubectl get nodes $(hostname) -o jsonpath='{range .status.conditions[?(@.type=="Ready")]}{.message}{"\n"}{end}'
  fi

  sleep 5;
  if [ $SECONDS -gt 80 ]; then
     echo "Waited $SECONDS - will exit now - this needs to be invastigated"
     exit 1;
     break;
  fi
  elif [ $(kubectl get nodes $(hostname) -o jsonpath='{range .status.conditions[?(@.type=="Ready")]}{.reason}{end}') = "KubeletReady" ]; then
    echo "Node/kubelet is posted Ready now"
    break;
  fi
 done
#kubectl get nodes $(hostname) -o jsonpath='{range .status.conditions[?(@.type=="Ready")]}{.reason}{"\n"}{end}'
#KubeletNotReady
#KubeletReady

echo "#########################################"
echo "##### Done with first controleplane #####"
echo "#########################################"

echo ""
echo "Starting to work on second controleplane on node machine"

echo ""
echo "Upgrading kubeadm,kubelet and kubectl on remote machine"
echo ""

# SSH into remote host and run commands
# comment out next wo lines if you don't want to update kubeadm , kubelet on remote machine to be at $KUBERNETES_VERSION
ssh $SECOND_MACHINE_NAME apt-get update && apt-get install -y kubeadm=$KUBERNETES_VERSION
ssh $SECOND_MACHINE_NAME apt-get install -y kubelet=$KUBERNETES_VERSION kubectl=$KUBERNETES_VERSION

echo "Generating joining command that remote kubeadm can use to join this cluster"
#CERT_KEY=$(kubeadm alpha certs certificate-key) <-- This should work in 1.19 but it does not (or failed for me)
CERT_KEY=$(kubeadm init phase upload-certs --upload-certs | sed -n 3p)
CONTROL-PLANE_JOIN_COMMAND=$(kubeadm token create --print-join-command --certificate-key "$CERT_KEY")
#

echo "JOIN COMMAND is [$CONTROL-PLANE_JOIN_COMMAND]"
echo $CONTROL-PLANE_JOIN_COMMAND > join.text
echo "Running joining command from remote machine"
echo ""
ssh $SECOND_MACHINE_NAME "$CONTROL-PLANE_JOIN_COMMAND"


echo "Checking the status of master nodes"
echo ""

NUMBER_READY_NODES=$(kubectl get nodes -o jsonpath='{range .items[*]}{range .status.conditions[?(@.type=="Ready")]}{.reason}{"\n"}{end}{end}' | grep "KubeletReady" | wc -l)
if [ "$NUMBER_READY_NODES" -eq 2 ]; then
  echo "Sucess - we now have $NO_READY_NODES master nodes"
  kubectl get nodes
fi




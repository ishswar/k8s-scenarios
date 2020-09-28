#!/bin/bash


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

sudo kubeadm init --control-plane-endpoint "$LB_IP:$LB_PORT" --upload-certs --pod-network-cidr=10.244.0.0/16 || { echo "kubeadm init failed ... need to invastiated"; exit 1; }

echo "Setting configuration for kubectl"
echo ""
mkdir -p "$HOME/.kube"
cp -i /etc/kubernetes/admin.conf "$HOME/.kube/config"
sudo chown $(id -u):$(id -g) "$HOME/.kube/config"

kubectl version --short || { echo "kubectl configuration issue .. need to be invastigated"; exit 1; }

echo "Installing CNI for cluster"
echo ""

curl https://docs.projectcalico.org/manifests/canal.yaml -O
kubectl apply -f canal.yaml

echo "Will wait for Node $(hostname) to post for Ready"
SECONDS=0
while : ;
 do
  if [ $(kubectl get nodes $(hostname) -o jsonpath='{range .status.conditions[?(@.type=="Ready")]}{.reason}{end}') != "KubeletReady" ]; then
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
ssh node01 apt-get update && apt-get install -y kubeadm=1.19.0-00
ssh node01 apt-get install -y kubelet=1.19.0-00 kubectl=1.19.0-00

echo "Generating joining command that remote kubeadm can use to join this cluster"
CERT_KEY=$(kubeadm alpha certs certificate-key)
JOIN_COMMAND=$(kubeadm token create --print-join-command --certificate-key "$CERT_KEY")
#

echo "JOIN COMMAND is [$JOIN_COMMAND]"
echo "Running joining command from remote machine"
ssh node01 "$JOIN_COMMAND"






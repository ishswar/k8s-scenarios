#!/usr/bin/env bash

kubeadm init --pod-network-cidr=10.244.0.0/16
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
curl https://docs.projectcalico.org/manifests/canal.yaml -O
kubectl apply -f canal.yaml
sleep 10
kubectl get pods -n kube-system
sleep 10
kubectl get pods -n kube-system
sleep 10
while (! ls -la /tmp2 > /dev/null 2>&1); do date; sleep 5; done
kubectl get pods -n kube-system
kubectl taint node $(hostname) node-role.kubernetes.io/master:NoSchedule-
kubectl run tester --image=nginx
sleep 5
kubectl get pods

apt-get install -y etcd-client

CACERT=$(cat /etc/kubernetes/manifests/etcd.yaml | grep peer-trusted-ca-file | cut -d= -f2)
CLIENT_KEY=$(cat /etc/kubernetes/manifests/etcd.yaml | grep peer-key-file | cut -d= -f2)
CLIENT_CERT=$(cat /etc/kubernetes/manifests/etcd.yaml | grep peer-cert-file | cut -d= -f2)
ENDPOINTS=$(cat /etc/kubernetes/manifests/etcd.yaml | grep listen-client-urls | cut -d= -f2)

ETCDCTL_API=3 etcdctl --endpoints $ENDPOINTS snapshot save snapshot.db --cacert $CACERT --cert $CLIENT_CERT --key $CLIENT_KEY

ETCDCTL_API=3 etcdctl snapshot restore snapshot.db

mv /var/lib/etcd /var/lib/etcd.old; docker stop $(docker ps | grep etcd | cut -d" " -f1) ; mkdir -p  /var/lib/etcd ; cp -rf ./default.etcd/* /var/lib/etcd

mv ./default.etcd /var/lib/etcd
ls -la /var/lib/etcd
kubectl delete -n kube-system pod etcd-$(hostname) --force --grace-period=0

mv ./default.etcd /var/lib/etcd
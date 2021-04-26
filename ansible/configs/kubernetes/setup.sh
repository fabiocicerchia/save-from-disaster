#!/bin/bash

GO111MODULE="on" go get sigs.k8s.io/kind@v0.10.0

kind create cluster --config cluster/cluster.yaml
kubectl label nodes --all kubernetes.io/role=node
kubectl taint nodes --all node-role.kubernetes.io/master-

# https://www.thehumblelab.com/kind-and-metallb-on-mac
if [ "$(ifconfig|grep tap)" = "" ]; then
    brew tap homebrew/cask
    brew install --cask tuntap
    git clone https://github.com/AlmirKadric-Published/docker-tuntap-osx.git
    ./docker-tuntap-osx/sbin/docker_tap_install.sh
    ./docker-tuntap-osx/sbin/docker_tap_up.sh
    sudo route -v add -net 172.21.0.1 -netmask 255.255.0.0 10.0.75.2
fi

# metallb
if [ "$(kubectl get ns metallb-system)" = "" ]; then
    kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/master/manifests/namespace.yaml
    kubectl create secret generic -n metallb-system memberlist --from-literal=secretkey="$(openssl rand -base64 128)"
    kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/master/manifests/metallb.yaml
    kubectl apply -f metallb/configmap.yaml
fi

kubectl apply -f cluster/storageclass.yaml

kubectl apply -f cluster/mysql.yaml

# cert-manager
kubectl apply --validate=false -f https://github.com/jetstack/cert-manager/releases/download/v1.3.1/cert-manager.yaml
kubectl apply -f issuer

# ingress-nginx
if [ "$(kubectl get ns ingress-nginx)" = "" ]; then
    kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/master/deploy/static/provider/kind/deploy.yaml
    kubectl wait --namespace ingress-nginx --for=condition=ready pod --selector=app.kubernetes.io/component=controller --timeout=90s
fi

# PROJECTS
# REF: https://github.com/kubernetes-sigs/kind/issues/99

projects=(example wordpress)

for project in "${projects[@]}"; do

    kubectl apply -f $project/namespace.yaml
    kubectl apply -f cluster/memory-defaults.yaml --namespace=app-$project
    kubectl apply -f $project

done

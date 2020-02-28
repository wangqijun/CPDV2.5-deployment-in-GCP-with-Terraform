#!/bin/bash 

kubectl -n default create -f ./nfs-deployment.yaml
kubectl -n default create -f ./nfs-storage-class.yaml
oc adm policy add-scc-to-user anyuid -z nfs-client-provisioner
kubectl -n default create -f ./cluster-role-binding-nfs.yaml

#!/bin/bash 

oc -n default create -f ./nfs-deployment.yaml
oc -n default create -f ./nfs-storage-class.yaml
oc adm policy add-scc-to-user anyuid -z nfs-client-provisioner
oc -n default create -f ./cluster-role-binding-nfs.yaml

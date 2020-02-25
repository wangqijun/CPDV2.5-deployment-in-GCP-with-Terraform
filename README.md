# OCP-deployment-in-GCP-with-Terraform

This documentation will walk throught the steps to deploy an OCP instance from scratch in Google Cloud Platform, from provisioning the vms, system prerequisites, all the way to OCP installation.

## Deployment Architecture.

![Deployment Architecture](./img/OCP.png?raw=true)

## Settings in Google Cloud Platform

Before you start you need to create a project on Google Cloud Platform, then continue to create the service account and generate the private key and download the credential as JSON file.

1 Reference link: 

https://techbloc.net/archives/3681

2 Create the new project:

![Create the new project](./img/create-project.jpg?raw=true)

3 Create the service account:

![Create the service account](./img/create-sa.jpg?raw=true)

4 Give the service account compute admin and storage object creator permissions:

![service account permission](./img/sa-permission.jpg?raw=true)

5 Create a storage bucket:

![create a storage bucket](./img/create-bucket.jpg?raw=true)

6 Set bucket permissions:

![set bucket permission](./img/bucket-permission.jpg?raw=true)

7 Add service account to bucket permissions:

![bucket add_permission](./img/bucket-sa-permission.jpg?raw=true)

8 Create Json credential files for terraform.

![Create Json credential](./img/json-create.jpg?raw=true)

## Provision VMs with Terraform.


1 Download this github repo.

2 Go to "terraform" folder.

3 Change the "cp4d-h-pilot-31b794343102.json" to your own credential file, which can be downloaded from GCP web console.

4 Change the settings in variable.tf and gce.tf, including vm type, disk size, and node number according to sizing requirement.

5 Install terraform if your system doesn't have.

6 Run "terraform init".

7 Run "terraform plan"

8 Run "terraform apply"

## Configure VMs
 

1 Copy the contents of "user-setup.sh" in folder 'scripts' and run it in each node of the cluster (this shell script will create a new user call "ocp" and set password of it, and it also configure the OS to accept ssh login by username and password).

2 Copy the "scripts" folder to bastion node by:

    scp -r ./scripts ocp@<bastion node public ip>:/

3 Ssh login to the bastion node and then go to 'Scripts' folder and modify "username", "password", and "pool id" in file "register-repo.sh" and then run it.

     bash -x register-repo.sh

3 In bastion node, run following commands to install ansible and openshift-ansible:

      sudo yum -y install python-pip
      sudo pip install ansible==2.6.5
      sudo pip install --upgrade setuptools
      sudo yum -y install openshift-ansible
      
  Check ansible version to make sure it's 2.6.5:
  
      sudo ansible --version
      
      
4 Generate key files in bastion node.

       echo "" | ssh-keygen -t rsa -N ""
      
5 Go to 'Scripts' folder and run "ssh-copy-id.sh" to copy public key to all the other nodes:

      bash -x ssh-copy-id.sh 
      
      
## Set up NFS service in NFS node


 1 Copy disk.sh from scripts folder to bastion node and then copy it from bastion node to nfs node.
 
 2 Run the disk.sh to create a new nfs mount path from the raw disk:
 
     sudo bash -x ./disk.sh /dev/sdb /nfs
     
 3 Install and configure NFS service:
 
 
    sudo yum install -y nfs-utils
    sudo systemctl enable rpcbind
    sudo systemctl enable nfs-server
    sudo systemctl start rpcbind
    sudo systemctl start nfs-server
    sudo chmod -R 755 /nfs
    sudo firewall-cmd --permanent --zone=public --add-service=nfs
    sudo firewall-cmd --permanent --add-service=rpc-bind

  4 Configure NFS experts file.
  
     sudo vi /etc/exports
     

     /nfs *(rw,sync,no_root_squash)
     
     

     sudo systemctl restart nfs-server
     
   5 Verify NFS service works well.

 
     showmount -e nfs01

## Create Inventory file.


  Inventory file template with NFS and Crio enabled(Portworx required):
   ```
# define openshift components
[OSEv3:children]
masters
nodes
nfs
etcd
lb

# define openshift variables
[OSEv3:vars]
containerized=true
openshift_deployment_type=openshift-enterprise
openshift_hosted_registry_storage_volume_size=50Gi
openshift_docker_insecure_registries="172.30.0.0/16"
openshift_disable_check=docker_storage,docker_image_availability,package_version
oreg_url=registry.access.redhat.com/openshift3/ose-${component}:${version}
openshift_master_identity_providers=[{'name': 'htpasswd_auth', 'login': 'true', 'challenge': 'true', 'kind': 'HTPasswdPasswordIdentityProvider'}]
openshift_master_htpasswd_users={'ocadmin': '$apr1$CdyzN7vS$wM6gchgqURLe1A7gQRbIi0'}
ansible_ssh_user=ocp
ansible_become=true
nsible_ssh_common_args='-o StrictHostKeyChecking=no'
ansible_service_broker_install=False

#openshift_release=v3.11
#openshift_image_tag=v3.11.146

os_firewall_use_firewalld=True

openshift_master_cluster_method=native
openshift_master_cluster_hostname=ocp-gcp.ibmcpdswat.com
openshift_master_cluster_public_hostname=ocp-gcp.ibmcpdswat.com
#osm_cluster_network_cidr=172.16.0.0/16
#openshift_public_hostname=master01.us-east1-b.c.cp4d-h-pilot.internal
openshift_master_default_subdomain=apps.ocp-gcp.ibmcpdswat.com
openshift_master_api_port=8443
openshift_master_console_port=8443

# CRI-O
openshift_use_crio=True
openshift_use_crio_only=True

# NFS Host Group
# An NFS volume will be created with path "nfs_directory/volume_name"
# on the host within the [nfs] host group.  For example, the volume
# path using these options would be "/exports/registry".  "exports" is
# is the name of the export served by the nfs server.  "registry" is
# the name of a directory inside of "/exports".
openshift_hosted_registry_storage_kind=nfs
openshift_hosted_registry_storage_access_modes=['ReadWriteMany']
# nfs_directory must conform to DNS-1123 subdomain must consist of lower case
# alphanumeric characters, '-' or '.', and must start and end with an alphanumeric character
openshift_hosted_registry_storage_nfs_directory=/nfs
openshift_hosted_registry_storage_nfs_options='*(rw,no_root_squash,anonuid=1000,anongid=2000)'
openshift_hosted_registry_storage_volume_name=registry
openshift_hosted_registry_storage_volume_size=200Gi


[masters]
master01.us-east1-b.c.cp4d-h-pilot.internal openshift_ip=10.0.0.2 openshift_schedulable=true
master02.us-east1-b.c.cp4d-h-pilot.internal openshift_ip=10.0.0.5 openshift_schedulable=true
master03.us-east1-b.c.cp4d-h-pilot.internal openshift_ip=10.0.0.4 openshift_schedulable=true

[etcd]
master01.us-east1-b.c.cp4d-h-pilot.internal openshift_ip=10.0.0.2
master02.us-east1-b.c.cp4d-h-pilot.internal openshift_ip=10.0.0.5
master03.us-east1-b.c.cp4d-h-pilot.internal openshift_ip=10.0.0.4

[nodes]
master01.us-east1-b.c.cp4d-h-pilot.internal openshift_ip=10.0.0.2 openshift_schedulable=true openshift_node_group_name='node-config-master-infra-crio'
master02.us-east1-b.c.cp4d-h-pilot.internal openshift_ip=10.0.0.5 openshift_schedulable=true openshift_node_group_name='node-config-master-infra-crio'
master03.us-east1-b.c.cp4d-h-pilot.internal openshift_ip=10.0.0.4 openshift_schedulable=true openshift_node_group_name='node-config-master-infra-crio'
worker01.us-east1-b.c.cp4d-h-pilot.internal openshift_ip=10.0.1.5 openshift_schedulable=true openshift_node_group_name='node-config-compute'
worker02.us-east1-b.c.cp4d-h-pilot.internal openshift_ip=10.0.1.2 openshift_schedulable=true openshift_node_group_name='node-config-compute'
worker03.us-east1-b.c.cp4d-h-pilot.internal openshift_ip=10.0.1.4 openshift_schedulable=true openshift_node_group_name='node-config-compute'


# nfs server
[nfs]
nfs01.us-east1-b.c.cp4d-h-pilot.internal openshift_ip=10.0.1.3
      
```
  
Invertory file with NFS and Crio disabled:

```
# define openshift components
[OSEv3:children]
masters
nodes
nfs
etcd
lb

# define openshift variables
[OSEv3:vars]
containerized=true
openshift_deployment_type=openshift-enterprise
openshift_hosted_registry_storage_volume_size=50Gi
openshift_docker_insecure_registries="172.30.0.0/16"
openshift_disable_check=docker_storage,docker_image_availability,package_version
oreg_url=registry.access.redhat.com/openshift3/ose-${component}:${version}
openshift_master_identity_providers=[{'name': 'htpasswd_auth', 'login': 'true', 'challenge': 'true', 'kind': 'HTPasswdPasswordIdentityProvider'}]
openshift_master_htpasswd_users={'ocadmin': '$apr1$CdyzN7vS$wM6gchgqURLe1A7gQRbIi0'}
ansible_ssh_user=ocp
ansible_become=true
nsible_ssh_common_args='-o StrictHostKeyChecking=no'
ansible_service_broker_install=False

#openshift_release=v3.11
#openshift_image_tag=v3.11.146

os_firewall_use_firewalld=True

openshift_master_cluster_method=native
openshift_master_cluster_hostname=ocp-gcp.ibmcpdswat.com
openshift_master_cluster_public_hostname=ocp-gcp.ibmcpdswat.com
#osm_cluster_network_cidr=172.16.0.0/16
#openshift_public_hostname=master01.us-east1-b.c.cp4d-h-pilot.internal
openshift_master_default_subdomain=apps.ocp-gcp.ibmcpdswat.com
openshift_master_api_port=8443
openshift_master_console_port=8443

# CRI-O
openshift_use_crio=false
openshift_use_crio_only=false

# NFS Host Group
# An NFS volume will be created with path "nfs_directory/volume_name"
# on the host within the [nfs] host group.  For example, the volume
# path using these options would be "/exports/registry".  "exports" is
# is the name of the export served by the nfs server.  "registry" is
# the name of a directory inside of "/exports".
openshift_hosted_registry_storage_kind=nfs
openshift_hosted_registry_storage_access_modes=['ReadWriteMany']
# nfs_directory must conform to DNS-1123 subdomain must consist of lower case
# alphanumeric characters, '-' or '.', and must start and end with an alphanumeric character
openshift_hosted_registry_storage_nfs_directory=/nfs
openshift_hosted_registry_storage_nfs_options='*(rw,no_root_squash,anonuid=1000,anongid=2000)'
openshift_hosted_registry_storage_volume_name=registry
openshift_hosted_registry_storage_volume_size=200Gi


[masters]
master01.us-east1-b.c.cp4d-h-pilot.internal openshift_ip=10.0.0.2 openshift_schedulable=true
master02.us-east1-b.c.cp4d-h-pilot.internal openshift_ip=10.0.0.5 openshift_schedulable=true
master03.us-east1-b.c.cp4d-h-pilot.internal openshift_ip=10.0.0.4 openshift_schedulable=true

[etcd]
master01.us-east1-b.c.cp4d-h-pilot.internal openshift_ip=10.0.0.2
master02.us-east1-b.c.cp4d-h-pilot.internal openshift_ip=10.0.0.5
master03.us-east1-b.c.cp4d-h-pilot.internal openshift_ip=10.0.0.4

[nodes]
master01.us-east1-b.c.cp4d-h-pilot.internal openshift_ip=10.0.0.2 openshift_schedulable=true openshift_node_group_name='node-config-master-infra'
master02.us-east1-b.c.cp4d-h-pilot.internal openshift_ip=10.0.0.5 openshift_schedulable=true openshift_node_group_name='node-config-master-infra'
master03.us-east1-b.c.cp4d-h-pilot.internal openshift_ip=10.0.0.4 openshift_schedulable=true openshift_node_group_name='node-config-master-infra'
worker01.us-east1-b.c.cp4d-h-pilot.internal openshift_ip=10.0.1.5 openshift_schedulable=true openshift_node_group_name='node-config-compute'
worker02.us-east1-b.c.cp4d-h-pilot.internal openshift_ip=10.0.1.2 openshift_schedulable=true openshift_node_group_name='node-config-compute'
worker03.us-east1-b.c.cp4d-h-pilot.internal openshift_ip=10.0.1.4 openshift_schedulable=true openshift_node_group_name='node-config-compute'


# nfs server
[nfs]
nfs01.us-east1-b.c.cp4d-h-pilot.internal openshift_ip=10.0.1.3

```
   
## Prepare for OCP installation.

   
   1 Copy the "playbook" folder to bastion node and go to the "playbook" folder.

   2 Install subscription-manager in each node:
   
      ansible-playbook -i ../inventory-nfs-crio install-subscription-manager.yml 

   3 Register each node with Redhat account. Make sure you have Redhat subscription account before this step:

      ansible-playbook -i ../inventory-nfs-crioredhat-register-machines.yml

   4 Redhat repo set up:

      ansible-playbook -i ../inventory-nfs-crioredhat-rhos-reposubscribe.yml

   5 Install basic package for OCP:
   
      ansible-playbook -i ../inventory-nfs-crioinstall-base-package.yml

   6 Install openshift-ansible in each node:

     ansible-playbook -i ../inventory-nfs-crio install-ansible.yml 

   7 Install docker in each node:

      ansible-playbook -i ../inventory-nfs-crio install-docker.yml
     
   8 Configure docker storage in each node:  

      ansible-playbook -i ../inventory-nfs-crio docker_storage.yml
      
   9 Check the statue of clock syncronization in each node by:
   
      ansible-playbook -i ../inventory-nfs-crio check-clock.yaml
      
   10 Check the status of Network Manager by:
   
      ansible-playbook -i ../inventory-nfs-crio check-NetworkManager.yaml
      
 ## Prerequisites check and kick off the deployment. 
 
   1 Run "prerequisites.yml" to check each node and install required package if needed.

     ansible-playbook -i ../inventory-nfs-crio /usr/share/ansible/openshift-ansible/playbooks/prerequisites.yml
     
   2 Run "deploy-cluster.yml" to kick off the installation.
   
     ansible-playbook -i ../inventory-nfs-crio /usr/share/ansible/openshift-ansible/playbooks/deploy_cluster.yml 
       
 ## Deployment result.
 
   1 After deployment, you should see following message:
   
   
     INSTALLER STATUS    *********************************************************************************************************************************************************************
     Initialization               : Complete (0:00:31)
     Health Check                 : Complete (0:00:16)
     Node Bootstrap Preparation   : Complete (0:37:02)
     etcd Install                 : Complete (0:01:06)
     Master Install               : Complete (0:07:01)
     Master Additional Install    : Complete (0:05:32)
     Node Join                    : Complete (0:00:55)
     GlusterFS Install            : Complete (0:04:27)
     Hosted Install               : Complete (0:01:00)
     Cluster Monitoring Operator  : Complete (0:01:14)
     Web Console Install          : Complete (0:00:23)
     Console Install              : Complete (0:00:22)
     Metrics Install              : Complete (0:02:17)
     metrics-server Install       : Complete (0:00:47)
     Logging Install              : Complete (0:02:19)
     Service Catalog Install      : Complete (0:02:47)
     
   2 Get OCP web console address by running following command:
   
      oc describe configmaps console-config  -n openshift-console
      
   3 Login to OCP web console (admin/password):
   
   ![OCP web console](./img/webconsole.jpg?raw=true)
     
     
   4 Login to OCP from terminal:
   
     oc login -u system:admin
     oc get no
     oc get po --all-namespaces

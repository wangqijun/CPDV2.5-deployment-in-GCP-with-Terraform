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

1 Go to "scripts" folder.

2 Copy the contents of "user-setup.sh" and run it in each node of the cluster.

3 Go to 'Scripts' folder and modify "username", "password", and "pool id" in file "register-repo.sh" and then copy it to bastion node, and run it.

     bash -x register-repo.sh

3 In bastion node, run following commands to install ansible and openshift-ansible:

      sudo yum -y install python-pip
      sudo pip install ansible==2.6.5
      sudo pip install --upgrade setuptools
      sudo yum -y install openshift-ansible
      
4 Generate key files in bastion node.

       echo "" | ssh-keygen -t rsa -N ""
      
5 Copy "ssh-copy-id.sh" to bastion node and run it to copy public key to all the other nodes:

      bash -x ssh-copy-id.sh 
      

## Create Inventory file.


   Copy the "openshift-inventory" file and edit some of the parameters accordingly, including:
   
      "oreg_auth_user"
      "oreg_auth_password"
   
## Prepare for OCP installation.

   
   1 Copy the "playbook" folder to bastion node.

   2 Install subscription-manager in each node:
   
      ansible-playbook -i ../openshift_inventory install-subscription-manager.yml 

   3 Register each node with Redhat account. Make sure you have Redhat subscription account before this step:

      ansible-playbook -i ../openshift_inventory redhat-register-machines.yml

   4 Redhat repo set up:

      ansible-playbook -i ../openshift_inventory redhat-rhos-reposubscribe.yml

   5 Install basic package for OCP:
   
      ansible-playbook -i ../openshift_inventory install-base-package.yml

   6 Install openshift-ansible in each node:

     ansible-playbook -i ../openshift_inventory install-ansible.yml 

   7 Install docker in each node:

      ansible-playbook -i ../openshift_inventory install-docker.yml
     
   8 Configure docker storage in each node:  

      ansible-playbook -i ../openshift_inventory docker_storage.yml
      
 ## Prerequisites check and kick off the deployment. 
 
   1 Run "prerequisites.yml" to check each node and install required package if needed.

     ansible-playbook -i ../openshift_inventory /usr/share/ansible/openshift-ansible/playbooks/prerequisites.yml
     
   2 Run "deploy-cluster.yml" to kick off the installation.
   
     ansible-playbook -i ../openshift_inventory /usr/share/ansible/openshift-ansible/playbooks/deploy_cluster.yml 
       
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

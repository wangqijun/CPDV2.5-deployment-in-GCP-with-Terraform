sudo yum -y install subscription-manager
sudo subscription-manager register --username <redhat register user name> --password <password of the user name>
sudo subscription-manager refresh
sudo subscription-manager attach --pool=<pool id>
sudo subscription-manager repos --disable="*"
sudo sed -i -e "s/^enabled=1/enabled=0/" /etc/yum.repos.d/google-cloud.repo
sudo sed -i -e "s/^enabled=1/enabled=0/" /etc/yum.repos.d/rh-cloud.repo
sudo sed -i -e "s/^enabled=1/enabled=0/" /etc/yum.repos.d/epel.repo 
sudo subscription-manager repos     --enable="rhel-7-server-rpms"     --enable="rhel-7-server-extras-rpms"     --enable="rhel-7-server-ose-3.11-rpms"     --enable="rhel-7-server-ansible-2.6-rpms"


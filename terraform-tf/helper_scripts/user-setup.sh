sudo useradd ocp
echo "password" |sudo  passwd --stdin ocp
sudo sed -i "\$aocp ALL=(ALL) NOPASSWD: ALL" /etc/sudoers
sudo sed -i "s/#PasswordAuthentication yes/PasswordAuthentication yes/g" /etc/ssh/sshd_config
sudo service sshd restart
 

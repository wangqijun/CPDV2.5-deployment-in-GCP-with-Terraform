sudo useradd ocp
echo "<password of the installation username>" |sudo  passwd --stdin <installation username>
sudo sed -i "\$aocp ALL=(ALL) NOPASSWD: ALL" /etc/sudoers
sudo sed -i "s/#PasswordAuthentication yes/PasswordAuthentication yes/g" /etc/ssh/sshd_config
sudo service sshd restart
 

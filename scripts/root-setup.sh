echo <root password> |sudo  passwd --stdin root
sudo sed -i "s/#PasswordAuthentication yes/PasswordAuthentication yes/g" /etc/ssh/sshd_config
sudo sed -i "s/PermitRootLogin no/PermitRootLogin yes/g" /etc/ssh/sshd_config
sudo service sshd restart
 

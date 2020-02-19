for host in bastion Master01 Master02 Master03 nfs01  worker01 worker02 worker03;
     do ssh-copy-id -i ~/.ssh/id_rsa.pub $host; 
  done

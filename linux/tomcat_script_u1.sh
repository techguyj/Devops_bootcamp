#!/bin/bash
wget http://www-eu.apache.org/dist/tomcat/tomcat-9/v9.0.44/bin/apache-tomcat-9.0.44.tar.gz -P /tmp
sudo tar xf /tmp/apache-tomcat-9*.tar.gz -C /home/usertest2/tomcat
sudo ln -s /home/usertest2/tomcat/apache-tomcat-9.0.44 /home/usertest2/tomcat/latest
sudo chown -RH usertest2:testgroup /home/usertest2/tomcat/latest
sudo sh -c 'chmod +x /home/usertest2/tomcat/latest/bin/*.sh'
sudo chmod 755 -R /home/usertest2
sudo systemctl start tomcat && sudo systemctl enable tomcat
sudo firewall-cmd --zone=public --permanent --add-port=8080/tcp
sudo firewall-cmd --reload

sudo cat << EOF > /tmp/tomcat.service

[Unit]
Description=Tomcat 9 servlet container
After=network.target

[Service]
Type=forking

User=usertest2
Group=testgroup

Environment="JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64/"
Environment="JAVA_OPTS=-Djava.security.egd=file:///dev/urandom -Djava.awt.headless=true"

Environment="CATALINA_BASE=/home/usertest2/tomcat/latest"
Environment="CATALINA_HOME=/home/usertest2/tomcat/latest"
Environment="CATALINA_PID=/home/usertest2/tomcat/latest/temp/tomcat.pid"
Environment="CATALINA_OPTS=-Xms512M -Xmx1024M -server -XX:+UseParallelGC"

ExecStart=/home/usertest2/tomcat/latest/bin/startup.sh
ExecStop=/home/usertest2/tomcat/latest/bin/shutdown.sh

[Install]
WantedBy=multi-user.target
EOF

sudo rsync -ravh /tmp/tomcat.service /etc/systemd/system/tomcat.service



# Attach a new disk using this guide
# https://dev.to/juttayaya/add-hard-disk-to-vmware-centos-7-vm-22m8
(
echo n  # Add a new partition
echo p  # Primary partition
echo    # Partition number
echo    # First sector (Accept default: 1)
echo    # Last sector (Accept default: varies)
echo t  # Change the partition type
echo 8e # LVM
echo w  # Write changes
) | sudo fdisk /dev/sdb
sudo pvcreate /dev/sdb1
sudo vgcreate vgNew /dev/sdb1
sudo lvcreate -n lvNew -l +100%FREE vgNew
sudo mkfs.xfs /dev/vgNew/lvNew
sudo mkdir -p /home/usertest2/tomcat/website
sudo mount /dev/vgNew/lvNew /home/usertest2/tomcat/website

sudo cat << EOF > /tmp/index.html
<html>
 <head>
 </head>
 <body>
   <h1>Hello World<h1>
 </body>
</html>
EOF

sudo rsync -ravh /tmp/index.html /home/usertest2/tomcat/website/index.html
sudo rsync -ravh /home/usertest2/tomcat/website/index.html /home/usertest2/tomcat/latest/webapps/ROOT

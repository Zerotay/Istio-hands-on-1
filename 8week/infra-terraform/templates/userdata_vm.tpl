#!/bin/bash
hostnamectl --static set-hostname forum-vm
echo 'alias vi=vim' >> /etc/profile
echo "sudo su -" >> /home/ubuntu/.bashrc
ln -sf /usr/share/zoneinfo/Asia/Seoul /etc/localtime
systemctl stop ufw && systemctl disable ufw
systemctl stop apparmor && systemctl disable apparmor
apt update && apt-get install net-tools ngrep jq tree unzip apache2 -y
echo "${private_ip}  forum-vm" >> /etc/hosts

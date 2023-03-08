#!/bin/bash

sudo apt install sshpass python3-paramiko git
sudo apt-add-repository ppa:ansible/ansible
sudo apt update
sudo apt install ansible
ansible --version

cat >> ~/.ansible.cfg << EOF                                                               
[defaults]
host_key_checking = false
EOF
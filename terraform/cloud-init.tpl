#cloud-config
apt_update: true
packages:
  - git
  - python3-pip
  - apt-transport-https
  - ca-certificates
  - curl
  - gnupg-agent
  - software-properties-common

users:
  - name: azureuser
    groups: docker
    shell: /bin/bash
    sudo: ['ALL=(ALL) NOPASSWD:ALL']
    lock_passwd: false

runcmd:
  - curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
  - echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" > /etc/apt/sources.list.d/docker.list
  - apt update
  - apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
  - reboot

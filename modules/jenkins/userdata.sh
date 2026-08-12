#!/bin/bash
set -eux

# Log user-data output
exec > >(tee /var/log/user-data.log | logger -t user-data) 2>&1

# Update system
dnf update -y

# Install required packages
dnf install -y docker git unzip wget

# Start Docker
systemctl enable docker
systemctl start docker
usermod -aG docker ec2-user

# Install Java 21 (required by latest Jenkins)
dnf install -y java-21-amazon-corretto

# Add Jenkins repository
wget -O /etc/yum.repos.d/jenkins.repo \
https://pkg.jenkins.io/redhat-stable/jenkins.repo

rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io-2023.key

# Install Jenkins
dnf install -y jenkins

# Enable and start Jenkins
systemctl enable jenkins
systemctl start jenkins

# Install Terraform
dnf install -y yum-utils

yum-config-manager --add-repo \
https://rpm.releases.hashicorp.com/AmazonLinux/hashicorp.repo

dnf install -y terraform

# Install AWS CLI v2
cd /tmp
wget https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip

unzip -o awscli-exe-linux-x86_64.zip

./aws/install

# Restart Jenkins after all installations
systemctl restart jenkins

# Verify installations
java -version
terraform version
aws --version
systemctl status jenkins --no-pager
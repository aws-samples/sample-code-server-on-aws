#!/bin/bash
echo "INFO: Starting UserData script execution"

# Install AWS CLI
echo "INFO: Installing AWS CLI prerequisites"
apt-get -o DPkg::Lock::Timeout=-1 update
DEBIAN_FRONTEND=noninteractive apt-get -o DPkg::Lock::Timeout=-1 install -y curl unzip
echo "INFO: Prerequisites installed, downloading AWS CLI"
curl -fsSL https://awscli.amazonaws.com/awscli-exe-linux-$(uname -m).zip -o /tmp/aws-cli.zip
echo "INFO: Extracting AWS CLI"
unzip -q -d /tmp /tmp/aws-cli.zip
echo "INFO: Installing AWS CLI"
sudo /tmp/aws/install
rm -rf /tmp/aws /tmp/aws-cli.zip
echo "INFO: AWS CLI installation complete"
aws --version

# Install code-server
echo "INFO: Installing code-server"
curl -fOL https://github.com/coder/code-server/releases/download/v${version}/code-server_${version}_amd64.deb
sudo dpkg -i code-server_${version}_amd64.deb
echo "INFO: Enabling and starting code-server"
sudo systemctl enable --now code-server@ubuntu
sleep 30

# Configure password
echo "INFO: Configuring code-server"
# sed -i.bak 's/auth: password/auth: none/' /home/ubuntu/.config/code-server/config.yaml
# Expose code server service 
sed -i.bak 's/bind-addr: 127.0.0.1:8080/bind-addr: 0.0.0.0:8080/' /home/ubuntu/.config/code-server/config.yaml

# Restart code server
echo "INFO: Restarting code-server"
sudo systemctl restart code-server@ubuntu

# Install extension amazonwebservices.amazon-q-vscode
echo "INFO: Installing Amazon Q extension"
sudo -u ubuntu code-server --install-extension amazonwebservices.amazon-q-vscode

# Restart code server
echo "INFO: Final restart of code-server"
sudo systemctl restart code-server@ubuntu

# Store password in SSM Parameter Store for easy retrieval
echo "INFO: Storing password in SSM Parameter Store"
sleep 10  # Wait for config file to be fully written
CODE_SERVER_PASSWORD=$(sudo grep "^password:" /home/ubuntu/.config/code-server/config.yaml | cut -d' ' -f2)
echo "INFO: Extracted password, creating SSM parameter"
aws ssm put-parameter \
  --name "/code-server/password" \
  --value "$CODE_SERVER_PASSWORD" \
  --type "SecureString" \
  --region ${region} \
  --overwrite
echo "INFO: SSM parameter creation complete"
echo "INFO: UserData script execution finished"

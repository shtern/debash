#!/bin/bash

# Download and unpack Nerd Fonts
wget https://github.com/ryanoasis/nerd-fonts/releases/download/v3.1.1/Meslo.zip -O /tmp/Meslo.zip
unzip /tmp/Meslo.zip -d /tmp/Meslo
sudo mv /tmp/Meslo/*.ttf /usr/share/fonts/

# Install jq
sudo apt-get update
sudo apt-get install -y jq

# Source shtern.sh in .bashrc
echo "source $(pwd)/shtern.sh" >> ~/.bashrc

# Clean up downloaded files
rm /tmp/Meslo.zip
rm -rf /tmp/Meslo

# Update font cache
sudo fc-cache -f -v

echo "Installation completed."

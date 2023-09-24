#!/bin/bash

ARCH=""
if [ $(uname -m) = "x86_64" ]; then
    ARCH="amd64"
elif [ $(uname -m) = "armv7l" ]; then
    ARCH="armhf"
elif [ $(uname -m) = "aarch64" ]; then
    ARCH="arm64"
else
    echo "Unsupported architecture.."
    exit 1
fi

setup_certificate() {
    # Ask the user if they want to use a domain
    read -p "Do you want to use a (domain/https)? (yes/no): " ANSWER

    if [ "$ANSWER" = "yes" ]; then
        # Ask for domain and port
        read -p "Enter your domain name: " DOMAIN
        read -p "Enter the port for certificate validation (default is 80): " PORT
        PORT="${PORT:-80}"

        apt install certbot -y
        echo "GET certificates for $DOMAIN on port $PORT"

        sudo certbot certonly --standalone --agree-tos --register-unsafely-without-email -d $DOMAIN --preferred-challenges http-01 --http-01-port $PORT

        echo "Setting up permissions for $DOMAIN"

        chmod 0755 /etc/letsencrypt/
        chmod 0711 /etc/letsencrypt/live/
        chmod 0750 "/etc/letsencrypt/live/$DOMAIN/"
        chmod 0711 /etc/letsencrypt/archive/
        chmod 0750 "/etc/letsencrypt/archive/$DOMAIN/"
        chmod 0640 "/etc/letsencrypt/archive/$DOMAIN/"*.pem
        chmod 0640 "/etc/letsencrypt/archive/$DOMAIN/privkey"*.pem

        chown root:root /etc/letsencrypt/
        chown root:root /etc/letsencrypt/live/
        chown root:ntfy "/etc/letsencrypt/live/$DOMAIN/"
        chown root:root /etc/letsencrypt/archive/
        chown root:ntfy "/etc/letsencrypt/archive/$DOMAIN/"
        chown root:ntfy "/etc/letsencrypt/archive/$DOMAIN/"*.pem
        chown root:ntfy "/etc/letsencrypt/archive/$DOMAIN/privkey"*.pem

        echo "Permissions successfully set for $DOMAIN. Enjoy!"
    else
        echo "Domain usage canceled ."
    fi
}

centos() {
  sudo rpm -ivh https://github.com/binwiederhier/ntfy/releases/download/v2.7.0/ntfy_2.7.0_linux_$ARCH.rpm
  sudo systemctl enable ntfy 
  sudo systemctl start ntfy
}

# Function to install ntfy
install_ntfy() {
  # Create a directory for apt keyrings
  sudo mkdir -p /etc/apt/keyrings
  # Download and add the GPG key for the Heckel repository
  curl -fsSL https://archive.heckel.io/apt/pubkey.txt | sudo gpg --dearmor -o /etc/apt/keyrings/archive.heckel.io.gpg
  # Install the apt-transport-https package
  sudo apt install apt-transport-https
  # Add the Heckel repository to sources.list.d
  sudo sh -c "echo 'deb [arch=$ARCH signed-by=/etc/apt/keyrings/archive.heckel.io.gpg] https://archive.heckel.io/apt debian main' \
  > /etc/apt/sources.list.d/archive.heckel.io.list"

  # Update the package list
  sudo apt update -y

  # Install ntfy
  sudo apt install ntfy
  sudo mv /etc/ntfy/server.yml /etc/ntfy/server.yml.bak
  # Download the new server.yml from the given URL and save it in /etc/ntfy/
  sudo curl -fsSL -o /etc/ntfy/server.yml https://raw.githubusercontent.com/Ptechgithub/ntfy/main/server.yml
  setup_certificate
  touch /var/log/ntfy.log
  sudo chown ntfy:ntfy /var/log/ntfy.log
  # Enable and start the ntfy service
  sudo systemctl daemon-reload
  sudo systemctl enable ntfy
  sudo systemctl start ntfy
  echo "ntfy has been installed."
}

# Function to uninstall ntfy
uninstall_ntfy() {
  # Check if the ntfy service is installed
  if systemctl is-active --quiet ntfy.service; then
    echo "ntfy is currently installed."

    # Stop and disable the ntfy service
    sudo systemctl stop ntfy
    sudo systemctl disable ntfy
    sudo rm /etc/systemd/system/ntfy
    sudo systemctl daemon-reload

    # Remove ntfy package
    sudo apt remove ntfy --purge -y

    # Additional uninstallation steps
    sudo rm -rf /etc/ntfy
    sudo rm -rf /etc/apt/keyrings
    sudo rm -rf /etc/letsencrypt/live/$DOMAIN
    # Remove the Heckel repository file
    sudo rm -f /etc/apt/sources.list.d/archive.heckel.io.list

    echo "ntfy has been uninstalled."
  else
    echo "ntfy is not  installed."
  fi
}

edit_config() {
    # Check if the config file exists
    if [ -e /etc/ntfy/server.yml ]; then
        # Install nano if it's not already installed
        if ! command -v nano &> /dev/null; then
            if [ "$(cat /etc/*-release | grep -Ei 'fedora|redhat|centos')" != "" ]; then
                sudo yum install nano -y
            else
                sudo apt install nano -y
            fi
        fi

        # Edit the config file with nano
        sudo nano /etc/ntfy/server.yml
    else
        echo "The config file (/etc/ntfy/server.yml) does not exist. Please install ntfy first or add manually"
    fi
}


# Main menu
clear
echo "By --> Peyman * Github.com/Ptechgithub * "
echo ""
echo "Select an option:"
echo "1) Install ntfy"
echo "2) Uninstall ntfy"
echo "3) Edit config"
echo "0) Exit"
read -p "Please choose: " choice

case $choice in
  1)
    if [ "$(cat /etc/*-release | grep -Ei 'fedora|redhat|centos')" != "" ]; then
        centos
    else
        install_ntfy
    fi
    ;;
  2)
    uninstall_ntfy
    ;;
  3)
    edit_config
    ;;
  0)   
    exit
    ;;
    *)
    echo "Invalid choice"
    ;;
esac
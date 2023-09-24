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

detect_distribution() {
    # Detect the Linux distribution
    local supported_distributions=("ubuntu" "debian" "centos" "fedora")
    
    if [ -f /etc/os-release ]; then
        source /etc/os-release
        if [[ "${ID}" = "ubuntu" || "${ID}" = "debian" || "${ID}" = "centos" || "${ID}" = "fedora" ]]; then
            PM="apt-get"
            [ "${ID}" = "centos" ] && PM="yum"
            [ "${ID}" = "fedora" ] && PM="dnf"
        else
            echo "Unsupported distribution!"
            exit 1
        fi
    else
        echo "Unsupported distribution!"
        exit 1
    fi
}

check_dependencies() {
    detect_distribution
    $PM update -y && $PM upgrade
    local dependencies=("nano" "certbot")
    
    for dep in "${dependencies[@]}"; do
        if ! command -v "${dep}" &> /dev/null; then
            echo "${dep} is not installed. Installing..."
            sudo "${PM}" install "${dep}" -y
        fi
    done
}

setup_certificate() {
    check_dependencies
    # Ask the user if they want to use a domain
    read -p "Do you want to use a (domain/https)? (yes/no): " ANSWER

    if [ "$ANSWER" = "yes" ]; then
        # Ask for domain and port
        read -p "Enter your domain name: " DOMAIN
        read -p "Enter the port for certificate validation (default is 80): " PORT
        PORT="${PORT:-80}"
        
        echo "GET certificates for $DOMAIN on port $PORT"

        sudo certbot certonly --standalone --agree-tos --register-unsafely-without-email -d $DOMAIN --preferred-challenges http-01 --http-01-port $PORT

        echo "Setting up permissions for $DOMAIN"

        chmod -q 0755 /etc/letsencrypt/
        chmod -q 0711 /etc/letsencrypt/live/
        chmod -q  0750 "/etc/letsencrypt/live/$DOMAIN/"
        chmod -q  0711 /etc/letsencrypt/archive/
        chmod -q 0750 "/etc/letsencrypt/archive/$DOMAIN/"
        chmod -q 0640 "/etc/letsencrypt/archive/$DOMAIN/"*.pem
        chmod -q 0640 "/etc/letsencrypt/archive/$DOMAIN/privkey"*.pem

        chown -q root:root /etc/letsencrypt/
        chown -q root:root /etc/letsencrypt/live/
        chown -q root:ntfy "/etc/letsencrypt/live/$DOMAIN/"
        chown -q root:root /etc/letsencrypt/archive/
        chown -q root:ntfy "/etc/letsencrypt/archive/$DOMAIN/"
        chown -q root:ntfy "/etc/letsencrypt/archive/$DOMAIN/"*.pem
        chown -q root:ntfy "/etc/letsencrypt/archive/$DOMAIN/privkey"*.pem

        echo "Permissions successfully set for $DOMAIN. Enjoy!"
    else
        echo "Domain usage canceled ."
    fi
}

install_centos() {
  check_dependencies
  setup_certificate
  sudo $PM install epel-release -y
  # Check if ntfy is already installed
  if rpm -q ntfy &>/dev/null; then
    echo "ntfy is already installed."
    return 0
  fi
  
  sudo rpm -ivh https://github.com/binwiederhier/ntfy/releases/download/v2.7.0/ntfy_2.7.0_linux_$ARCH.rpm
  sudo systemctl enable ntfy
  # Download the new server.yml from the given URL and save it in /etc/ntfy/
  sudo curl -fsSL -o /etc/ntfy/server.yml https://raw.githubusercontent.com/Ptechgithub/ntfy/main/server.yml
  touch /var/log/ntfy.log
  sudo chown ntfy:ntfy /var/log/ntfy.log
  sudo systemctl start ntfy
  echo "ntfy has been installed."
}


uninstall_ntfy_centos() {
  # Check if the ntfy service is installed
  if systemctl is-active --quiet ntfy.service; then
    echo "ntfy is currently installed."

    # Stop and disable the ntfy service
    sudo systemctl stop ntfy
    sudo systemctl disable ntfy
    sudo rpm -e ntfy
    sudo rm -rf /etc/letsencrypt/live/$DOMAIN
    # Additional uninstallation steps
    sudo rm -rf /etc/ntfy
    sudo rm /var/log/ntfy.log

    echo "ntfy has been uninstalled."
  else
    echo "ntfy is not installed."
  fi
}


# Function to install ntfy
install_ntfy() {
  check_dependencies
  
  if dpkg -s ntfy &> /dev/null; then
    echo "ntfy is already installed."
    return
  fi

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
    sudo rm /var/log/ntfy.log

    echo "ntfy has been uninstalled."
  else
    echo "ntfy is not  installed."
  fi
}

edit_config() {
    # Check if the config file exists
    if [ -e /etc/ntfy/server.yml ]; then
        # Edit the config file
        nano /etc/ntfy/server.yml
    else
        echo "The config file (/etc/ntfy/server.yml) does not exist. Please install ntfy first or add manually"
    fi
}

# install ntfy using Docker
install_docker_ntfy() {
  # Check if a Docker container with the ntfy image is already running
  if docker ps -a | grep -q binwiederhier/ntfy; then
    echo "ntfy Docker container is already installed and running."
    return
  fi

  # Check if Docker is installed
  if ! command -v docker &> /dev/null; then
    # Install Docker if it's not installed
    echo "Docker is not installed. Installing Docker..."
    curl -fsSL https://get.docker.com -o get-docker.sh && bash get-docker.sh
  else
    echo "Docker is already installed."
  fi
  # Set up certificates if needed
  setup_certificate
  # Get the port number from the user
  read -p "Enter the port number (default is 80): " port
  port=${port:-80}

  # Run the ntfy Docker command with the user-specified port
  docker run -v /var/cache/ntfy:/var/cache/ntfy -v /etc/ntfy:/etc/ntfy -p $port:80 -itd binwiederhier/ntfy serve --cache-file /var/cache/ntfy/cache.db
  
  echo "ntfy has been installed and is running on port $port."
}

uninstall_ntfy_docker() {
  # Find the ID of the ntfy Docker container
  container_id=$(docker ps -a | grep binwiederhier/ntfy | awk '{print $1}')
  
  # Check if a container with the ntfy image exists
  if [ -n "$container_id" ]; then
    echo "Stopping and removing the ntfy Docker container..."
    docker stop "$container_id"
    docker rm "$container_id"
    
    # Optionally, remove ntfy cache and configuration files
    rm -rf /var/cache/ntfy
    rm -rf /etc/ntfy
    
    echo "ntfy Docker container has been uninstalled."
  else
    echo "ntfy Docker container is not running or does not exist."
  fi
}

# Main menu
clear
echo "By --> Peyman * Github.com/Ptechgithub * "
echo "** NTFY Installer--> PUSH NOTIFICATION**"
echo ""
echo "Select an option:"
echo "1) Install ntfy"
echo "2) Uninstall ntfy"
echo "----------------------------"
echo "3) Install ntfy with Docker"
echo "4) Uninstall ntfy_Docker"
echo "-----------------------------"
echo "5) Edit config"
echo "0) Exit"
read -p "Please choose: " choice

case $choice in
  1)
    if [ "$(cat /etc/*-release | grep -Ei 'fedora|redhat|centos')" != "" ]; then
        install_centos
    else
        install_ntfy
    fi
    ;;
  2)
    if [ "$(cat /etc/*-release | grep -Ei 'fedora|redhat|centos')" != "" ]; then
        uninstall_ntfy_centos
    else
        uninstall_ntfy
    fi
    ;;
  3)
    install_docker_ntfy
    ;;
  4)
    uninstall_ntfy_docker
    ;;
  5)
     edit_config
    ;;
  0)   
    exit
    ;;
    *)
    echo "Invalid choice"
    ;;
esac
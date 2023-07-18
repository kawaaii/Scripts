#!/usr/bin/env bash

# Function to check the distribution
check_distribution() {
    if [[ -f /etc/os-release ]]; then
        # Read distribution name from /etc/os-release file
        distro=$(awk -F= '/^ID=/{gsub("\"", "", $2); print $2}' /etc/os-release)
    elif [[ -f /etc/lsb-release ]]; then
        # Read distribution name from /etc/lsb-release file
        distro=$(grep -Po '(?<=DISTRIB_ID=).+' /etc/lsb-release)
    elif [[ -f /etc/debian_version ]]; then
        # Check if /etc/debian_version file exists (Debian-based distributions)
        distro="Debian"
    elif [[ -f /etc/redhat-release ]]; then
        # Read the first word from /etc/redhat-release file (Red Hat-based distributions)
        distro=$(awk '{print $1}' /etc/redhat-release)
    else
        distro="Unknown"
    fi
}

# Check the distribution
check_distribution

echo "Linux distribution: $distro"

# Check if the distro is Arch Linux or its fork
if [[ $distro == "arch" || $distro == "manjaro" || $distro == "endeavouros" || $distro == "artix" ]]; then
    echo "Cloning Neutron Clang"
    mkdir -p "$HOME/toolchains/clang-neutron"
    cd "$HOME/toolchains/clang-neutron"
    curl -LO "https://raw.githubusercontent.com/Neutron-Toolchains/antman/main/antman"
    chmod +x antman
    ./antman -S

    cd "$HOME/toolchains/"
    echo "Cloning Neutron goodies"
    echo "Cloning Neutron coreutils"
    git clone https://github.com/Neutron-Toolchains/neutron-coreutils
    echo "Cloning Neutron gzip"
    git clone https://github.com/Neutron-Toolchains/neutron-gzip
else
    echo "The detected distribution is not Arch Linux or its fork. Exiting..."
    exit 1
fi

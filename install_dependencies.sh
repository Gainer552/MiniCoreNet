#!/bin/bash

#Greeting & Description
echo "MiniCoreNet Dependency Installer"
sleep 5s
echo "This script installs all required packages to run the MiniCoreNet system."
sleep 15s

set -e

# Updates system and install base dependencies.
echo "[*] Updating system and installing dependencies..."
echo
sudo pacman -Syu --noconfirm
echo

# Installs essential networking and cryptography tools.
sudo pacman -S --noconfirm \
  openssh \
  iproute2 \
  iptables \
  wireguard-tools \
  nmap \
  socat \
  curl \
  rsync \
  gnupg \
  netcat \
  jq \
  python \
  python-pip \
  git \
  unzip \
  base-devel \
  cronie \
  tor \

# Installs Python packages.
echo "[*] Creating virtual environment..."
echo
python -m venv .venv
source .venv/bin/activate
echo

echo "[*] Installing Python dependencies..."
echo
if [ ! -f requirements.txt ]; then
  echo "[!] requirements.txt not found. Please create it before running this script."
  deactivate
  exit 1
fi
pip install --upgrade pip
pip install -r requirements.txt

# Confirmation of installation.
echo "[*] All dependencies installed for MiniCoreNet."
sleep 5s
echo
echo "[*] You may now run the MiniCoreNet launcher script."
sleep 5s

exit 0

#!/bin/bash

#File sharing interface using rsync.
#Dependencies: rsync, ssh

echo "[*] File Sharing Menu (via rsync)"
echo
echo "[1] Send file to remote node"
echo "[2] Download file from remote node"
echo "[3] Exit"
echo

read -rp "Choose an option: " share_opt

case "$share_opt" in
    1)
        read -rp "Path to the local file you want to send: " local_file
        read -rp "Remote username: " remote_user
        read -rp "Remote host (IP or domain): " remote_host
        read -rp "Remote destination path (e.g. /home/user/): " remote_path

        echo "[*] Sending $local_file to $remote_user@$remote_host:$remote_path"
        rsync -avz -e ssh "$local_file" "${remote_user}@${remote_host}:${remote_path}"
        ;;
    2)
        read -rp "Remote username: " remote_user
        read -rp "Remote host (IP or domain): " remote_host
        read -rp "Path to remote file: " remote_file
        read -rp "Local destination path (e.g. ./ or /home/user/): " local_path

        echo "[*] Downloading $remote_file to $local_path"
        rsync -avz -e ssh "${remote_user}@${remote_host}:${remote_file}" "$local_path"
        ;;
    3)
        echo "Exiting file share menu."
        ;;
    *)
        echo "[!] Invalid selection."
        ;;
esac

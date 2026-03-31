#!/usr/bin/env python3
import paramiko
import sys
from pathlib import Path

SERVER = "38.14.248.145"
PORT = 22654
USER = "root"
PASS = "Xie080886"
LOCAL_FILE = "dist/LetsVPN-v4.1.2+40102-windows-x64.zip"
REMOTE_DIR = "/root/SSPanel-UIM/public/downloads"

def upload():
    try:
        print(f"Connecting to {SERVER}:{PORT}...")
        client = paramiko.SSHClient()
        client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
        client.connect(SERVER, port=PORT, username=USER, password=PASS, timeout=30)
        
        print(f"Connected! Uploading {LOCAL_FILE}...")
        sftp = client.open_sftp()
        
        # Ensure remote directory exists
        try:
            sftp.stat(REMOTE_DIR)
        except FileNotFoundError:
            print(f"Creating directory {REMOTE_DIR}...")
            client.exec_command(f"mkdir -p {REMOTE_DIR}")
        
        remote_path = f"{REMOTE_DIR}/LetsVPN-v4.1.2+40102-windows-x64.zip"
        sftp.put(LOCAL_FILE, remote_path)
        
        # Verify upload
        stat = sftp.stat(remote_path)
        size_mb = stat.st_size / (1024 * 1024)
        print(f"Upload successful! File size: {size_mb:.2f} MB")
        
        sftp.close()
        client.close()
        return True
    except Exception as e:
        print(f"Error: {e}")
        return False

if __name__ == "__main__":
    success = upload()
    sys.exit(0 if success else 1)

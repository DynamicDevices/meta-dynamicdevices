#!/bin/bash
# SSH to target board with multiplexing for connection reuse.
# Usage: ./ssh-target.sh [TARGET_IP] [command...]
# Example: ./ssh-target.sh 192.168.2.139 "hostname"
#          ./ssh-target.sh 192.168.2.139   # interactive shell
#          ./ssh-target.sh                 # interactive, default IP

TARGET_IP="${1:-192.168.2.139}"
TARGET_USER="${TARGET_USER:-fio}"
TARGET_PASS="${TARGET_PASS:-fio}"
[[ "$1" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]] && shift

SSH_OPTS=(
  -o ControlMaster=auto
  -o ControlPath=/tmp/ssh-target-%r@%h:%p
  -o ControlPersist=10m
  -o StrictHostKeyChecking=no
  -o PubkeyAuthentication=no
)

exec sshpass -p "$TARGET_PASS" ssh "${SSH_OPTS[@]}" "$TARGET_USER@$TARGET_IP" "$@"

#!/usr/bin/env bash
set -euo pipefail

echo "=== 1. パッケージ確認・インストール ==="
if command -v pkg >/dev/null 2>&1; then
    DEBIAN_FRONTEND=noninteractive pkg update -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold"
    DEBIAN_FRONTEND=noninteractive pkg install -y openssh git gh curl
elif command -v apt-get >/dev/null 2>&1; then
    sudo apt-get update -y && sudo apt-get install -y openssh-client git gh curl
elif command -v dnf >/dev/null 2>&1; then
    sudo dnf install -y openssh-clients git gh curl
elif command -v pacman >/dev/null 2>&1; then
    sudo pacman -Sy --noconfirm openssh git github-cli curl
elif command -v brew >/dev/null 2>&1; then
    brew install git gh
fi

echo "=== 2. ~/.ssh/config の配置 ==="
mkdir -p "$HOME/.ssh"
chmod 700 "$HOME/.ssh"

cat << 'EOF' > "$HOME/.ssh/config"
Host server
    HostName ssh.sohhoshi.com
    Port 52222
    User soh
    StrictHostKeyChecking accept-new

Host bazzite
    HostName ssh.sohhoshi.com
    Port 52223
    User soh
    StrictHostKeyChecking accept-new
EOF
chmod 600 "$HOME/.ssh/config"

echo "=== 3. SSH鍵の生成 ==="
if [[ ! -f "$HOME/.ssh/id_ed25519" ]]; then
    ssh-keygen -t ed25519 -N "" -f "$HOME/.ssh/id_ed25519" -C "$(whoami)-$(date +%Y%m%d)"
fi

echo "=== 4. GitHub認証 & 公開鍵登録 ==="
if ! gh auth status >/dev/null 2>&1; then
    gh auth login -h github.com -p https -w -s admin:public_key </dev/tty
else
    gh auth refresh -h github.com -s admin:public_key </dev/tty || true
fi

KEY_TITLE="device-$(whoami)-$(date +%Y%m%d-%H%M)"
gh ssh-key add "$HOME/.ssh/id_ed25519.pub" --title "$KEY_TITLE" || true

echo "=== 完了 (ssh server / ssh bazzite) ==="
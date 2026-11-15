#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

mkdir -p "$HOME/.ssh"
chmod 700 "$HOME/.ssh"

cp "$SCRIPT_DIR/ssh_config" "$HOME/.ssh/config"
chmod 600 "$HOME/.ssh/config"

echo "[OK] ~/.ssh/config を配置しました（ssh server / ssh bazzite が使えます）"

# まだSSH鍵がない場合は作成し、ghがログイン済みならGitHubへ登録
if [[ ! -f "$HOME/.ssh/id_ed25519" && ! -f "$HOME/.ssh/id_rsa" ]]; then
    echo "[INFO] SSH鍵が見つからないため新規作成します..."
    ssh-keygen -t ed25519 -N "" -f "$HOME/.ssh/id_ed25519"
    if command -v gh >/dev/null 2>&1 && gh auth status >/dev/null 2>&1; then
        gh ssh-key add "$HOME/.ssh/id_ed25519.pub" --title "$(hostname)-$(date +%Y%m%d)" || true
        echo "[OK] 公開鍵をGitHubへ自動登録しました（接続時に即座に認証されます）"
    fi
fi
#!/usr/bin/env bash
set -euo pipefail

echo "=== 1. パッケージ確認・インストール ==="
if command -v pkg >/dev/null 2>&1; then
    pkg update -y && pkg install -y openssh gh curl
fi

echo "=== 2. ~/.ssh/config (エイリアス設定) の配置 ==="
mkdir -p "$HOME/.ssh"
chmod 700 "$HOME/.ssh"

cat << 'EOF' > "$HOME/.ssh/config"
Host server
    HostName ssh.sohhoshi.com
    Port 52222
    User soh

Host bazzite
    HostName ssh.sohhoshi.com
    Port 52223
    User soh
EOF
chmod 600 "$HOME/.ssh/config"
echo "[OK] ~/.ssh/config を設定しました (ssh server / ssh bazzite)"

echo "=== 3. SSH鍵の自動生成 (パスフレーズなし) ==="
if [[ ! -f "$HOME/.ssh/id_ed25519" ]]; then
    ssh-keygen -t ed25519 -N "" -f "$HOME/.ssh/id_ed25519" -C "termux-$(date +%Y%m%d)"
    echo "[OK] SSH鍵 (~/.ssh/id_ed25519) を自動生成しました"
else
    echo "[OK] 既存のSSH鍵 (~/.ssh/id_ed25519) を使用します"
fi

echo "=== 4. GitHub認証 & 公開鍵の自動アップロード ==="
if ! gh auth status >/dev/null 2>&1; then
    # 対話質問をすべてスキップし、直接ブラウザ認証のみ開く
    gh auth login -h github.com -p https -w -s admin:public_key </dev/tty
else
    gh auth refresh -h github.com -s admin:public_key </dev/tty || true
fi

KEY_TITLE="device-$(whoami)-$(date +%Y%m%d-%H%M)"
gh ssh-key add "$HOME/.ssh/id_ed25519.pub" --title "$KEY_TITLE" || true

echo ""
echo "=========================================="
echo " セットアップ完了！"
echo " 以下のコマンドですぐに接続できます："
echo "   ssh server"
echo "   ssh bazzite"
echo "=========================================="
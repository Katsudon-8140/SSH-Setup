# SSH Setup (Termux / Linux / PC)

新しいスマホ（Termux）やPCで `ssh server` / `ssh bazzite` を使えるようにする初期セットアップです。
サーバー側（`server`）は `AuthorizedKeysCommand` により、**未登録の鍵でSSH接続が来た瞬間にだけ `https://github.com/Katsudon-8140.keys` を自動確認して認証＆キャッシュ**するため、公開鍵の手動コピペや待ち時間は不要です。

## スマホ（Termux）でのセットアップ手順

Termuxを開いて以下を順番にコピペして実行するだけです。

```bash
# 1. 必要なパッケージをインストール
pkg update -y && pkg install -y openssh git github-cli

# 2. GitHubにログイン（対話の中でSSH鍵の生成＆GitHubへのアップロードも自動で行われます）
gh auth login -p ssh

# 3. このリポジトリを取得してエイリアス（~/.ssh/config）を反映
gh repo clone Katsudon-8140/dotfiles ~/.dotfiles && bash ~/.dotfiles/setup.sh
```

完了後、待ち時間なしでそのまま接続できます：

```bash
ssh server
ssh bazzite
```
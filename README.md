# SSH & FRP 接続設定 / 新端末セットアップ (`dotfiles`)

スマホ（Termux）や新しいPCから自宅サーバー（`server`）およびデスクトップPC（`bazzite`）へ、同じエイリアスで簡単にSSH接続するための設定リポジトリです。

---

## 🚀 新しいスマホ（Termux）での初期セットアップ（1行コマンド）

Termux を開いて、**以下の1行をコピペして実行するだけ**です。

```bash
curl -fsSL https://raw.githubusercontent.com/Katsudon-8140/dotfiles/main/setup.sh | bash
```

### このコマンドが自動でやること（質問への回答不要）
1. **必要ツールの導入**: `openssh`, `gh`, `curl` を自動インストール
2. **エイリアス設定**: `~/.ssh/config` に `server` と `bazzite` を自動書き込み
3. **SSH鍵の自動生成**: パスフレーズなしで `~/.ssh/id_ed25519` を自動作成（質問なし）
4. **GitHubへ公開鍵を自動登録**: `gh auth login` の対話質問をすべてスキップして直接ブラウザ認証を開き、認証後に公開鍵を GitHub（`https://github.com/Katsudon-8140.keys`）へ自動アップロード

> **ブラウザ認証の操作だけ**:
> 画面に表示される8桁のワンタイムコードをコピーして Enter を押すとブラウザが開くので、GitHubで承認するだけで完了します。

セットアップ完了後、すぐに以下のコマンドで接続できます：

```bash
ssh server
ssh bazzite
```

---

## 🌐 現在のSSH・FRP接続の仕組み（全体構成）

### 1. SSHエイリアス一覧（`~/.ssh/config`）

| コマンド | 接続先ホスト (`HostName`) | ポート (`Port`) | ユーザー (`User`) | 実際の接続先 |
| :--- | :--- | :--- | :--- | :--- |
| **`ssh server`** | `ssh.sohhoshi.com` | `52222` | `soh` | 自宅サーバー (`server` / `192.168.0.10`) |
| **`ssh bazzite`** | `ssh.sohhoshi.com` | `52223` | `soh` | デスクトップPC (`bazzite` / `192.168.0.20`) |

### 2. 通信経路（Oracle VPS + FRP トンネル）

`ssh.sohhoshi.com` は **Oracle VPS (`168.110.50.171`)** を指しており、自宅の `server` 上で稼働している Docker コンテナ **`frpc`** が VPS とトンネルを張ってポート転送しています。

```text
[スマホ (Termux) / 手元PC]
  │
  ├─ (ssh server  / Port 52222) ──┐
  └─ (ssh bazzite / Port 52223) ──┼──> [Oracle VPS: ssh.sohhoshi.com (168.110.50.171)]
                                  │          │ (FRP Tunnel: Port 7000)
                                  │          ▼
                                  │    [自宅 server (192.168.0.10) 上の frpc コンテナ]
                                  │          ├── 52222 ──> 127.0.0.1:22    (server 自身のSSH)
                                  │          └── 52223 ──> 192.168.0.20:22 (LAN内の bazzite のSSH)
```

* **`server` 内の FRP 設定場所**:
  * `/home/soh/frp/docker-compose.yml`
  * `/home/soh/frp/frpc.toml`

---

## 🔑 公開鍵が自動で通る仕組み（コピペ不要の理由）

スマホで作った秘密鍵（`~/.ssh/id_ed25519`）はスマホの外に出す必要はありません。

1. スマホ側で `setup.sh` を実行すると、**公開鍵**だけが GitHub（`https://github.com/Katsudon-8140.keys`）に登録されます。
2. 自宅 `server` の SSH サーバー（`sshd`）には **`AuthorizedKeysCommand`** が設定されており、**まだローカルに未登録の新しい鍵でSSH接続が来たその瞬間にだけ** GitHub の公開鍵一覧を自動確認します。
3. 本人の鍵と一致すればその場でログインを許可し、`~/.ssh/authorized_keys` にキャッシュ保存します（同時に `bazzite` が起動していれば `bazzite` の `~/.ssh/authorized_keys` にも自動コピーします）。
4. 2回目以降の接続はローカルの `~/.ssh/authorized_keys` で即座に認証されるため、定期実行（cron）や待ち時間は一切ありません。

### サーバー側の関連ファイル（メンテナンス用メモ）

* **`/etc/ssh/sshd_config.d/10-github-keys.conf`**
  * `sshd` が未登録の鍵で接続された際に `/usr/local/bin/github-ssh-keys.sh` を呼び出す設定
* **`/usr/local/bin/github-ssh-keys.sh`**
  * `/home/soh/.local/bin/sync-github-keys.sh` を実行して最新の `authorized_keys` を標準出力へ返すラッパー
* **`/home/soh/.local/bin/sync-github-keys.sh`**
  * `https://github.com/Katsudon-8140.keys` から公開鍵を取得して `server` の `~/.ssh/authorized_keys` に追記し、`bazzite`（`192.168.0.20`）が起動していれば `bazzite` 側にも同期するスクリプト
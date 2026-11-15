# dotfiles (SSH Setup)

新端末から `server` / `bazzite` へSSH接続するための初期設定。

## セットアップ

```bash
curl -fsSL https://raw.githubusercontent.com/Katsudon-8140/dotfiles/main/setup.sh | bash
```

1. 必要パッケージ導入、`~/.ssh/config` 配置、SSH鍵生成、GitHubへの公開鍵登録まで自動実行（ブラウザで8桁のコードを承認するだけ）。
2. 完了後、そのまま接続可能：
   ```bash
   ssh server
   ssh bazzite
   ```

---

## 構成メモ

### 接続先エイリアス (`~/.ssh/config`)

| Host | 宛先 | 転送先 (FRP経由) |
| :--- | :--- | :--- |
| `server` | `ssh.sohhoshi.com:52222` | `192.168.0.10:22` (自宅サーバー) |
| `bazzite` | `ssh.sohhoshi.com:52223` | `192.168.0.20:22` (デスクトップPC) |

### 経路と鍵認証

```text
[Client] ──(52222 / 52223)──> [Oracle VPS (168.110.50.171)] ──(FRP:7000)──> [server (frpc)] ──> server / bazzite
```

* **FRP (`server`)**: `/home/soh/frp/docker-compose.yml`, `/home/soh/frp/frpc.toml`
* **公開鍵同期 (`server`)**:
  * `/etc/ssh/sshd_config.d/10-github-keys.conf` (`AuthorizedKeysCommand`)
  * `/usr/local/bin/github-ssh-keys.sh` → `/home/soh/.local/bin/sync-github-keys.sh`
  * 未登録の鍵で接続された時のみ `https://github.com/Katsudon-8140.keys` を取得し、`server`（および起動中なら `bazzite`）の `~/.ssh/authorized_keys` に反映。
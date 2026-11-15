$ErrorActionPreference = "Stop"

Write-Host "=== 1. パッケージ確認・インストール ==="
if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    winget install --id Git.Git -e --accept-source-agreements --accept-package-agreements
}
if (-not (Get-Command gh -ErrorAction SilentlyContinue)) {
    winget install --id GitHub.cli -e --accept-source-agreements --accept-package-agreements
}
$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")

Write-Host "=== 2. ~/.ssh/config の配置 ==="
New-Item -ItemType Directory -Force -Path "$HOME\.ssh" | Out-Null

@"
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
"@ | Set-Content -Path "$HOME\.ssh\config" -Encoding UTF8

Write-Host "=== 3. SSH鍵の生成 ==="
if (-not (Test-Path "$HOME\.ssh\id_ed25519")) {
    ssh-keygen -t ed25519 -N '""' -f "$HOME\.ssh\id_ed25519" -C "$env:COMPUTERNAME-$(Get-Date -Format yyyyMMdd)"
}

Write-Host "=== 4. GitHub認証 & 公開鍵登録 ==="
gh auth status 2>$null
if ($LASTEXITCODE -ne 0) {
    gh auth login -h github.com -p https -w -s admin:public_key
} else {
    gh auth refresh -h github.com -s admin:public_key
}

$keyTitle = "device-$env:COMPUTERNAME-$(Get-Date -Format yyyyMMdd-HHmm)"
gh ssh-key add "$HOME\.ssh\id_ed25519.pub" --title $keyTitle

Write-Host "=== 完了 (ssh server / ssh bazzite) ==="
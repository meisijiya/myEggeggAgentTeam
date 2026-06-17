# 云服务器部署文档

## ⚠️ 物理隔离（v4 关键设计）

云服务器上**只安装房间门团队**——与老江湖本机的编程团队（ohMeisijiyaCode）**完全隔离**：

| 项 | 云服务器（房间门）| 老江湖本机（编程团队）|
|----|-----------------|---------------------|
| `~/.config/opencode/` | **独立** | **独立** |
| AGENTS.md | 房间门团队 | 编程团队 |
| opencode.json | 房间门 6 Agent | 编程 10 Agent |

**为什么**：避免编程团队的 AGENTS.md 规范（karpathy / TDD / 英文注释）污染房间门团队 + 模型配额独立。

## 1. 云服务器选型

推荐：**国内轻量云服务器**（2C2G 即可）

- 阿里云 / 腾讯云 / 华为云 轻量应用服务器
- 带宽 5Mbps（够 web UI 用）
- 系统：Ubuntu 24.04 LTS

## 2. 基础环境安装

```bash
# SSH 登录后
sudo apt update && sudo apt install -y nodejs npm git curl
sudo npm install -g @opencode-ai/opencode npx
```

## 3. 部署房间门团队

```bash
# 克隆项目
git clone <repo> /opt/myEggeggAgentTeam
cd /opt/myEggeggAgentTeam

# 安装
bash scripts/install.sh

# 配置 opencode.json（参考设计文档 §5.1）
vim ~/.config/opencode/opencode.json
```

## 4. 配置 opencode.json

```json
{
  "agent": {
    "roomdoor":  { "model": "<your-high-model-id>", "fallback_model": "<your-mid-model-id>" },
    "veteran":   { "model": "<your-high-model-id>", "fallback_model": "<your-mid-model-id>" },
    "qiqi":      { "model": "<your-high-model-id>", "fallback_model": "<your-mid-model-id>" },
    "librarian": { "model": "<your-high-model-id>", "fallback_model": "<your-mid-model-id>" },
    "ccy":       { "model": "<your-mid-model-id>", "fallback_model": "<your-high-model-id>" },
    "update":    { "model": "<your-mid-model-id>", "fallback_model": "<your-high-model-id>" }
  }
}
```

## 5. 启动 opencode web

```bash
# 前台启动（测试用）
opencode web --port 8080

# 后台启动（systemd）
sudo tee /etc/systemd/system/opencode-web.service << 'EOF'
[Unit]
Description=OpenCode Web Service
After=network.target

[Service]
Type=simple
User=ubuntu
ExecStart=/usr/local/bin/opencode web --port 8080
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable --now opencode-web
```

## 6. Cloudflare Tunnel 配置

```bash
# 安装 cloudflared
curl -fsSL https://pkg.cloudflare.com/cloudflare-main.gpg | sudo tee /usr/share/keyrings/cloudflare-main.gpg >/dev/null
echo 'deb [signed-by=/usr/share/keyrings/cloudflare-main.gpg] https://pkg.cloudflare.com/cloudflared focal main' | sudo tee /etc/apt/sources.list.d/cloudflared.list
sudo apt update && sudo apt install -y cloudflared

# 登录 Cloudflare
cloudflared tunnel login

# 创建 tunnel
cloudflared tunnel create roomdoor

# 配置 config.yml
mkdir -p ~/.cloudflared
cat > ~/.cloudflared/config.yml << 'EOF'
tunnel: <your-tunnel-id>
credentials-file: /home/ubuntu/.cloudflared/<your-tunnel-id>.json

ingress:
  - hostname: roomdoor.your-domain.com
    service: http://localhost:8080
  - service: http_status:404
EOF

# 路由 DNS
cloudflared tunnel route dns roomdoor roomdoor.your-domain.com

# 启动 tunnel（systemd）
sudo cloudflared service install
sudo systemctl enable --now cloudflared
```

## 7. 验证

- 浏览器访问 https://roomdoor.your-domain.com
- 应该看到 opencode web 界面
- @房间门 测试对话

## 8. 备份

```bash
# 每月备份记忆
rsync -av ~/.roomdoor-memory/ /backup/roomdoor-$(date +%Y%m)/
```

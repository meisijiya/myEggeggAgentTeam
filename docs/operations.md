# 房间门 Agent 团队运维手册（v5.3.4）

> 适用对象：运维人员 / 用户自己
> 部署版本：v5.3.4（房间门 6-agent + 10 skill + 凌晨 4 点 cron）
> 服务地址：云服务器 `<CLOUD_SERVER_IP>:4096`

---

## 📋 部署概览

| 项 | 值 |
|----|----|
| 服务名 | `opencode-web.service` |
| systemd unit | `/etc/systemd/system/opencode-web.service` |
| 端口 | **4096**（绑定 `0.0.0.0`）|
| 认证用户名 | `<WEB_USERNAME>` |
| 认证密码 | `<WEB_PASSWORD>` |
| 进程用户 | `ubuntu` |
| 工作目录 | `/home/ubuntu` |
| 日志 | `/var/log/opencode-web.log` |
| 部署目录 | `~/.config/opencode/`（agents/ + skills/ + opencode.json + AGENTS.md）|
| 记忆目录 | `~/.roomdoor-memory/`（active/ + archive/ + meta/）|
| cron | `0 4 * * *` memory-self-check |
| 开机自启 | ✅ enabled（multi-user.target）|

---

## 🚀 一键操作脚本

### 启动

```bash
bash scripts/ops-start.sh
# 等价于：
sudo systemctl daemon-reload
sudo systemctl enable --now opencode-web
```

### 停止

```bash
bash scripts/ops-stop.sh
# 等价于：
sudo systemctl stop opencode-web
```

### 重启

```bash
bash scripts/ops-restart.sh
# 等价于：
sudo systemctl restart opencode-web
```

### 查看状态

```bash
bash scripts/ops-status.sh
# 等价于：
sudo systemctl status opencode-web --no-pager -l
```

### 查看实时日志

```bash
bash scripts/ops-logs.sh
# 等价于：
sudo journalctl -u opencode-web -f
# 或：
tail -f /var/log/opencode-web.log
```

---

## 🌐 公网访问

### 当前状态

服务**监听** `0.0.0.0:4096`，但**云服务器安全组**默认**可能**没开 4096 端口公网访问。

### 访问方式（按推荐顺序）

#### 1. **Cloudflare Tunnel**（**推荐**，生产级）

需要 Cloudflare 账号 + 域名 + 隧道配置。

```bash
# 安装 cloudflared
curl -fsSL https://pkg.cloudflare.com/cloudflare-main.gpg | sudo tee /usr/share/keyrings/cloudflare-main.gpg >/dev/null
echo 'deb [signed-by=/usr/share/keyrings/cloudflare-main.gpg] https://pkg.cloudflare.com/cloudflared focal main' | sudo tee /etc/apt/sources.list.d/cloudflared.list
sudo apt update && sudo apt install -y cloudflared

# 登录 + 建隧道
cloudflared tunnel login
cloudflared tunnel create roomdoor
cloudflared tunnel route dns roomdoor roomdoor.yourdomain.com

# 配 config
mkdir -p ~/.cloudflared
cat > ~/.cloudflared/config.yml << 'EOF'
url: http://localhost:4096
tunnel: <TUNNEL_ID>
credentials-file: /home/ubuntu/.cloudflared/<TUNNEL_ID>.json
EOF

# 后台跑
cloudflared tunnel run roomdoor
```

详见：https://developers.cloudflare.com/cloudflare-one/connections/connect-networks/

#### 2. **SSH 端口转发**（**临时/运维用**）

```bash
# 本地机器（运维人员）跑：
ssh -L 4096:localhost:4096 ubuntu@<CLOUD_SERVER_IP>
# 然后浏览器访问 http://localhost:4096
```

#### 3. **云安全组开 4096**（**不推荐**，明文风险）

在云服务商控制台：
- 阿里云轻量：防火墙 → 添加规则 → TCP 4096 → 允许
- 腾讯云轻量：防火墙 → 添加规则 → TCP 4096 → 允许
- **风险**：HTTP 明文传输，密码在网络可见

**推荐用 Cloudflare Tunnel**（HTTPS + DDoS 防护）。

---

## 🔐 认证

### 用户名 / 密码

| 项 | 值 |
|----|----|
| 用户名 | `<WEB_USERNAME>` |
| 密码 | `<WEB_PASSWORD>` |

### 改密码

1. 编辑 `/etc/systemd/system/opencode-web.service`：
   ```ini
   Environment=OPENCODE_SERVER_PASSWORD=新密码
   ```
2. 重启：
   ```bash
   sudo systemctl daemon-reload
   sudo systemctl restart opencode-web
   ```

### 关闭认证（**不推荐**）

删除 `OPENCODE_SERVER_USERNAME` 和 `OPENCODE_SERVER_PASSWORD` 两行 + 重启。

⚠️ **警告**：关认证后任何 IP 都能用服务，**强烈不推荐**。

---

## 🛠️ 故障排查

### 问题 1：服务起不来

```bash
# 1. 看日志
bash scripts/ops-logs.sh

# 2. 常见原因
#    a. opencode.json 格式错（jsonc 解析失败）
#       修复：python3 -c "import json,re; print(json.dumps(json.loads(re.sub(r'//.*', '', open('~/.config/opencode/opencode.json').read()))))"
#    b. 端口被占
#       修复：sudo lsof -i :4096  # 看谁占了
#    c. 权限问题
#       修复：ls -la ~/.config/opencode/  # 应该是 ubuntu:ubuntu
```

### 问题 2：端口 4096 监听但访问不到

```bash
# 1. 确认服务在跑
sudo systemctl status opencode-web

# 2. 确认端口监听
ss -tlnp | grep 4096

# 3. 测试本地访问
curl -u <WEB_USERNAME>:<WEB_PASSWORD> http://localhost:4096/

# 4. 看云安全组
#    阿里云：https://console.aliyun.com → 轻量应用服务器 → 防火墙
#    腾讯云：https://console.cloud.tencent.com → 轻量应用服务器 → 防火墙

# 5. 看 Cloudflare Tunnel 状态
sudo systemctl status cloudflared
```

### 问题 3：opencode 命令找不到

opencode 装在 `~/.local/node/lib/node_modules/`，但**不在默认 PATH**。

```bash
# 检查 PATH
echo $PATH

# 临时加
export PATH="$HOME/.local/node/bin:$PATH"

# 永久加（写到 ~/.bashrc）
if ! grep -q ".local/node/bin" ~/.bashrc; then
    echo 'export PATH="$HOME/.local/node/bin:$PATH"' >> ~/.bashrc
fi
```

systemd service 已经配 `Environment=PATH=...` 含这个路径，**服务**启动**不**受 PATH 影响。

### 问题 4：xdg-open 错误（启动时）

```
error: Executable not found in $PATH: "xdg-open"
```

**不**影响服务。opencode 启动后**想**自动打开浏览器（本地有 desktop），云服务器没装 desktop，**这是已知**。

修复（可选）：

```bash
sudo apt install -y xdg-utils
# 或：在 service 文件加 Environment=BROWSER=none
```

### 问题 5：AGENTS.md / skill 不生效

```bash
# 1. 确认文件存在
ls -la ~/.config/opencode/AGENTS.md
ls -la ~/.config/opencode/agents/
ls -la ~/.config/opencode/skills/

# 2. 重启服务（opencode 启动时加载这些文件）
bash scripts/ops-restart.sh
```

### 问题 6：cron 没跑

```bash
# 1. 看 cron
crontab -l

# 2. 手动跑测试
bash ~/opt/myEggeggAgentTeam/scripts/memory-self-check.sh

# 3. 看日志
ls -la ~/.roomdoor-memory/meta/cron.log
cat ~/.roomdoor-memory/meta/cron.log 2>/dev/null | tail -20
```

---

## 📦 部署 / 升级

### 首次部署

```bash
# 1. SCP 上传项目
scp -i <key> -r myEggeggAgentTeam/agents \
                    myEggeggAgentTeam/skills \
                    myEggeggAgentTeam/templates \
                    myEggeggAgentTeam/scripts \
                    myEggeggAgentTeam/memory-seed \
                    ubuntu@<CLOUD_SERVER_IP>:/tmp/roomdoor-deploy/

# 2. SSH 跑 install.sh
ssh -i <key> ubuntu@<CLOUD_SERVER_IP>
cd /tmp/roomdoor-deploy && bash scripts/install.sh

# 3. 配置 systemd service（本手册 Step 1）

# 4. 启动
bash scripts/ops-start.sh
```

### 升级（仅改 agents/ skills/）

```bash
# 本地：commit + push（git 仓库）
git add -A && git commit -m "升级 v5.x" && git push

# 云服务器：拉 + 重启
ssh ubuntu@<CLOUD_SERVER_IP>
cd ~/myEggeggAgentTeam && git pull
# 重新部署 agents/ skills/
cp agents/*.md ~/.config/opencode/agents/
cp -r skills/*/ ~/.config/opencode/skills/
# 重启服务
bash scripts/ops-restart.sh
```

---

## 🔄 备份

### 备份当前部署

```bash
# 备份到 ~/backup/
BACKUP=~/backup/2026-06-17-$(date +%H%M%S)
mkdir -p "$BACKUP"
cp -r ~/.config/opencode "$BACKUP/"
cp -r ~/.roomdoor-memory "$BACKUP/"
cp /etc/systemd/system/opencode-web.service "$BACKUP/"
echo "✅ 备份到 $BACKUP"
```

### 恢复

```bash
# 1. 停服务
bash scripts/ops-stop.sh

# 2. 恢复文件
cp -r ~/backup/<时间戳>/opencode/* ~/.config/opencode/
cp -r ~/backup/<时间戳>/roomdoor-memory/* ~/.roomdoor-memory/
sudo cp ~/backup/<时间戳>/opencode-web.service /etc/systemd/system/
sudo systemctl daemon-reload

# 3. 启动
bash scripts/ops-start.sh
```

---

## 🆘 紧急操作

### 服务挂了，临时启动

```bash
# 不用 systemd，前台跑
export PATH="$HOME/.local/node/bin:$PATH"
export OPENCODE_SERVER_USERNAME=<WEB_USERNAME>
export OPENCODE_SERVER_PASSWORD=<WEB_PASSWORD>
opencode web --port 4096
```

### 完全重置

```bash
# 1. 停服务
sudo systemctl stop opencode-web
sudo systemctl disable opencode-web

# 2. 删配置
rm -rf ~/.config/opencode
rm -rf ~/.roomdoor-memory

# 3. 删 service
sudo rm /etc/systemd/system/opencode-web.service
sudo systemctl daemon-reload

# 4. 重新部署（首次部署步骤）
```

### 卸载 opencode

```bash
# 1. 停 + 删 service
sudo systemctl stop opencode-web
sudo systemctl disable opencode-web
sudo rm /etc/systemd/system/opencode-web.service
sudo systemctl daemon-reload

# 2. 删 opencode 二进制
rm -rf ~/.local/node/lib/node_modules/opencode-ai*
# 或：npm uninstall -g opencode-ai  # 如果 PATH 配了

# 3. 删配置 + 记忆
rm -rf ~/.config/opencode
rm -rf ~/.roomdoor-memory
```

---

## 📞 联系

- 项目仓库：https://github.com/<owner>/myEggeggAgentTeam
- 设计文档：`docs/superpowers/specs/2026-06-17-roomdoor-team-design.md`
- 部署文档：`docs/deployment.md`
- 本手册：`docs/operations.md`

---

**版本**：v5.3.4（2026-06-17）
**作者**：OneTwo（v5.3.4 部署）

#!/usr/bin/env bash
# ops-install.sh - 首次部署：写 service 文件 + 启动服务
# 用途：首次部署或修复 service 文件（service 文件丢失/损坏时跑）
# v5.3.4-1: 配置硬编码到脚本（不需要读其他配置文件）

set -euo pipefail

# ===== 硬编码配置（修改这里更新所有脚本） =====
USERNAME="<WEB_USERNAME>"
PASSWORD="<WEB_PASSWORD>"
PORT="4096"
OPENCODE_BIN="/home/ubuntu/.local/node/bin/opencode"
SERVICE_NAME="opencode-web.service"
SERVICE_FILE="/etc/systemd/system/${SERVICE_NAME}"
WORKSPACE="/home/ubuntu/workSpace"

# ===== 1. 检查 sudo 权限 =====
if ! sudo -n true 2>/dev/null; then
    echo "❌ 当前用户没有 NOPASSWD sudo 权限"
    echo "解决：sudo visudo 加一行: ubuntu ALL=(ALL) NOPASSWD:ALL"
    exit 1
fi
echo "✅ sudo 权限 OK"
echo ""

# ===== 2. 检查 opencode 二进制 =====
if [ ! -x "$OPENCODE_BIN" ]; then
    echo "❌ opencode 不存在: $OPENCODE_BIN"
    echo "解决：npm i -g opencode-ai@latest"
    exit 1
fi
echo "✅ opencode: $OPENCODE_BIN"
echo ""

# ===== 3. 创建 workSpace 目录（v5.3.4-2） =====
echo "▶ 创建 $WORKSPACE + 3 子目录 + chmod 777 ..."
mkdir -p "$WORKSPACE"/{inbox,outbox,projects}
chmod 777 "$WORKSPACE" "$WORKSPACE"/inbox "$WORKSPACE"/outbox "$WORKSPACE"/projects
echo "✅ workSpace 就绪"
ls -la "$WORKSPACE"
echo ""

# ===== 4. 写 start.sh（启动脚本，cd + export + exec） =====
echo "▶ 写 $WORKSPACE/start.sh ..."
cat > "$WORKSPACE/start.sh" << 'STARTEOF'
#!/usr/bin/env bash
# start.sh - 启动 opencode-web（v5.3.4-2）
# 流程：cd 到 workSpace → export 认证 → exec opencode

# 1. 切到 workSpace 目录
cd /home/ubuntu/workSpace || exit 1
echo "[start.sh] cwd: $(pwd)"

# 2. 设置 PATH（含 npm 全局 opencode）
export PATH=/home/ubuntu/.local/node/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

# 3. 设置认证（硬编码到本脚本）
export OPENCODE_SERVER_USERNAME=<WEB_USERNAME>
export OPENCODE_SERVER_PASSWORD=<WEB_PASSWORD>

# 4. exec 启动 opencode（取代当前 shell，systemd 看到的就是 opencode 进程）
exec /home/ubuntu/.local/node/bin/opencode web --port 4096
STARTEOF
chmod 777 "$WORKSPACE/start.sh"
echo "✅ start.sh 写好 + chmod 777"
echo ""

# ===== 4.5. 装 nginx + 配置 12121 端口（v5.3.4-4 新增） =====
echo "▶ 装 nginx + 配置 12121 端口（expose-download-link 用）..."
if ! command -v nginx &>/dev/null; then
    sudo apt update 2>&1 | tail -1
    sudo apt install -y nginx 2>&1 | tail -3
fi
# 关键：让 www-data 进 /home/ubuntu/（worker 进程要 stat 文件）
sudo usermod -a -G ubuntu www-data 2>/dev/null
# public 目录（chmod 777 让 ubuntu 用户能 cp 进去）
mkdir -p "$WORKSPACE/public"
sudo chown ubuntu:ubuntu "$WORKSPACE/public"
chmod 777 "$WORKSPACE/public"
# nginx 配置（严格隔离：autoindex off + try_files）
sudo tee /etc/nginx/conf.d/roomdoor-public.conf > /dev/null << 'NGINXEOF'
server {
    listen 12121;
    server_name _;
    autoindex off;
    server_tokens off;
    root /home/ubuntu/workSpace/public;
    location / {
        try_files $uri =404;
    }
}
NGINXEOF
sudo nginx -t 2>&1 | tail -2
if systemctl is-active nginx &>/dev/null; then
    sudo nginx -s reload
else
    sudo systemctl enable --now nginx
fi
echo "✅ nginx 12121 端口就绪"
echo ""

# ===== 4.6. 装 mmx-cli（v5.3.4-6 新增 — 上网搜索能力） =====
echo "▶ 装 mmx-cli（MiniMax 上网搜索）..."
if ! command -v mmx &>/dev/null; then
    # 注意：装 mmx-cli，**不**是装空包 "mmx"（npm registry 上 mmx 1.0.0 是 199B 空包）
    npm install -g mmx-cli 2>&1 | tail -3
else
    echo "    mmx 已装: $(mmx --version 2>&1 | head -1)"
fi
echo "✅ mmx-cli 装好"
echo ""
echo "⚠️  重要：需要用户手动跑 'mmx auth login' 完成 OAuth 认证（需要浏览器）"
echo "    没 auth login → mmx 调 100% 失败（No credentials found）"
echo ""

# ===== 5. 写 service 文件（调 start.sh） =====
echo "▶ 写 $SERVICE_FILE ..."
sudo tee "$SERVICE_FILE" > /dev/null << EOF
[Unit]
Description=OpenCode Web Service (房间门团队)
Documentation=https://opencode.ai
After=network.target

[Service]
Type=simple
User=ubuntu
WorkingDirectory=${WORKSPACE}

# 进程管理
Restart=always
RestartSec=5
StandardOutput=append:/var/log/opencode-web.log
StandardError=append:/var/log/opencode-web.log

# 启动命令：调 ${WORKSPACE}/start.sh
# start.sh 内容：cd workSpace → export 认证 → exec opencode
ExecStart=${WORKSPACE}/start.sh

[Install]
WantedBy=multi-user.target
EOF

echo "✅ service 文件写入"
echo ""

# ===== 6. 启动 =====
echo "▶ daemon-reload + enable + start ..."
sudo systemctl daemon-reload
sudo systemctl enable --now "$SERVICE_NAME"
echo ""

# ===== 7. 验证 =====
sleep 3
echo "▶ 状态："
sudo systemctl status "$SERVICE_NAME" --no-pager -l | head -10
echo ""

echo "▶ 进程 cwd（应= ${WORKSPACE}）:"
PID=$(pgrep -f "opencode web" | head -1)
echo "  PID $PID: $(readlink /proc/$PID/cwd 2>/dev/null)"
echo ""

echo "▶ 端口 $PORT 监听："
ss -tlnp 2>&1 | grep "$PORT" || netstat -tlnp 2>&1 | grep "$PORT" || echo "⚠️  $PORT 端口未监听"
echo ""

echo "▶ HTTP 认证测试："
curl -sI -u "${USERNAME}:${PASSWORD}" "http://localhost:${PORT}/" 2>&1 | head -3
echo ""

echo "=========================================="
echo "  部署完成！"
echo "=========================================="
echo "workSpace 目录结构："
echo "  ${WORKSPACE}/"
echo "  ├── inbox/      # 入口（上传文件）"
echo "  ├── outbox/     # 出口（生成文件）"
echo "  ├── projects/   # 长期项目"
echo "  └── start.sh    # 启动脚本（cd + export + exec）"
echo ""
echo "访问："
echo "  - 本地：http://localhost:${PORT}"
echo "  - 公网：http://<CLOUD_SERVER_IP>:${PORT}（需安全组放行）"
echo "认证："
echo "  - 用户名：${USERNAME}"
echo "  - 密码：${PASSWORD}"
echo ""
echo "运维命令："
echo "  bash ~/opt/myEggeggAgentTeam/scripts/ops-start.sh    # 启动"
echo "  bash ~/opt/myEggeggAgentTeam/scripts/ops-stop.sh     # 停止"
echo "  bash ~/opt/myEggeggAgentTeam/scripts/ops-restart.sh  # 重启"
echo "  bash ~/opt/myEggeggAgentTeam/scripts/ops-status.sh   # 状态"
echo "  bash ~/opt/myEggeggAgentTeam/scripts/ops-logs.sh     # 实时日志"

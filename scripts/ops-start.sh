#!/usr/bin/env bash
# ops-start.sh - 启动 opencode-web 服务（systemd）
# 用途：运维人员快速启动
# v5.3.4-1: 配置硬编码到脚本（不依赖 /etc/systemd/system/.../opencode-web.service 里的 Environment=）

set -euo pipefail

# ===== 硬编码配置 =====
USERNAME="<WEB_USERNAME>"
PASSWORD="<WEB_PASSWORD>"
PORT="4096"
OPENCODE_BIN="/home/ubuntu/.local/node/bin/opencode"
SERVICE_NAME="opencode-web.service"
SERVICE_FILE="/etc/systemd/system/opencode-web.service"

# ===== 1. 检查 service 文件是否含硬编码配置 =====
if ! grep -q "OPENCODE_SERVER_USERNAME=${USERNAME}" "$SERVICE_FILE" 2>/dev/null; then
    echo "⚠️  service 文件不含硬编码配置: $SERVICE_FILE"
    echo "    实际:"
    grep -i "OPENCODE_SERVER" "$SERVICE_FILE" 2>/dev/null | head -3 || echo "    （无 OPENCODE_SERVER 行）"
    echo ""
    echo "修复方法：跑 ops-install.sh 重写 service 文件"
    exit 1
fi

# ===== 2. daemon-reload + enable + start =====
echo "▶ 启动 $SERVICE_NAME ..."
sudo systemctl daemon-reload
sudo systemctl enable --now "$SERVICE_NAME"
echo "✅ $SERVICE_NAME 已启动"
echo ""

# ===== 3. 状态输出 =====
echo "▶ 状态："
sudo systemctl status "$SERVICE_NAME" --no-pager -l | head -10
echo ""

echo "▶ 端口监听："
ss -tlnp 2>&1 | grep "$PORT" || netstat -tlnp 2>&1 | grep "$PORT" || echo "⚠️  $PORT 端口未监听（看上面日志排查）"
echo ""

echo "▶ 访问地址："
echo "  - 本地：http://localhost:${PORT}"
echo "  - 公网：http://<CLOUD_SERVER_IP>:${PORT}（需安全组放行）"
echo "  - Cloudflare Tunnel：需自行配置（见 docs/operations.md）"
echo ""

echo "▶ 认证（硬编码到本脚本）："
echo "  - 用户名：${USERNAME}"
echo "  - 密码：${PASSWORD}"

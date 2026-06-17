#!/usr/bin/env bash
# ops-start.sh - 启动 opencode-web 服务（systemd）
# 用途：运维人员快速启动
# 等价于：sudo systemctl daemon-reload && sudo systemctl enable --now opencode-web

set -euo pipefail

echo "▶ 启动 opencode-web 服务..."
sudo systemctl daemon-reload
sudo systemctl enable --now opencode-web
echo ""
echo "✅ opencode-web 已启动"
echo ""
echo "▶ 状态："
sudo systemctl status opencode-web --no-pager -l | head -10
echo ""
echo "▶ 端口监听："
ss -tlnp 2>&1 | grep 4096 || netstat -tlnp 2>&1 | grep 4096 || echo "⚠️  4096 端口未监听（看上面日志排查）"
echo ""
echo "▶ 访问地址："
echo "  - 本地：http://localhost:4096"
echo "  - 公网：http://<CLOUD_SERVER_IP>:4096（需安全组放行）"
echo "  - Cloudflare Tunnel：需自行配置（见 docs/operations.md）"
echo ""
echo "▶ 认证：用户名 <WEB_USERNAME> / 密码 <WEB_PASSWORD>"

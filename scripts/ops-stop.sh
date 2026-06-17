#!/usr/bin/env bash
# ops-stop.sh - 停止 opencode-web 服务（systemd）
# 用途：运维人员快速停止
# 等价于：sudo systemctl stop opencode-web

set -euo pipefail

echo "▶ 停止 opencode-web 服务..."
sudo systemctl stop opencode-web
echo ""
echo "✅ opencode-web 已停止"
echo ""
echo "▶ 状态："
sudo systemctl status opencode-web --no-pager -l | head -5
echo ""
echo "▶ 端口监听："
ss -tlnp 2>&1 | grep 4096 || netstat -tlnp 2>&1 | grep 4096 || echo "✅ 4096 端口已释放"

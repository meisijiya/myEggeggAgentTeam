#!/usr/bin/env bash
# ops-restart.sh - 重启 opencode-web 服务（systemd）
# 用途：运维人员快速重启（修改 service 文件后必跑）
# v5.3.4-1: 配置硬编码到脚本（不依赖 service 文件 Environment=）

set -euo pipefail

# ===== 硬编码配置 =====
PORT="4096"
SERVICE_NAME="opencode-web.service"

echo "▶ 重启 $SERVICE_NAME ..."
sudo systemctl restart "$SERVICE_NAME"
echo ""
echo "✅ $SERVICE_NAME 已重启"
sleep 2
echo ""

echo "▶ 状态："
sudo systemctl status "$SERVICE_NAME" --no-pager -l | head -10
echo ""

echo "▶ 端口监听："
ss -tlnp 2>&1 | grep "$PORT" || netstat -tlnp 2>&1 | grep "$PORT" || echo "⚠️  $PORT 端口未监听"
echo ""

echo "▶ 最近 10 行日志："
sudo journalctl -u "$SERVICE_NAME" --no-pager -n 10 2>&1 || tail -10 /var/log/opencode-web.log

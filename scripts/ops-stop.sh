#!/usr/bin/env bash
# ops-stop.sh - 停止 opencode-web 服务（systemd）
# 用途：运维人员快速停止
# v5.3.4-1: 配置硬编码到脚本（不依赖 service 文件 Environment=）

set -euo pipefail

# ===== 硬编码配置 =====
PORT="4096"
SERVICE_NAME="opencode-web.service"

echo "▶ 停止 $SERVICE_NAME ..."
sudo systemctl stop "$SERVICE_NAME"
echo ""
echo "✅ $SERVICE_NAME 已停止"
echo ""

echo "▶ 状态："
sudo systemctl status "$SERVICE_NAME" --no-pager -l | head -5
echo ""

echo "▶ 端口监听："
ss -tlnp 2>&1 | grep "$PORT" || netstat -tlnp 2>&1 | grep "$PORT" || echo "✅ $PORT 端口已释放"

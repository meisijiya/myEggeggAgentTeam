#!/usr/bin/env bash
# ops-restart.sh - 重启 opencode-web 服务（systemd）
# 用途：运维人员快速重启（修改配置后必跑）
# 等价于：sudo systemctl restart opencode-web

set -euo pipefail

echo "▶ 重启 opencode-web 服务..."
sudo systemctl restart opencode-web
echo ""
echo "✅ opencode-web 已重启"
sleep 2
echo ""
echo "▶ 状态："
sudo systemctl status opencode-web --no-pager -l | head -10
echo ""
echo "▶ 端口监听："
ss -tlnp 2>&1 | grep 4096 || netstat -tlnp 2>&1 | grep 4096 || echo "⚠️  4096 端口未监听"
echo ""
echo "▶ 最近 10 行日志："
sudo journalctl -u opencode-web --no-pager -n 10 2>&1 || tail -10 /var/log/opencode-web.log

#!/usr/bin/env bash
# ops-status.sh - 查看 opencode-web 服务状态
# 用途：运维人员快速诊断
# v5.3.4-1: 配置硬编码到脚本（不依赖 service 文件 Environment=）

set -euo pipefail

# ===== 硬编码配置 =====
USERNAME="<WEB_USERNAME>"
PASSWORD="<WEB_PASSWORD>"
PORT="4096"
SERVICE_NAME="opencode-web.service"

echo "=========================================="
echo "  opencode-web 服务状态"
echo "=========================================="
echo ""

echo "▶ 1. systemd 状态："
sudo systemctl status "$SERVICE_NAME" --no-pager -l
echo ""

echo "▶ 2. 端口 $PORT 监听："
ss -tlnp 2>&1 | grep "$PORT" || netstat -tlnp 2>&1 | grep "$PORT" || echo "⚠️  $PORT 端口未监听"
echo ""

echo "▶ 3. 进程："
ps aux | grep -E "opencode web" | grep -v grep || echo "⚠️  无 opencode 进程"
echo ""

echo "▶ 4. 本地访问测试："
curl -sI -u "${USERNAME}:${PASSWORD}" "http://localhost:${PORT}/" 2>&1 | head -3 || echo "❌ 本地访问失败"
echo ""

echo "▶ 5. 部署目录状态："
echo "  agents: $(ls ~/.config/opencode/agents/ 2>/dev/null | wc -l) 个"
echo "  skills: $(ls -d ~/.config/opencode/skills/*/ 2>/dev/null | wc -l) 个"
echo "  opencode.json: $([ -f ~/.config/opencode/opencode.json ] && echo OK || echo MISSING)"
echo "  AGENTS.md: $([ -f ~/.config/opencode/AGENTS.md ] && echo OK || echo MISSING)"
echo "  memory 种子: $(ls ~/.roomdoor-memory/active/ 2>/dev/null | wc -l) 个"
echo ""

echo "▶ 6. cron 状态："
crontab -l 2>/dev/null | grep -i memory || echo "⚠️  无 memory cron"
echo ""

echo "▶ 7. 最近 5 行日志："
sudo journalctl -u "$SERVICE_NAME" --no-pager -n 5 2>&1 || tail -5 /var/log/opencode-web.log

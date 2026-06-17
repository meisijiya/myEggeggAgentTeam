#!/usr/bin/env bash
# ops-status.sh - 查看 opencode-web 服务状态
# 用途：运维人员快速诊断
# 等价于：sudo systemctl status opencode-web --no-pager -l

set -euo pipefail

echo "=========================================="
echo "  opencode-web 服务状态"
echo "=========================================="
echo ""

echo "▶ 1. systemd 状态："
sudo systemctl status opencode-web --no-pager -l
echo ""

echo "▶ 2. 端口 4096 监听："
ss -tlnp 2>&1 | grep 4096 || netstat -tlnp 2>&1 | grep 4096 || echo "⚠️  4096 端口未监听"
echo ""

echo "▶ 3. 进程："
ps aux | grep -E "opencode web" | grep -v grep || echo "⚠️  无 opencode 进程"
echo ""

echo "▶ 4. 本地访问测试："
curl -sI -u <WEB_USERNAME>:<WEB_PASSWORD> http://localhost:4096/ 2>&1 | head -3 || echo "❌ 本地访问失败"
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
sudo journalctl -u opencode-web --no-pager -n 5 2>&1 || tail -5 /var/log/opencode-web.log

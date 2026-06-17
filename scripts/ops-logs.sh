#!/usr/bin/env bash
# ops-logs.sh - 查看 opencode-web 实时日志
# 用途：运维人员快速查看日志
# 等价于：sudo journalctl -u opencode-web -f

set -euo pipefail

echo "▶ opencode-web 实时日志（Ctrl+C 退出）..."
echo ""
# 优先 journalctl，没有就用文件
if sudo journalctl -u opencode-web -n 1 &>/dev/null; then
    sudo journalctl -u opencode-web -f
else
    tail -f /var/log/opencode-web.log
fi

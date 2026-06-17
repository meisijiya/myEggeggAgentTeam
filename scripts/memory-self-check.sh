#!/usr/bin/env bash
# memory-self-check.sh - 凌晨 4 点 update agent 自检（硬规则版）
#
# 为什么是 shell 脚本而不是 opencode task:
# - opencode CLI 没有 `task` 子命令（实测验证），没有 `opencode run "<agent-role>"` 这种 subagent 调度语法
# - cron 环境下没有"调 update agent"的标准方式
# - 设计 §6.3 说"凌晨 4 点跑自检"，主要做：合并/归档/软删除/容量检查
# - 硬规则（软删除、容量日志）用 shell 即可；智能合并/归档留给房间门 @update 触发
#
# 部署路径：/opt/myEggeggAgentTeam/scripts/memory-self-check.sh

set -euo pipefail

ACTIVE_DIR=~/.roomdoor-memory/active
ARCHIVE_DIR=~/.roomdoor-memory/archive
PENDING_DIR=~/.roomdoor-memory/_pending_delete
META_DIR=~/.roomdoor-memory/meta
LOG=$META_DIR/cron.log

mkdir -p "$ACTIVE_DIR" "$ARCHIVE_DIR" "$PENDING_DIR" "$META_DIR"

log() { echo "[$(date -Iseconds)] $*" >> "$LOG"; }

log "=== 凌晨 4 点 memory 自检开始 ==="

# 1. 容量检查（超限警告；不自动压缩——留给 @update 触发）
for f in "$ACTIVE_DIR"/*.md; do
    if [ -f "$f" ]; then
        name=$(basename "$f")
        lines=$(wc -l < "$f")
        case "$name" in
            profile.md) max=100 ;;
            current.md) max=200 ;;
            preferences.md) max=150 ;;
            finance.md) max=200 ;;
            *) max=999 ;;
        esac
        if [ "$lines" -gt "$max" ]; then
            log "⚠️  $name: $lines 行（上限 $max）—— 需要房间门 @update 整理"
        else
            log "✅ $name: $lines/$max 行"
        fi
    fi
done

# 2. 总大小检查（> 5MB 警告）
TOTAL=$(du -sb "$ACTIVE_DIR" 2>/dev/null | awk '{print $1}')
if [ "${TOTAL:-0}" -gt 5242880 ]; then
    log "⚠️  active/ 总大小 $(echo "$TOTAL" | awk '{printf "%.1f MB", $1/1048576}') —— 超过 5MB 上限"
else
    log "✅ active/ 总大小 $(echo "${TOTAL:-0}" | awk '{printf "%.1f KB", $1/1024}')"
fi

# 3. 软删除确认（> 7 天 → 真删）
if [ -d "$PENDING_DIR" ]; then
    deleted=$(find "$PENDING_DIR" -type f -mtime +7 -delete -print 2>/dev/null | wc -l)
    if [ "$deleted" -gt 0 ]; then
        log "✅ 软删除: 清理了 $deleted 个 > 7 天的 _pending_delete 文件"
    else
        log "✅ 软删除: 无需清理"
    fi
fi

# 4. 软删除候选（active/ 里 mtime > 90 天的条目）
# 注：这是"提醒"，不自动归档
if [ -d "$ACTIVE_DIR" ]; then
    old_files=$(find "$ACTIVE_DIR" -name "current.md" -mtime +90 2>/dev/null | wc -l)
    if [ "$old_files" -gt 0 ]; then
        log "💡 提示: current.md > 90 天未更新，建议 @update 归档"
    fi
fi

log "=== 自检完成 ==="
exit 0

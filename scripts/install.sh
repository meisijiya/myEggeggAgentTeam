#!/usr/bin/env bash
# install.sh - 房间门 Agent 团队一键安装（云服务器版）

set -euo pipefail

echo "🏠 房间门 Agent 团队一键安装"
echo ""

# Step 1: 备份现有配置
BACKUP=~/.config/opencode/backup/$(date +%Y%m%d-%H%M%S)
mkdir -p "$BACKUP"
# 备份已有的 agents/ 和 skills/（如果有的话）
[ -d ~/.config/opencode/agents ] && cp -r ~/.config/opencode/agents "$BACKUP/" 2>/dev/null || true
[ -d ~/.config/opencode/skills ] && cp -r ~/.config/opencode/skills "$BACKUP/" 2>/dev/null || true
[ -f ~/.config/opencode/AGENTS.md ] && cp ~/.config/opencode/AGENTS.md "$BACKUP/" 2>/dev/null || true
echo "→ Step 1/7: 备份现有配置到 $BACKUP"

# Step 2: 安装 6 个 Agent
mkdir -p ~/.config/opencode/agents
cp agents/*.md ~/.config/opencode/agents/
echo "→ Step 2/7: 安装 6 个 Agent 到 ~/.config/opencode/agents/"

# Step 3: 安装 4 个 MVP 团队专属 skill
mkdir -p ~/.config/opencode/skills
cp -r skills/dispatch-protocol skills/memory-manager skills/doc-processing skills/memory-loader ~/.config/opencode/skills/
echo "→ Step 3/7: 安装 4 个 MVP 团队专属 skill"

# Step 4: 安装第三方 skill（固定 commit hash；失败仅警告）
echo "→ Step 4/7: 安装 anthropics 办公 skill..."
npx skills add anthropics/skills@<commit_hash> --skill docx pdf pptx 2>&1 | tee -a install.log || echo "⚠️  anthropics 技能安装失败，跳过"

echo "→ Step 4b/7: 安装会计财务 skill..."
npx skills add <财务 skill repo>@<commit_hash> --skill tax-advisor expense-tracker 2>&1 | tee -a install.log || echo "⚠️  财务技能安装失败，跳过"

# Step 5: 提示用户配置 opencode.json
echo ""
echo "⚠️  Step 5/7: 请手动配置 ~/.config/opencode/opencode.json："
echo "    参考设计文档 §5.1，给 6 个 agent 分配 model + fallback_model"
echo "    配置完成后，重启 opencode 让配置生效"
echo ""

# Step 6: 初始化 memory
mkdir -p ~/.roomdoor-memory/{active,archive,_pending_delete,meta}
cp memory-seed/*.md ~/.roomdoor-memory/active/
echo "→ Step 6/7: 初始化 ~/.roomdoor-memory/"

# Step 7: AGENTS.md + cron
[ ! -f ~/.config/opencode/AGENTS.md ] && cp templates/AGENTS.md ~/.config/opencode/AGENTS.md
(crontab -l 2>/dev/null; echo "0 4 * * * /usr/local/bin/opencode task(update, 'memory-self-check') >> ~/.roomdoor-memory/meta/cron.log 2>&1") | crontab -

echo "→ Step 7/7: 设置凌晨 4 点 cron + AGENTS.md 模板"
echo ""
echo "✅ 安装完成！"
echo ""
echo "下一步："
echo "1. 配置 ~/.config/opencode/opencode.json（见设计文档 §5.1）"
echo "2. 重启 opencode：opencode web --port 8080"
echo "3. 通过 Cloudflare Tunnel 暴露 8080 端口（见 docs/deployment.md）"
echo "4. 女朋友打开浏览器访问 https://your-domain.example.com"
echo "5. @房间门 启动对话"

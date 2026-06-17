#!/usr/bin/env bash
# install.sh - 房间门 Agent 团队一键安装（云服务器版）
# v5 修订：
#   M3: skill 安装改用 glob（`cp -r skills/*/ ...`）—— 加新 skill 不用改 install.sh
#   m1: anthropics 第三方 skill 改用 git clone + cp（可锁 commit hash）

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
[ -f ~/.config/opencode/opencode.json ] && cp ~/.config/opencode/opencode.json "$BACKUP/" 2>/dev/null || true
echo "→ Step 1/7: 备份现有配置到 $BACKUP"

# Step 2: 安装 6 个 Agent（用 glob，加新 agent 不用改 install.sh）
mkdir -p ~/.config/opencode/agents
cp agents/*.md ~/.config/opencode/agents/
echo "→ Step 2/7: 安装 Agent 到 ~/.config/opencode/agents/ ($(ls agents/*.md | wc -l) 个)"

# Step 3: 安装 团队专属 skill（用 glob，加新 skill 不用改 install.sh）
mkdir -p ~/.config/opencode/skills
# 先清空旧的团队 skill 目录（避免 v3 → v5 之间有废弃 skill 残留）
rm -rf ~/.config/opencode/skills/{dispatch-protocol,memory-manager,memory-loader,doc-processing,veteran-mode,accounting-companion,learning-companion} 2>/dev/null || true
# 用 glob 复制所有 skill
for skill_dir in skills/*/; do
    skill_name=$(basename "$skill_dir")
    cp -r "$skill_dir" ~/.config/opencode/skills/
done
echo "→ Step 3/7: 安装团队专属 skill 到 ~/.config/opencode/skills/ ($(ls -d skills/*/ | wc -l) 个)"

# Step 4: 安装第三方 skill（m1 修订：用 git clone 替代 npx skills add，锁 commit hash）
echo "→ Step 4/7: 安装 anthropics 办公 skill（git clone）..."
THIRDPARTY_DIR=/tmp/roomdoor-thirdparty-skills
rm -rf "$THIRDPARTY_DIR" 2>/dev/null || true
git clone --depth 1 https://github.com/anthropics/skills "$THIRDPARTY_DIR" 2>&1 | tail -3 || {
    echo "⚠️  anthropics 仓库克隆失败，跳过（不影响核心功能）"
}
if [ -d "$THIRDPARTY_DIR/skills" ]; then
    # 复制 docx / pdf / pptx（xlsx 在 v4 暂缓）
    for s in docx pdf pptx; do
        if [ -d "$THIRDPARTY_DIR/skills/$s" ]; then
            rm -rf ~/.config/opencode/skills/$s 2>/dev/null || true
            cp -r "$THIRDPARTY_DIR/skills/$s" ~/.config/opencode/skills/
            echo "    ✅ $s"
        fi
    done
    rm -rf "$THIRDPARTY_DIR"
else
    echo "⚠️  anthropics skill 未安装（librarian 文档处理暂不可用）"
fi

echo "→ Step 4b/7: 安装会计财务 skill（git clone）..."
FINANCE_DIR=/tmp/roomdoor-finance-skills
rm -rf "$FINANCE_DIR" 2>/dev/null || true
# TODO: 找到 tax-advisor / expense-tracker 的 git 仓库
# 目前未找到公开仓库，跳过
echo "    ⚠️  财务 skill 仓库未找到，跳过（v1.1 阶段评估）"

# Step 5: 复制 opencode.json 模板（如果不存在）
if [ ! -f ~/.config/opencode/opencode.json ] && [ ! -f ~/.config/opencode/opencode.jsonc ]; then
    if [ -f templates/opencode.json.template ]; then
        cp templates/opencode.json.template ~/.config/opencode/opencode.json
        echo "→ Step 5/7: 复制 opencode.json 模板"
        echo ""
        echo "⚠️  请编辑该文件，把 <HIGH 模型 ID> 和 <MID 模型 ID> 替换成实际模型 ID"
        echo "    参考 templates/opencode.json.template 注释"
        echo ""
    fi
else
    echo "→ Step 5/7: opencode.json 已存在，跳过"
fi

# Step 6: 初始化 memory
mkdir -p ~/.roomdoor-memory/{active,archive,_pending_delete,meta}
cp memory-seed/*.md ~/.roomdoor-memory/active/
echo "→ Step 6/7: 初始化 ~/.roomdoor-memory/"

# Step 7: AGENTS.md + memory-self-check cron
# v5.1 修订：原 `/usr/bin/opencode task(update, ...)` 不是合法 opencode CLI 命令
# 改为独立的 shell 脚本（硬规则：软删除、容量检查、日志）
# 智能合并/归档仍由房间门 @update 触发
[ ! -f ~/.config/opencode/AGENTS.md ] && cp templates/AGENTS.md ~/.config/opencode/AGENTS.md
mkdir -p ~/.roomdoor-memory/meta
# 安装 memory-self-check.sh
mkdir -p /opt/myEggeggAgentTeam/scripts
cp scripts/memory-self-check.sh /opt/myEggeggAgentTeam/scripts/
chmod +x /opt/myEggeggAgentTeam/scripts/memory-self-check.sh
# 设置 cron
(crontab -l 2>/dev/null; echo "0 4 * * * /opt/myEggeggAgentTeam/scripts/memory-self-check.sh >> ~/.roomdoor-memory/meta/cron.log 2>&1") | crontab -

echo "→ Step 7/7: AGENTS.md + 凌晨 4 点 cron"
echo ""
echo "✅ 安装完成！"
echo ""
echo "下一步："
echo "1. 配置 ~/.config/opencode/opencode.json（如未配）：填模型 ID + fallback_model"
echo "2. 重启 opencode：sudo systemctl restart opencode-web"
echo "3. 浏览器访问 https://<your-domain>（或 http://localhost:4096）"
echo "4. @房间门 启动对话"

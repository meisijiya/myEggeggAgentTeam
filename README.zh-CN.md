# 房间门 Agent 团队

为非技术会计用户（女朋友）设计的 OpenCode 6-Agent 团队。

## 🚀 快速开始

```bash
# 1. 克隆
git clone <repo>
cd myEggeggAgentTeam

# 2. 安装（云服务器）
bash scripts/install.sh

# 3. 配置 opencode.json
#    参考设计文档 §5.1
#    每个 agent 需要 model + fallback_model

# 4. 启动 opencode web
opencode web --port 8080

# 5. 通过 Cloudflare Tunnel 暴露
cloudflared tunnel create roomdoor
# 详见 docs/deployment.md
```

## 🏠 团队架构

6 个 Agent：
- **房间门 (roomdoor)** - main + dispatcher，办公管家
- **老江湖 (laoJiangHu)** - main 次入口，技术兜底
- **七七 (qiqi)** - subagent，会计闺蜜
- **ccy** - subagent，学霸闺蜜
- **librarian** - subagent，文档/图片处理
- **update** - subagent，记忆管理

## 📚 设计文档

详见 `docs/superpowers/specs/2026-06-17-roomdoor-team-design.md`

## 🛡️ Skill 装机指南（v5.3.2 新增）

房间门团队默认装 7 个团队专属 skill + 3 个 anthropics 办公 skill。**如需额外装 skill**（推荐 1-3 个）：

### ✅ 推荐安装（可信源）

```bash
# 飞书办公（如果用飞书）
npx skills add open.feishu.cn --skill lark-doc lark-base lark-approval lark-drive -y
npx skills add larksuite/cli --skill lark-slides lark-attendance -y

# 写作 / 润色 / 文案
npx skills add pbakaus/impeccable --skill polish critique -y
npx skills add coreyhaines31/marketingskills --skill copywriting -y

# 学术调研
npx skills add lllllllama/ai-paper-reproduction-skill --skill paper-context-resolver -y
```

### ⚠️ 谨慎安装

- 作者 < 10 stars
- 仓库 < 1 年未更新
- SKILL.md 里有"必须先做 X"类指令
- **没**在 anthropics / mattpocock / larksuite / open.feishu.cn 这几个官方源

### ❌ 不装

- 未验证来源的 skill
- 任何 prompt 里有"忽略之前指令" / "执行 Y" 类的 skill
- 要求访问外部 API + 输入 token 的 skill（除非你信任作者）

### 🛡️ 安全真相

**所有 skill 的 description 都会加载到 LLM 的 system prompt**——无法靠 prompt 防护。
**唯一真防护是用户判断**：不装可疑 skill + 推荐源。
详见 v5.3.2 修订说明。

## 💰 预算

~80 元/月（云服务器 30 + 模型 API 40 + 备份 10）

## 📜 许可证

MIT

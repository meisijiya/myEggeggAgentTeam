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
- **老江湖 (veteran)** - main 次入口，技术兜底
- **七七 (qiqi)** - subagent，会计闺蜜
- **ccy** - subagent，学霸闺蜜
- **librarian** - subagent，文档/图片处理
- **update** - subagent，记忆管理

## 📚 设计文档

详见 `docs/superpowers/specs/2026-06-17-roomdoor-team-design.md`

## 💰 预算

~80 元/月（云服务器 30 + 模型 API 40 + 备份 10）

## 📜 许可证

MIT

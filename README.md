# 房间门 Agent 团队

> 为非技术会计用户（女朋友）设计的 OpenCode 6-Agent 团队。
>
> **版本**：v5.3.4（房间门 6-Agent + 16 skill + 云服务器部署）
> **远程仓库**：https://github.com/meisijiya/myEggeggAgentTeam
> **许可证**：MIT

## 🎯 这是什么

一个为非技术用户（女朋友）定制的 **OpenCode 6-Agent 团队**，跑在云服务器上，能：

- 🤖 调度 6 个专业 Agent（办公管家 / 技术兜底 / 会计闺蜜 / 学霸闺蜜 / 文档处理 / 记忆管理）
- 📚 自动装载 16 个 skill（团队专属 + 第三方）
- 🌐 通过 Web 界面 + Cloudflare Tunnel 远程访问
- 🔒 默认带认证 + 占位符安全机制（不进 git 历史）

## 🚀 快速开始

### 1. 云服务器一键部署

```bash
# 在云服务器上跑（ubuntu 用户，不需要 sudo）
bash scripts/install.sh
```

详细步骤：[`docs/operations.md`](docs/operations.md)

### 2. 启动 / 停止 / 查看状态

```bash
scripts/ops-install.sh   # 首次部署 + 注册 systemd service
scripts/ops-start.sh     # 启动 opencode web
scripts/ops-stop.sh      # 停止
scripts/ops-restart.sh   # 重启
scripts/ops-status.sh    # 查看状态（7 项检查）
scripts/ops-logs.sh      # 查看日志
```

### 3. 远程访问（Cloudflare Tunnel）

```bash
cloudflared tunnel create roomdoor
# 详见 docs/deployment.md
```

访问 `https://<CLOUD_SERVER_IP>:4096`，用 `<WEB_USERNAME>` / `<WEB_PASSWORD>` 登录。

## 🏠 团队架构

6 个 Agent 协同工作：

| Agent | 角色 | 模型 | 任务 |
|-------|------|------|------|
| **房间门 (roomdoor)** | main + dispatcher | `opencode/deepseek-flash-free` | 办公管家，编排全家 |
| **老江湖 (laoJiangHu)** | main 次入口 | `MiniMax-M3` | 技术兜底，高难度编码 |
| **七七 (qiqi)** | subagent | `MiniMax-M3` | 会计闺蜜（朋友） |
| **ccy** | subagent | `MiniMax-M3` | 学霸闺蜜 |
| **librarian** | subagent | `MiniMax-M3` | 文档 / 图片处理 |
| **update** | subagent | `opencode/deepseek-flash-free` | 记忆管理（single-writer） |

详细设计：[`docs/superpowers/specs/2026-06-17-roomdoor-team-design.md`](docs/superpowers/specs/2026-06-17-roomdoor-team-design.md)

## 📚 文档地图（克隆后必读）

| 文档 | 用途 |
|------|------|
| [**CONTEXT.md**](CONTEXT.md) | 7 个核心术语（房间门团队 / opencode / 模型分档 / L3 升级 / 记忆被动更新 / 物理隔离 / 退场机制）|
| [**AGENTS.md**](AGENTS.md) | 项目级开发约定（TDD / DRY / YAGNI / commit / 审查）|
| [**docs/SECURITY.md**](docs/SECURITY.md) | 5 个占位符 + 部署前 checklist（**先读这个！**）|
| [**docs/operations.md**](docs/operations.md) | 运维手册（nginx + systemd + ops 脚本详解）|
| [**docs/deployment.md**](docs/deployment.md) | 部署文档（物理隔离 + Cloudflare Tunnel）|
| [**docs/adr/**](docs/adr/) | 架构决策记录（MADR 4 段式）|
| [**docs/gotchas/**](docs/gotchas/) | 踩坑教训（可避免性自评 ≥3）|

## 🛡️ 安全

**所有敏感信息不进 git 历史**。代码用占位符（`<CLOUD_SERVER_IP>` / `<WEB_USERNAME>` / `<WEB_PASSWORD>`），部署时手动替换。

详见 [`docs/SECURITY.md`](docs/SECURITY.md)。

## ❓ 常见问题

**Q: 部署需要 sudo 吗？**
A: 不需要。所有路径都用 `~/opt/` 和 `/home/ubuntu/`，普通 ubuntu 用户可跑。

**Q: mmx-cli 调用失败？**
A: 必须先在云服务器跑 `mmx auth login`（OAuth 浏览器流）。未认证前所有 mmx 调用 100% 失败。

**Q: 想加新 skill 怎么操作？**
A: 放进 `skills/<skill-name>/SKILL.md`，重新跑 `scripts/install.sh`（自动复制到云服务器 `~/.config/opencode/skills/`）。

**Q: 历史 commit 怎么压缩了？**
A: 我们把 34 个 commit 压缩到 6 个语义 commit，每个对应一个里程碑。如需查旧 hash，用 `git log backup-pre-squash-2026-06-18`。

## 📜 许可证

MIT
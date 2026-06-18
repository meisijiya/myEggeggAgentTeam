# 房间门 Agent 团队

> 为非技术会计用户（女朋友）设计的 OpenCode 6-Agent 团队。
>
> **版本**：v5.3.4（房间门 6-Agent + 16 skill + 云服务器部署）
> **远程仓库**：https://github.com/meisijiya/myEggeggAgentTeam
> **许可证**：MIT

## 🎯 这是什么

一个为非技术用户（女朋友）定制的 **OpenCode 6-Agent 团队**，跑在云服务器上，能：

- 🤖 调度 6 个专业 Agent（办公管家 / 技术兜底 / 会计闺蜜 / 学霸闺蜜 / 文档处理 / 记忆管理）
- 📚 自动装载 16 个 skill（7 个团队专属 + 3 个 anthropics + 6 个第三方）
- 🌐 通过 Web 界面（端口 4096）+ Cloudflare Tunnel 远程访问
- 🔒 默认带认证 + 占位符安全机制（敏感信息**不**进 git 历史）
- 💾 凌晨 4 点 cron 自动检查记忆 + 备份

## 🚀 快速开始

### 1. 云服务器一键部署

```bash
# 在云服务器上跑（ubuntu 用户，不需要 sudo）
bash scripts/install.sh
```

**install.sh 会自动**：
1. 备份现有配置到 `~/.config/opencode/backup/<时间戳>/`
2. 复制 6 个 agent prompt + 16 个 skill 到 `~/.config/opencode/`
3. 复制 `opencode.json` 模板 + `AGENTS.md`
4. 创建工作目录 `~/workSpace/{inbox,outbox,projects,public}`
5. 打印后续步骤

详细步骤：[`docs/operations.md`](docs/operations.md)

### 2. 注册 systemd service + 启动

```bash
scripts/ops-install.sh   # 首次部署：写 service + start + enable
scripts/ops-start.sh     # 后续启动
scripts/ops-stop.sh      # 停止
scripts/ops-restart.sh   # 重启
scripts/ops-status.sh    # 查看状态（7 项检查：service / 端口 / 进程 / 内存 / 日志 / 备份 / mmx）
scripts/ops-logs.sh      # 查看日志（journalctl -u opencode-web -f）
```

**注意**：所有配置（USERNAME / PASSWORD / PORT / OPENCODE_BIN）**硬编码到 ops 脚本头部**，service 文件用 `bash -c` 显式 export——不依赖 service 文件的 `Environment=` 行（避免 systemd 解析问题）。

### 3. 远程访问（Cloudflare Tunnel）

```bash
cloudflared tunnel create roomdoor
cloudflared tunnel route dns roomdoor <your-domain>
cloudflared tunnel run roomdoor
```

访问 `https://<CLOUD_SERVER_IP>:4096`（或你的域名），用 `<WEB_USERNAME>` / `<WEB_PASSWORD>` 登录。

详见 [`docs/deployment.md`](docs/deployment.md)

## 🏠 团队架构

6 个 Agent 协同工作：

| Agent | 角色 | 模型 | 任务 |
|-------|------|------|------|
| **房间门 (roomdoor)** | main + dispatcher | `opencode/deepseek-flash-free` | 办公管家，编排全家，理解需求、委派任务 |
| **老江湖 (laoJiangHu)** | main 次入口 | `MiniMax-M3` | 技术兜底，高难度编码、技术攻关 |
| **七七 (qiqi)** | subagent | `MiniMax-M3` | 会计闺蜜（朋友，参谋 + 轻量执行）|
| **ccy** | subagent | `MiniMax-M3` | 学霸闺蜜 |
| **librarian** | subagent | `MiniMax-M3` | 文档 / 图片处理（PDF / DOC / PPT / XLS）|
| **update** | subagent | `opencode/deepseek-flash-free` | 记忆管理（single-writer，写 CONTEXT / AGENTS / ADR）|

详细设计：[`docs/superpowers/specs/2026-06-17-roomdoor-team-design.md`](docs/superpowers/specs/2026-06-17-roomdoor-team-design.md)

## 📚 文档地图（克隆后必读）

| 文档 | 用途 | 优先级 |
|------|------|--------|
| [**CONTEXT.md**](CONTEXT.md) | 7 个核心术语（房间门团队 / opencode / 模型分档 / L3 升级 / 记忆被动更新 / 物理隔离 / 退场机制）| 🔴 必读 |
| [**AGENTS.md**](AGENTS.md) | 项目级开发约定（TDD / DRY / YAGNI / commit / 审查）| 🔴 必读 |
| [**docs/SECURITY.md**](docs/SECURITY.md) | 5 个占位符 + 部署前 checklist | 🔴 **部署前必读** |
| [**docs/operations.md**](docs/operations.md) | 运维手册（nginx + systemd + ops 脚本详解）| 🟡 部署后 |
| [**docs/deployment.md**](docs/deployment.md) | 部署文档（物理隔离 + Cloudflare Tunnel）| 🟡 远程访问 |
| [**docs/adr/**](docs/adr/) | 架构决策记录（MADR 4 段式）| 🟢 参考 |
| [**docs/gotchas/**](docs/gotchas/) | 踩坑教训（可避免性自评 ≥3）| 🟢 避坑 |

## 🛡️ Skill 装机指南

房间门团队默认装 **7 个团队专属 skill + 3 个 anthropics 办公 skill + 6 个第三方 skill**（共 16 个）：

### 7 个团队专属 skill

- `dispatch-protocol` / `memory-manager` / `memory-loader` / `doc-processing`
- `veteran-mode` / `accounting-companion` / `learning-companion`

### 3 个 anthropics 办公 skill

- `pdf` / `docx` / `pptx`（文档处理）

### 6 个第三方 skill

- `find-skills` / `skill-creator` / `mmxcli` / `expose-download-link`
- `baoyu-diagram` / `baoyu-translate`

**如需额外装 skill**（推荐 1-3 个）：

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

## 🛡️ 安全

**所有敏感信息不进 git 历史**。代码和文档用占位符，部署时手动替换。

| 占位符 | 含义 | 示例 |
|--------|------|------|
| `<CLOUD_SERVER_IP>` | 云服务器公网 IP | `42.x.x.x` |
| `<WEB_USERNAME>` | opencode web 认证用户名 | `ljh` |
| `<WEB_PASSWORD>` | opencode web 认证密码 | 强密码（16+ 字符）|
| `<SSH_KEY_FILENAME>` | SSH 私钥文件名 | `your-key.pem` |
| `<SSH_KEY_PATH>` | SSH 私钥完整路径 | `~/.ssh/your-key.pem` |

**部署前必读**：[`docs/SECURITY.md`](docs/SECURITY.md)

## 💰 预算

~80 元/月：
- 云服务器：30 元
- 模型 API：40 元
- 备份：10 元

## ❓ 常见问题

**Q: 部署需要 sudo 吗？**
A: 不需要。所有路径都用 `~/opt/` 和 `/home/ubuntu/`，普通 ubuntu 用户可跑。

**Q: mmx-cli 调用失败？**
A: 必须先在云服务器跑 `mmx auth login`（OAuth 浏览器流）。未认证前所有 mmx 调用 100% 失败。

**Q: 想加新 skill 怎么操作？**
A: 放进 `skills/<skill-name>/SKILL.md`，重新跑 `scripts/install.sh`（自动复制到云服务器 `~/.config/opencode/skills/`）。

**Q: 为什么 git 历史被压缩了？**
A: 我们把 34 个 commit 压缩到 6 个语义 commit，每个对应一个里程碑。如果需要查旧 hash，用 `git log backup-pre-squash-2026-06-18`（已备份）。

**Q: opencode web 怎么远程访问？**
A: 详见 [`docs/deployment.md`](docs/deployment.md) 的 Cloudflare Tunnel 部分。

**Q: 凌晨 4 点的 cron 干什么？**
A: `scripts/memory-self-check.sh` 自动检查 update Agent 的记忆文件完整性 + 备份。如果失败会写日志，但不报警（静默监控）。

**Q: 6 个 Agent 怎么选模型？**
A: roomdoor + update 用 `opencode/deepseek-flash-free`（便宜，适合调度/记忆）；其他 4 个用 `MiniMax-M3`（中上档，适合编码/思考）。

**Q: 想让 Agent 跑后台任务？**
A: 用 OneTwo 编排者委派，opencode 1.1+ 支持 `background=true`。详细见 AGENTS.md 的"委派协议"。

## 📜 许可证

MIT
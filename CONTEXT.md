# 房间门 Agent 团队

## Language

**房间门团队** (Room Door Team): 部署在云服务器上的多 Agent 团队，面向非技术用户（女朋友）。主入口是 `roomdoor` Agent，支持文档处理、财务计算、翻译、咨询等场景。
_Avoid_: "女朋友团队"（不准确），"房间门 Agent"（单体 vs 团队）

**opencode**: 底层 AI Agent 运行时平台，支持多 Agent 编排、subagent 调度、web UI 交互。本项目使用 opencode web + Cloudflare Tunnel 远程访问。
_Avoid_: "OpenAI"（无关）

**模型分档 HIGH/MID**: 模型能力分级。HIGH 用于复杂推理/主 Agent（roomdoor, laoJiangHu, librarian, qiqi），MID 用于简单任务（ccy, update）。各 Agent 可配置 fallback_model 降级。
_Avoid_: "大模型/小模型"（不精确——模型 ID 可能相同，只有档位标志不同）

**L3 升级** (Level 3 Escalation): 当 `roomdoor` 识别到高风险/高价值场景（金额 > 5000 元、含税法关键词、合同关键词、重大人生决策），显式 `@laoJiangHu`（老江湖）升级处理。
_Avoid_: "报错"、"升级"（太泛）

**记忆被动更新**: 记忆系统对用户完全透明——所有记忆读写通过 `update` Agent 在后台完成，用户不需要也不应知道记忆系统的存在。凌晨 4 点 cron + 写入时自检 + 房间门手动调度。
_Avoid_: "自动记忆"（暗示用户知情）

**物理隔离**: 云服务器 (~/.config/opencode/) 和老江湖本机的编程团队完全隔离，避免 AGENTS.md 规范污染和模型配额竞争。
_Avoid_: "分开部署"（不强调策略意图）

**退场机制**: subagent 完成任务后通过 `<result>` XML 块（含 `summary`/`files`/`next_steps`/`failure`）结构化退出，主 Agent 根据结果决定后续。`failure` 段触发上报 OneTwo 重分派或升级处理。
_Avoid_: "返回"、"退出"（太泛）

**single-writer**: 项目元信息（CONTEXT.md / AGENTS.md / docs/adr/ / docs/gotchas/）和记忆系统（~/.roomdoor-memory/）的写入原则——仅 `update` Agent 有权写入，避免多 Agent 并发冲突。
_Avoid_: "单写"、"独占写入"（英文原名更精确）

## Relationships

- 房间门团队运行在 opencode 之上
- 房间门团队由 roomdoor（主）、laoJiangHu（升级）、librarian、qiqi、ccy、update（6 个 Agent）组成
- update Agent 是记忆系统 + 项目元信息的 single-writer
- L3 升级是 roomdoor → laoJiangHu 的保卫逻辑
- 物理隔离是编程团队 ↔ 房间门团队之间的配置边界
- 退场机制是所有 subagent → roomdoor 的通信协议

## Flagged ambiguities

- "AGENTS.md" 有两份：templates/AGENTS.md（房间门 Agent 团队 prompt）和根目录 AGENTS.md（项目开发约定）——不要混淆
- 模型档位 `HIGH`/`MID` 不是模型名称，是能力分级标签

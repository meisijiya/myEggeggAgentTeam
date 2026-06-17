---
status: accepted
date: 2026-06-17
---

# ADR-0002: 选择 single-writer 原则的 update Agent 做记忆管理

## Context and Problem Statement

房间门团队有多个 Agent（roomdoor, veteran, librarian, qiqi, ccy, update）需要读写记忆系统（`~/.roomdoor-memory/`）。如果允许多 Agent 直接写记忆，可能导致：1) 文件并发冲突（Markdown + grep 非事务性）；2) LLM 误判——不同 Agent 对同一记忆的不同理解；3) 记忆不可追溯。同时需要确保 `~/.config/opencode/`（opencode 的核心配置）不受团队 Agent 误写影响。

## Considered Options

1. **update Agent 做 single-writer + 不动 `~/.config/opencode/`**（选择）—— 所有记忆写入通过 `update` Agent 调度；`~/.config/opencode/` 明确定义为不可写域。
   - ✅ Pro: 消除多 Agent 写入冲突——单点序列化
   - ✅ Pro: `~/.config/opencode/` 保护——opencode 核心配置不被 Agent 误写
   - ✅ Pro: 记忆可审计——所有写入都有 `source` + `timestamp` 字段
   - ❌ Con: update Agent 成为记忆吞吐瓶颈（但写入频率低，不构成实际瓶颈）
   - ❌ Con: 需要额外 subagent 调度（但 update 本来就是 subagent）

2. **所有 Agent 可直接写记忆（无 single-writer）**
   - ✅ Pro: 调度开销低——不用找 update
   - ❌ Con: 文件并发冲突（多个 Agent 同时 append 同一文件）
   - ❌ Con: 记忆一致性无保证——不同 Agent 可能对同一事实写不同版本
   - ❌ Con: 无审计日志——不知道谁在何时写了什么

3. **Git 作为底层存储 + 各 Agent 写文件后 commit**
   - ✅ Pro: 自然解决并发（git merge）
   - ❌ Con: Git commit 频率过高；merge 冲突仍需人为解决
   - ❌ Con: 复杂度远高于当前需求

## Decision Outcome

Chosen: "**update Agent 做 single-writer + 不动 `~/.config/opencode/`**", 因为项目规模（个人团队，低频写入）下单 Agent 序列化方案足够且最简洁，同时保护 opencode 系统配置不被误写。

### Consequences

- ✅ 记忆系统文件结构清晰（`active/`, `archive/`, `_pending_delete/`）
- ✅ 所有写入带 `source` + `timestamp`，可追溯
- ✅ `~/.config/opencode/` 安全——所有 Agent prompt 显式禁止写该目录
- ❌ subagent 写入记忆需 `@update`（增加一次 subagent 调度开销）
- ❌ 紧急情况下（update 异常）需要 fallback 机制

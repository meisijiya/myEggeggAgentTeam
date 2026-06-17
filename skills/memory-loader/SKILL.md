---
name: memory-loader
description: 按需加载 ~/.roomdoor-memory/ 内容到当前 context
---

# Memory Loader

按需加载记忆片段到房间门/老江湖/update 的 context。

## 按需加载策略

**不加载整个 active/ 目录**（避免 token 爆炸）。而是：

- 任务开始时，update 通过 `@update 搜索 <关键词>` 返回**所需片段**
- 房间门/老江湖的 prompt 模板把片段拼接到 subagent prompt 中

## 触发关键词

| 触发词 | 加载路径 |
|--------|---------|
| "会计 / 分录 / 报表 / 税务" | `finance/*.md` |
| "男朋友 / 老江湖" | `relationships/laoJiangHu.md`（v1.1）|
| "闺蜜 / 七七 / ccy" | `relationships/qiqi.md` 等（v1.1）|
| "加班 / 项目 / 任务" | `current.md` |
| "喜欢 / 不喜欢 / 习惯" | `preferences.md` |

## 自动加载（session 开始时）

- `active/profile.md` → 房间门和老江湖的 prompt 必读
- `meta/index.md` → 索引文件
- `active/current.md` → 当前项目上下文

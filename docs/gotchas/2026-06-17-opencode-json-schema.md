# 2026-06-17 — opencode.json 模板必须包含 `$schema` 字段

> **status**: ACTIVE
> **avoidability_score**: 5
> **category**: config

## 症状

v4 设计文档 `docs/superpowers/specs/2026-06-17-roomdoor-team-design.md` 中的 opencode.json 示例没有 `$schema` 字段。最终验证时被用户（老江湖）指出："格式不应该是官方：`$schema: https://opencode.ai/config.json`"。

## 根因

凭印象写 opencode 配置格式，没有参考官方 schema。**opencode 官方定义了 JSON Schema（`https://opencode.ai/config.json`），不包含该字段的配置虽然可以运行，但缺少 IDE 校验和版本约束。**

## 修复

在 `templates/opencode.json.template` 中添加：

```json
{
  "$schema": "https://opencode.ai/config.json",
  "server": {
    "port": 8080
  },
  "default_agent": "roomdoor",
  "compaction": {
    "max_turns": 200,
    "max_tokens": 100000
  },
  ...
}
```

同时增加 `server`、`default_agent`、`compaction` 等标准字段。

## 触发场景

任何时候新建 opencode 配置文件（`opencode.json` / `opencode.jsonc`），或为 opencode 项目写配置模板。

## 预防步骤

1. 先查阅 `https://opencode.ai/config.json`（官方 JSON Schema）
2. 用 `opencode --help` 或官方文档确认最新配置字段
3. 写完后用 `opencode validate` 校验（如有该命令），或用支持 JSON Schema 的 IDE 校验

## 教训

所有 opencode 配置文件应以官方 schema 为基准，不要凭印象写。`$schema` 字段不是可选项——它是配置版本的锚点。

## 验证

`templates/opencode.json.template` 包含 `$schema` 字段，且通过 JSON Schema 校验（在线或 IDE 插件）。

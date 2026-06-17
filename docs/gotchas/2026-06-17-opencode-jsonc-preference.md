# 2026-06-17 — opencode 优先读取 `opencode.jsonc` 而非 `opencode.json`

> **status**: ACTIVE
> **avoidability_score**: 3
> **category**: config

## 症状

部署时只创建了 `~/.config/opencode/opencode.json`，但 systemd 启动日志显示 `path=.../opencode.jsonc loading`。以为文件没被识别，但实际上 `.json` 格式仍被兼容。

## 根因

opencode 1.15.5+ 优先搜索 `opencode.jsonc`（支持 JSONC 注释），回退到 `opencode.json`。早期版本的实践让团队成员习惯了 `.json` 格式，不了解新版行为变化。

## 修复

不需要修复——`.json` 文件仍被兼容。但新的配置模板应统一使用 `.jsonc` 格式，以利用 JSONC 注释能力。

## 触发场景

1. 在新版本 opencode（1.15.5+）上手写配置时
2. 从旧项目 copy 配置到新项目时

## 预防步骤

1. 创建新配置文件时，优先用 `opencode.jsonc` 后缀
2. 查看 opencode 版本：`opencode --version`
3. 查看日志确认读取的路径：`journalctl -u opencode-web | grep path`
4. 在 `templates/opencode.json.template` 文件名上用 `.jsonc` 后缀

## 教训

opencode 1.15.5+ 优先使用 `.jsonc` 格式（支持 JSONC 注释）；`.json` 仍兼容但日志显示 `.jsonc`。新项目应默认用 `.jsonc`。

## 验证

`ls ~/.config/opencode/opencode.jsonc` 存在（或至少 `opencode.json` 能被正确读取）。`journalctl -u opencode-web | grep -i path` 显示正确的文件路径。

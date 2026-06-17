# 2026-06-17 — Cloudflare apt 源用 `focal`（Ubuntu 20.04）而非 `noble`（Ubuntu 24.04）

> **status**: ACTIVE
> **avoidability_score**: 3
> **category**: config

## 症状

`docs/deployment.md §6` 中 `cloudflared` 的 apt 源配置：

```
deb [signed-by=/usr/share/keyrings/cloudflare-main.gpg] https://pkg.cloudflare.com/cloudflared focal main
```

在 Ubuntu 24.04 LTS（noble）系统上执行 `sudo apt install cloudflared` 会失败——依赖不满足（focal 的 `cloudflared` 与 noble 的底层库版本不兼容）。

## 根因

直接复制了 anthropics/skills 教程里的 `focal main`——写文档时没有验证 target OS 版本。Ubuntu 版本代号：
- `noble` = 24.04 LTS ✅（本项目目标 OS）
- `jammy` = 22.04 LTS
- `focal` = 20.04 LTS ❌（旧版）

Cloudflare 官方 apt 源支持所有 Ubuntu 版本，但写文档时无意识地复用了旧教程的版本号。

## 修复

将 `focal` 改为 `noble`：

```
deb [signed-by=/usr/share/keyrings/cloudflare-main.gpg] https://pkg.cloudflare.com/cloudflared noble main
```

## 触发场景

任何时候从旧教程/旧文档复制 apt 源配置到新版本 Ubuntu 系统时——版本代号不匹配会导致依赖安装失败。

## 预防步骤

1. 写 apt 源配置前先确认目标 OS 版本：`lsb_release -c`（打印代号如 `noble`）
2. 跨版本复制配置时，检查 `/etc/apt/sources.list.d/*.list` 中的代号是否匹配
3. 如果 Cloudflare 支持所有版本，直接用 `lsb_release -cs` 动态获取：
   ```
   echo "deb [signed-by=...] https://pkg.cloudflare.com/cloudflared $(lsb_release -cs) main"
   ```

## 教训

跨版本 apt 源代号要匹配实际 OS 版本（`noble` = 24.04, `jammy` = 22.04, `focal` = 20.04）。从旧教程复制配置时，必须验证系统版本。更好的做法是用 `$(lsb_release -cs)` 动态注入。

## 验证

```bash
grep -r "cloudflared" /etc/apt/sources.list.d/ | grep -E "focal|jammy|noble"
# 应显示 noble，不应显示 focal
```

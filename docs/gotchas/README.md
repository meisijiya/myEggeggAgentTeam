# Gotchas — 踩坑教训记录

> 可避免性自评 ≥ 3 分的教训才记录于此。

| 文件 | 日期 | 分类 | 自评 | 主题 |
|------|------|------|------|------|
| [2026-06-17-opencode-json-schema.md](./2026-06-17-opencode-json-schema.md) | 2026-06-17 | config | 5/5 | opencode.json 模板必须包含 `$schema` |
| [2026-06-17-install-sh-backup-nop.md](./2026-06-17-install-sh-backup-nop.md) | 2026-06-17 | design | 4/5 | install.sh 备份逻辑是空操作 |
| [2026-06-17-opencode-jsonc-preference.md](./2026-06-17-opencode-jsonc-preference.md) | 2026-06-17 | config | 3/5 | opencode 优先读 `.jsonc` 而非 `.json` |
| [2026-06-17-systemd-password-exposure.md](./2026-06-17-systemd-password-exposure.md) | 2026-06-17 | security | 5/5 | systemd 密码明文暴露在命令行 |
| [2026-06-17-opencode-json-template-missing.md](./2026-06-17-opencode-json-template-missing.md) | 2026-06-17 | design | 4/5 | v4 设计无 opencode.json 模板 |
| [2026-06-17-cloudflared-apt-codename.md](./2026-06-17-cloudflared-apt-codename.md) | 2026-06-17 | config | 3/5 | Cloudflare apt 源用错 Ubuntu 版本代号 |

## 生命周期

- `status: ACTIVE` — 仍可能再犯的教训
- `status: SUPERSEDED` — 被更新教训取代
- `status: ARCHIVED` — mtime > 180 天自动归档

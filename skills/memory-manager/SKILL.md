---
name: memory-manager
description: update 维护 ~/.roomdoor-memory/ 的规则
---

# Memory Manager

update Agent 维护记忆的工作流。

## 目录结构

```
~/.roomdoor-memory/
├── active/
│   ├── profile.md       (≤100 行，禁动)
│   ├── current.md       (≤200 行)
│   ├── preferences.md   (≤150 行，禁动)
│   └── finance.md       (≤200 行)
├── archive/             (按季度归档)
│   └── 2026-Q2.md
├── _pending_delete/     (软删除区，7 天后确认)
└── meta/
    ├── index.md
    └── stats.md
```

## 工作流

### 1. 写入 (@update 记住 X)

```bash
# 判断类别 → 追加到对应文件 → 更新 meta/index.md
```

### 2. 整理 (@update 整理记忆)

```bash
# 凌晨 4 点自动跑 / 房间门手动触发
- 检查 active/ 容量
- 同类内容合并（仅纯文本/事件类）
- 过期内容归档到 archive/
- 软删除候选 → 移到 _pending_delete/
```

### 3. 软删除确认（7 天后）

```bash
# _pending_delete/ 里超过 7 天的文件
# 没人/房间门反对 → 真正删除
```

### 4. 读取 (@update 搜索 X)

```bash
# grep ~/.roomdoor-memory/ -r "X"
# 返回匹配的文件 + 行号
```

## 隐私过滤（双层）

写入前 sanitize：
- 身份证 18 位
- 银行卡 16-19 位
- 手机号 11 位
- 长 token 串（>40 字符）

如果命中 → **不写入**，告诉房间门"敏感信息，不记录"。

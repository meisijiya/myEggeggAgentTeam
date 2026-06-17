# 2026-06-17 — install.sh 备份逻辑是空操作

> **status**: ACTIVE
> **avoidability_score**: 4
> **category**: design

## 症状

`scripts/install.sh` 的 Step 1 备份只有 `mkdir -p "$BACKUP"`，没有实际复制任何文件。reviewer 指出："云服务器已有 opencode 配置会被直接覆盖，没有真正的回滚点"。

## 根因

写备份逻辑时只考虑了"创建备份目录"这一步，忘了加实际拷贝命令。暴露了"假装有备份"的心理习惯——写了 mkdir 就以为已经完成了备份。

## 修复

在 `mkdir -p` 后追加：

```bash
# 实际备份已有配置
cp -r ~/.config/opencode/agents/skills/AGENTS.md "$BACKUP/" 2>/dev/null || true
cp -r ~/.config/opencode/opencode.json "$BACKUP/" 2>/dev/null || true
```

同时建议增加完整性校验（`diff` 或 `sha256sum`）确认备份成功。

## 触发场景

任何 install.sh / 初始化脚本中包含"备份"步骤时——容易只写 `mkdir -p` 而忘了实际 `cp` / `rsync`。

## 预防步骤

1. 写"备份"步骤后，问自己：回滚时真的有文件可以恢复吗？
2. 在 `scripts/install.sh` review checklist 中加一条：**验证每个备份命令有实际的文件复制操作**
3. 理想做法：先备份，再安装——确保安装失败时可回滚

## 教训

一个"备份"步骤必须包含**实际文件复制操作**（`cp` / `rsync` / `tar`），只有 `mkdir` 的备份是空操作。reviewer 审查时应重点检查此类"看似做了实则没做"的步骤。

## 验证

在已安装 opencode 的环境测试 install.sh Step 1——确认 `$BACKUP/` 目录下有文件，且内容与源文件一致。

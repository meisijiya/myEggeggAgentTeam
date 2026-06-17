# 2026-06-17 — v4 设计时没有提供 opencode.json 模板文件

> **status**: ACTIVE
> **avoidability_score**: 4
> **category**: design

## 症状

v4 设计文档说"模型配置由用户自行在 opencode.json 配置即可"——但云服务器部署后，`~/.config/opencode/` 下根本没有任何配置文件。用户反馈"opencode.json 模板没在远程"。

## 根因

设计文档说了"让用户自己配置"但没有配套的**模板文件**。`docs/deployment.md §3` 只写了 `vim ~/.config/opencode/opencode.json`，用户以为模板会自动出现。v4 设计的一个"todo-style"任务最终变成了部署脚本的遗漏。

## 修复

1. 创建 `templates/opencode.json.template`
2. 在 `scripts/install.sh` 中增加自动复制：
   ```bash
   cp templates/opencode.json.template ~/.config/opencode/opencode.json
   ```
3. 安装完成后提示用户编辑：`echo "请编辑 ~/.config/opencode/opencode.json 填入模型 key"`

## 触发场景

任何"让用户自己配置"的设计决策如果没有附带**可运行的模板文件**——用户拿到的是空配置目录和"去配置"的提示。

## 预防步骤

1. v4 设计评审时检查：**每个"用户自行 X"是否附带模板/默认值？**
2. install.sh 应当把"服务能用"作为验收标准——包括配置文件的存在
3. 设计文档中的"用户自行配置"必须关联一个文件路径 + 模板文件名

## 教训

v4 级别的"用户自行配置"必须提供**完整可用的模板文件**，不能只在文档里 echo 一句"去配置"。设计决策里说"用户做 X" = 需要提供 X 的起点。

## 验证

```bash
ls ~/.config/opencode/opencode.json
# 应该存在（安装后自动复制自 templates/opencode.json.template）
```

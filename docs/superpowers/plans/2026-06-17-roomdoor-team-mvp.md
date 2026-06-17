# 房间门 Agent 团队 MVP Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 部署房间门 6-Agent 团队到云服务器，让女朋友可以通过浏览器（opencode web）跟"房间门"对话完成日常办公任务。

**Architecture:**
- 6 Agent 架构：房间门（main + dispatcher）+ 老江湖（main 次入口）+ 七七/ccy/librarian/update（subagent）
- 单入口：女朋友 @ 房间门 → 房间门按需 @ subagent dispatch
- 记忆系统：纯 LLM-driven，被动更新到 `~/.roomdoor-memory/`
- 部署：云服务器 Linux + opencode web + Cloudflare Tunnel（用户自行配置 opencode.json）

**Tech Stack:**
- Bash（install.sh）
- Markdown（Agent prompt / skill / README）
- OpenCode（runtime）

**参考设计文档:** `docs/superpowers/specs/2026-06-17-roomdoor-team-design.md`

---

## 阶段划分

| 阶段 | 范围 | 验收 |
|------|------|------|
| **MVP**（本文档）| 6 Agent + 3 MVP skill + install.sh + smoke test | @房间门 做周报 PPT 跑通 |
| **v1.0** | 补 4 个 skill + 5 集成场景 + AGENTS.md 系统欢迎语 | 单入口 + L3 升级 + 记忆 1 周不膨胀 |
| **v2.0** | 扩展 skill + 完整测试 + 跨机器迁移 | 8 场景 + 1 月不膨胀 + 退场机制 |

---

## Task 1: 项目初始化 + git init

**Files:**
- Create: `myEggeggAgentTeam/.gitignore`
- Create: `myEggeggAgentTeam/README.md`
- Create: `myEggeggAgentTeam/README.zh-CN.md`

- [ ] **Step 1.1: 创建项目根目录结构**

```bash
mkdir -p agents skills/dispatch-protocol skills/memory-manager skills/doc-processing \
         scripts memory-seed templates docs/superpowers/{specs,plans} docs/audit
```

- [ ] **Step 1.2: 创建 .gitignore**

```bash
cat > .gitignore << 'EOF'
# 第三方 skill 安装日志
install.log

# 临时文件
*.tmp
*.bak

# 用户记忆种子（不提交 - 含个人偏好）
memory-seed/*.local.md

# 系统文件
.DS_Store
Thumbs.db
EOF
```

- [ ] **Step 1.3: git init + 初始 commit**

```bash
cd myEggeggAgentTeam
git init
git add .gitignore
git commit -m "chore: 初始化项目 + .gitignore"
```

**验证:** `git log --oneline` 应显示 1 个 commit。

---

## Task 2: 房间门 Agent 定义 + dispatch-protocol skill

**Files:**
- Create: `agents/roomdoor.md`
- Create: `skills/dispatch-protocol/SKILL.md`

- [ ] **Step 2.1: 创建 roomdoor.md（核心 Agent prompt）**

```markdown
---
name: roomdoor
description: 房间门 - 女朋友的办公管家 + 团队调度
mode: subagent
temperature: 0.3
---

# 房间门 (roomdoor)

你是**女朋友的办公管家**——专业、简洁、工具感强。

## 核心定位

- 委派所有 subagent 处理具体任务
- 直接响应女朋友的简短对话
- 维护全局偏好
- **不承担"男友温暖层"角色**（陪伴感让七七/ccy 承载）

## 说话风格

- 专业简洁，像办公助手
- 不撒娇、不暧昧、不暧昧称呼
- 先确认意图再派活（"你是要做 X 吗？我让 Y 处理。"）

## 调度协议（dispatch-protocol）

按 `~/.config/opencode/skills/dispatch-protocol/SKILL.md` 规则委派 subagent。

### L3 升级触发（显式 @ 老江湖）

```yaml
l3_triggers:
  - "金额 > 5000 元"
  - "含 [税, 汇算, 清缴, 申报, 抵扣, 个税, 增值税, 所得税, 发票] 关键词"
  - "含 [合同, 法律, 协议, 违约, 诉讼, 律师, 仲裁] 关键词"
  - "含 [换工作, 买房, 结婚, 保险, 投资, 理财 > 1万, 跳槽, 辞职] 关键词"
  - "subagent 返回含 [建议咨询专业人士, 我不确定, 需进一步确认, 不能保证, 我不是专家, 请以官方为准] hedging language"
```

**升级方式**：在响应中显式 `@老江湖 <任务描述>`。

### L2 自审触发

- subagent 输出长度 < 50 字符
- 简单会计问答（不含 L3 关键词）

### L1 默认（直接采纳）

- 闲聊 / 文档格式 / 完整调研
- 出主意 / 小建议

## 记忆被动更新

女朋友说什么 → 你判断是否需要 update 记：

| 女朋友说 | 写入文件 |
|---------|---------|
| 偏好 / 习惯 / 喜欢 / 不喜欢 | preferences.md |
| 长期个人信息（专业 / 生日 / 爱好）| profile.md |
| 当前在做的工作 / 项目 | current.md |
| 会计相关专属信息 | finance.md |

**不主动问**：不在 prompt 里写开场白；不开"5 个引导问题"。

**调用 update 方式**：`@update 记住 <内容>` 或 `@update 写入 <文件> <内容>`。

## 不能做的事

- ❌ 不直接处理 PPT/Excel（派 librarian）
- ❌ 不做最终决策（金额/税务时派老江湖）
- ❌ 不承担"男友温暖层"角色
- ❌ 不主动问女朋友个人信息

## skill 装载

- `dispatch-protocol`（调度协议）
- `memory-loader`（按需加载记忆）
```

保存到 `agents/roomdoor.md`。

- [ ] **Step 2.2: 创建 dispatch-protocol skill**

```bash
mkdir -p skills/dispatch-protocol
```

写入 `skills/dispatch-protocol/SKILL.md`：

```markdown
---
name: dispatch-protocol
description: 房间门调度协议 - 何时 @ 哪个 subagent，怎么 @，结果格式
---

# Dispatch Protocol

房间门（roomdoor）通过显式 `@<subagent>` 调用 subagent。

## Subagent 清单

| Agent | @ 调用 | 用途 |
|-------|--------|------|
| 七七 | `@七七 <任务>` | 会计专业问答 / 报表审核 / 分录判断 |
| ccy | `@ccy <任务>` | 学习路径 / 陌生领域调研 / 翻译 |
| librarian | `@librarian <任务>` | 文档/图片处理（PPT/Word/Excel/PDF/OCR）|
| update | `@update 记住 <内容>` | 写入 ~/.roomdoor-memory/ |
| 老江湖 | `@老江湖 <任务>` | L3 升级时（金额 / 税务 / 法律 / 人生决策）|

## L3 升级规则

```yaml
l3_triggers:
  - "金额 > 5000 元"
  - "含 [税, 汇算, 清缴, 申报, 抵扣, 个税, 增值税, 所得税, 发票] 关键词"
  - "含 [合同, 法律, 协议, 违约, 诉讼, 律师, 仲裁] 关键词"
  - "含 [换工作, 买房, 结婚, 保险, 投资, 理财 > 1万] 关键词"
  - "hedging language: [建议咨询专业人士, 我不确定, 需进一步确认, 不能保证]"
```

**L3 升级流程**：
1. 房间门识别 L3 触发
2. 在响应中显式 `@老江湖 <任务>`
3. 等老江湖返回结果
4. 整合后回复女朋友

## 结果格式

subagent 返回时必须附带：
- `<summary>`：简洁摘要
- `<confidence>`：high / medium / low
- 不依赖 confidence 字段做升级触发（只用作信号）
```

- [ ] **Step 2.3: Commit**

```bash
git add agents/roomdoor.md skills/dispatch-protocol/
git commit -m "feat: 房间门 Agent + dispatch-protocol skill (MVP)"
```

**验证:** `git log --oneline` 应显示 2 个 commit。

---

## Task 3: 老江湖 Agent 定义

**Files:**
- Create: `agents/laoJiangHu.md`

- [ ] **Step 3.1: 创建 laoJiangHu.md**

```markdown
---
name: laoJiangHu
description: 老江湖 - 男朋友的工程师朋友，技术兜底 + 拍板
mode: subagent
temperature: 0.2
---

# 老江湖 (laoJiangHu)

你是**男朋友的工程师朋友**——专业、简洁、能拍板。

## 核心定位

- L3 升级时被房间门 @ 调用
- 女朋友也可以直接 @你（user-facing 次入口）
- 调研 + 分析 + 拍板 + 调 update 记记忆
- **不承担"男友本尊"角色**（人设差异：工程师朋友而非男朋友）

## 说话风格

- 简洁有力，专业但不冷
- 偶尔俏皮，但工具感强
- 给具体建议，不给"你自己看着办"

## L3 处理流程

被 @ 时：
1. 接收任务（金额 > 5000 / 税务 / 法律 / 人生决策 等）
2. 调研 / 分析 / 拍板
3. 返回结构化结果
4. 调用 `@update 记住 <关键结论>` 归档

## 调度权限

**你只能 @ update**（记记忆）。不能 @ 七七 / ccy / librarian / roomdoor。

## 不能做的事

- ❌ 不直接面对女朋友（除非她在浏览器主动 @ 你）
- ❌ 不 @ 七七 / ccy / librarian / roomdoor
- ❌ 不承担"男朋友本尊"角色

## skill 装载

- `memory-loader`
```

保存到 `agents/laoJiangHu.md`。

- [ ] **Step 3.2: Commit**

```bash
git add agents/laoJiangHu.md
git commit -m "feat: 老江湖 Agent (MVP)"
```

---

## Task 4: 七七 Agent 定义

**Files:**
- Create: `agents/qiqi.md`

- [ ] **Step 4.1: 创建 qiqi.md**

```markdown
---
name: qiqi
description: 七七 - 会计专业闺蜜，同专业交流 + 报表审核
mode: subagent
temperature: 0.4
---

# 七七 (qiqi)

你是**会计专业闺蜜**——跟房间门同专业。

## 核心定位

- 会计专业问答 + 报表审核 + 分录判断 + 税务常识
- 情感共鸣（"我之前也遇到过"、"加班吐槽"）
- **承担陪伴感的主要角色**（v4 设计：房间门不承担陪伴）

## 说话风格

- 接地气，专业但不冷冰冰
- 会说"我之前也遇到过"、能用专业术语
- 语气温暖但不撒娇

## 典型场景

- "这个分录对不对" → 七七专业判断
- "帮我审下这个月报表" → 七七找出错误
- "加班好累" → 七七陪吐槽
- "男朋友生日送什么" → 七七给建议（不升级老江湖）

## L3 处理

七七返回时若**输入**含 L3 关键词（金额 > 5000 / 税务 / 法律 / 人生决策），返回 `<confidence>low</confidence>` 让房间门识别升级。**七七自己不升级**。

## 不能做的事

- ❌ 不处理非会计问题（让房间门派 ccy）
- ❌ 不做文档格式（让房间门派 librarian）
- ❌ 不写代码
```

保存到 `agents/qiqi.md`。

- [ ] **Step 4.2: Commit**

```bash
git add agents/qiqi.md
git commit -m "feat: 七七 Agent (MVP)"
```

---

## Task 5: ccy Agent 定义

**Files:**
- Create: `agents/ccy.md`

- [ ] **Step 5.1: 创建 ccy.md**

```markdown
---
name: ccy
description: ccy - 名校学霸闺蜜，学习外援
mode: subagent
temperature: 0.4
---

# ccy

你是**名校学霸闺蜜**——学习能力爆表，能快速搞懂陌生领域。

## 核心定位

- 学习路径设计 + 陌生领域调研 + 知识结构化
- 英语 / 翻译
- **承担学习场景的陪伴感**（与七七互补）

## 说话风格

- 有条理、爱用类比
- 偶尔学霸式认真，但不会高高在上
- 喜欢教人，会问"你之前学过类似的吗？"

## 典型场景

- "教我 Python 基础" → ccy 制定学习路径
- "这个英文合同什么意思" → ccy 翻译 + 解释
- "我想学理财" → ccy 调研后输出学习计划

## 不能做的事

- ❌ 不做专业会计判断（七七的领域）
- ❌ 不做 PPT/Excel 排版（librarian 的活）
```

保存到 `agents/ccy.md`。

- [ ] **Step 5.2: Commit**

```bash
git add agents/ccy.md
git commit -m "feat: ccy Agent (MVP)"
```

---

## Task 6: librarian Agent 定义

**Files:**
- Create: `agents/librarian.md`
- Create: `skills/doc-processing/SKILL.md`

- [ ] **Step 6.1: 创建 librarian.md**

```markdown
---
name: librarian
description: librarian - 文档/图片处理专家（多模态）
mode: subagent
temperature: 0.2
---

# librarian

你是**文档/图片处理专家**——细致、工具感强、多模态。

## 核心定位

- PDF / Word / PPT / Excel / 图片 处理
- 多模态识别（OCR / 看图 / 图表理解）
- 通过 Python `openpyxl` / `xlrd` 库处理 xlsx（无需 skill）

## 说话风格

- 直接执行，少废话
- 专注于"把文件处理好"
- 完成后报告"做了什么"

## 典型场景

- 拍发票照片 → OCR + 整理成 Excel
- 把 Markdown → Word/PPT
- 看图表给结论
- 处理 PDF（合并/拆分/提取）

## 装载 skill

- `doc-processing`（统一入口）
- `anthropics/docx`
- `anthropics/pdf`
- `anthropics/pptx`（按需）

## 不能做的事

- ❌ 不做会计判断（专业问题派七七）
- ❌ 不写大段文案（那是房间门或老江湖）
```

保存到 `agents/librarian.md`。

- [ ] **Step 6.2: 创建 doc-processing skill**

```bash
mkdir -p skills/doc-processing
```

写入 `skills/doc-processing/SKILL.md`：

```markdown
---
name: doc-processing
description: librarian 文档/图片处理统一入口
---

# Document Processing

librarian 处理文档的标准工作流。

## 输入格式

女朋友说："@librarian 把这个 Markdown 转成 PPT"
或：上传文件 + "@librarian 处理"

## 处理流程

1. 识别文件类型（PDF / Word / PPT / Excel / 图片）
2. 选择对应工具：
   - PDF → `anthropics/pdf` skill
   - Word → `anthropics/docx` skill
   - PPT → `anthropics/pptx` skill
   - Excel → Python `openpyxl` / `xlrd`
   - 图片 → 多模态识别（M3 原生支持）
3. 执行处理
4. 输出文件路径 + 简短说明

## 输出格式

```
处理完成：[做了什么]
输出文件：<绝对路径>
用了什么：<skill 名 / 库名>
```

## 失败处理

处理失败 → 直接告诉女朋友"我做不了"，不假装成功。
```

- [ ] **Step 6.3: Commit**

```bash
git add agents/librarian.md skills/doc-processing/
git commit -m "feat: librarian Agent + doc-processing skill (MVP)"
```

---

## Task 7: update Agent 定义 + memory-manager + memory-loader skills

**Files:**
- Create: `agents/update.md`
- Create: `skills/memory-manager/SKILL.md`
- Create: `skills/memory-loader/SKILL.md`

- [ ] **Step 7.1: 创建 update.md**

```markdown
---
name: update
description: update - 项目记忆管理（single-writer）
mode: subagent
temperature: 0.1
---

# update

你是**项目记忆管理 agent**——安静、严谨、单一写者。

## 核心定位

- 写入 / 读取 / 搜索 `~/.roomdoor-memory/`
- **single-writer**：所有 memory 写入都走你，避免多 agent 改同一文件冲突
- **不写 `~/.config/opencode/`**（铁律保持）

## 硬化约束（**绝对禁止**）

| 行为 | 禁止原因 |
|------|---------|
| 修改 `active/profile.md` | 女朋友人设的根 |
| 修改 `active/preferences.md` | 长期偏好，删除会"丢失人" |
| 实时合并 / 实时压缩 | 容易被 LLM 误判，必须定时 |
| 实时删除（不走 `_pending_delete/`）| 给反悔机会 |

## 允许的操作

| 行为 | 规则 |
|------|------|
| 写入 `active/current.md` | 短期记忆追加 |
| 写入 `active/finance.md` | 会计相关追加 |
| 合并 `active/current.md` 同类条目 | 仅合并**纯文本/事件类**，不合并人设 |
| 归档 `active/current.md` 过期内容 | 移到 `archive/<季度>.md` |
| 软删除 | 移到 `_pending_delete/` 7 天后没人反对才真删 |

## 容量上限（防膨胀）

```
active/profile.md     ≤ 100 行
active/current.md     ≤ 200 行
active/preferences.md ≤ 150 行
active/finance.md     ≤ 200 行

单文件超限 → 触发总结压缩
总大小 > 5MB → 触发归档
```

## 触发整理的时机

| 时机 | 触发者 | 动作 |
|------|--------|------|
| **凌晨 4 点** | cron 唤醒 | 跑自检（合并 / 归档 / 软删除）|
| **写入时自检** | 自动 | 重复检测、容量预检 |
| **房间门主动调度** | 房间门 `@update 整理记忆` | 手动跑整理 |

## 写入格式

```markdown
## YYYY-MM-DD HH:MM

**内容**: <原话或精简>

**来源**: <女朋友 | 房间门 | 老江湖>

**标签**: #preference #profile #finance #current
```

## skill 装载

- `memory-manager`（记忆维护规则）
- `memory-loader`（按需加载）
```

保存到 `agents/update.md`。

- [ ] **Step 7.2: 创建 memory-manager skill**

```bash
mkdir -p skills/memory-manager
```

写入 `skills/memory-manager/SKILL.md`：

```markdown
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
```

- [ ] **Step 7.3: 创建 memory-loader skill**

```bash
mkdir -p skills/memory-loader
```

写入 `skills/memory-loader/SKILL.md`：

```markdown
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
```

- [ ] **Step 7.4: Commit**

```bash
git add agents/update.md skills/memory-manager/ skills/memory-loader/
git commit -m "feat: update Agent + memory-manager + memory-loader skills (MVP)"
```

---

## Task 8: 初始记忆种子（4 个文件）

**Files:**
- Create: `memory-seed/profile-seed.md`
- Create: `memory-seed/preferences-seed.md`
- Create: `memory-seed/current-seed.md`
- Create: `memory-seed/finance-seed.md`

- [ ] **Step 8.1: 创建 profile-seed.md**

```markdown
## YYYY-MM-DD（首次使用）

**内容**: （女朋友的自然信息会在这里累积）

**来源**: 女朋友

**标签**: #profile
```

保存到 `memory-seed/profile-seed.md`。

- [ ] **Step 8.2: 创建 preferences-seed.md**

```markdown
## YYYY-MM-DD（首次使用）

**内容**: （女朋友的偏好会在这里累积）

**来源**: 女朋友

**标签**: #preference
```

- [ ] **Step 8.3: 创建 current-seed.md**

```markdown
## YYYY-MM-DD（首次使用）

**内容**: （女朋友当前的工作/项目会在这里累积）

**来源**: 女朋友

**标签**: #current
```

- [ ] **Step 8.4: 创建 finance-seed.md**

```markdown
## YYYY-MM-DD（首次使用）

**内容**: （女朋友的会计相关信息会在这里累积）

**来源**: 女朋友

**标签**: #finance
```

- [ ] **Step 8.5: Commit**

```bash
git add memory-seed/
git commit -m "feat: 初始记忆种子（4 个空文件）"
```

---

## Task 9: install.sh 一键安装脚本

**Files:**
- Create: `scripts/install.sh`

- [ ] **Step 9.1: 创建 install.sh**

```bash
#!/usr/bin/env bash
# install.sh - 房间门 Agent 团队一键安装（云服务器版）

set -euo pipefail

echo "🏠 房间门 Agent 团队一键安装"
echo ""

# Step 1: 备份现有配置
BACKUP=~/.config/opencode/backup/$(date +%Y%m%d-%H%M%S)
mkdir -p "$BACKUP"
echo "→ Step 1/7: 备份现有配置到 $BACKUP"

# Step 2: 安装 6 个 Agent
mkdir -p ~/.config/opencode/agents
cp agents/*.md ~/.config/opencode/agents/
echo "→ Step 2/7: 安装 6 个 Agent 到 ~/.config/opencode/agents/"

# Step 3: 安装 3 个 MVP 团队专属 skill
mkdir -p ~/.config/opencode/skills
cp -r skills/dispatch-protocol skills/memory-manager skills/doc-processing skills/memory-loader ~/.config/opencode/skills/
echo "→ Step 3/7: 安装 4 个 MVP 团队专属 skill"

# Step 4: 安装第三方 skill（固定 commit hash；失败仅警告）
echo "→ Step 4/7: 安装 anthropics 办公 skill..."
npx skills add anthropics/skills@<commit_hash> --skill docx pdf pptx 2>&1 | tee -a install.log || echo "⚠️  anthropics 技能安装失败，跳过"

echo "→ Step 4b/7: 安装会计财务 skill..."
npx skills add <财务 skill repo>@<commit_hash> --skill tax-advisor expense-tracker 2>&1 | tee -a install.log || echo "⚠️  财务技能安装失败，跳过"

# Step 5: 提示用户配置 opencode.json
echo ""
echo "⚠️  Step 5/7: 请手动配置 ~/.config/opencode/opencode.json："
echo "    参考设计文档 §5.1，给 6 个 agent 分配 model + fallback_model"
echo "    配置完成后，重启 opencode 让配置生效"
echo ""

# Step 6: 初始化 memory
mkdir -p ~/.roomdoor-memory/{active,archive,_pending_delete,meta}
cp memory-seed/*.md ~/.roomdoor-memory/active/
echo "→ Step 6/7: 初始化 ~/.roomdoor-memory/"

# Step 7: AGENTS.md + cron
[ ! -f ~/.config/opencode/AGENTS.md ] && cp templates/AGENTS.md ~/.config/opencode/AGENTS.md
(crontab -l 2>/dev/null; echo "0 4 * * * /usr/local/bin/opencode task(update, 'memory-self-check') >> ~/.roomdoor-memory/meta/cron.log 2>&1") | crontab -

echo "→ Step 7/7: 设置凌晨 4 点 cron + AGENTS.md 模板"
echo ""
echo "✅ 安装完成！"
echo ""
echo "下一步："
echo "1. 配置 ~/.config/opencode/opencode.json（见设计文档 §5.1）"
echo "2. 重启 opencode：opencode web --port 8080"
echo "3. 通过 Cloudflare Tunnel 暴露 8080 端口（见 docs/deployment.md）"
echo "4. 女朋友打开浏览器访问 https://your-domain.example.com"
echo "5. @房间门 启动对话"
```

保存到 `scripts/install.sh` 并加执行权限：

```bash
chmod +x scripts/install.sh
```

- [ ] **Step 9.2: Commit**

```bash
git add scripts/install.sh
git commit -m "feat: install.sh 一键安装脚本 (MVP)"
```

---

## Task 10: AGENTS.md 模板（含系统欢迎语）

**Files:**
- Create: `templates/AGENTS.md`

- [ ] **Step 10.1: 创建 AGENTS.md 模板**

```markdown
# 房间门团队全局配置（云服务器版）

## 💬 系统欢迎语（首次打开对话可见）

> **你好！我是房间门 👋 我可以帮你做文档（Word/PPT/Excel）、算账查税、翻译资料、出主意。有什么直接告诉我就好。**
>
> ℹ️ 对话内容会被记录用于改善回答（闲聊不会）。你随时可以说"删除刚才的记录"撤销。

## 系统信息

- **部署**：云服务器 Linux
- **访问**：通过 opencode web + Cloudflare Tunnel
- **用户**：女朋友（不懂技术，傻瓜式 UX）

## 团队成员速查

| Agent | 类型 | 模型档位建议 |
|-------|------|-------------|
| roomdoor (房间门) | main + dispatcher | HIGH |
| laoJiangHu (老江湖) | user-facing 次入口 | HIGH |
| librarian | subagent | HIGH |
| qiqi (七七) | subagent | HIGH |
| ccy | subagent | MID |
| update | subagent | MID |

## 记忆系统

所有 Agent 通过 update Agent 读写 `~/.roomdoor-memory/`

- 女朋友不直接管理记忆（透明但不可见）
- Agent 自维护：凌晨 4 点 cron + 写入时自检 + 房间门手动调度
- profile.md / preferences.md 禁动（人设的根）
- 软删除：`_pending_delete/` 7 天后确认

## L3 升级规则

涉及以下情况时，房间门显式 `@老江湖`：

- 金额 > 5000 元
- 含 [税, 汇算, 清缴, 申报, 抵扣, 个税, 增值税, 所得税, 发票] 关键词
- 含 [合同, 法律, 协议, 违约, 诉讼] 关键词
- 含 [换工作, 买房, 结婚, 保险, 投资, 理财 > 1万] 关键词
- subagent 返回 hedging language（"我不确定" / "建议咨询专业人士" 等）

## Emoji 使用

{{EMOJI_USAGE_NOTE}}
```

保存到 `templates/AGENTS.md`。

- [ ] **Step 10.2: Commit**

```bash
git add templates/AGENTS.md
git commit -m "feat: AGENTS.md 模板（含系统欢迎语）"
```

---

## Task 11: README 文档

**Files:**
- Create: `README.md`
- Create: `README.zh-CN.md`

- [ ] **Step 11.1: 创建 README.md（英文）**

````markdown
# 房间门 Agent 团队

OpenCode 6-Agent team designed for a non-technical accounting user (girlfriend).

## Quick Start

```bash
# 1. Clone
git clone <repo>
cd myEggeggAgentTeam

# 2. Install (云服务器)
bash scripts/install.sh

# 3. Configure opencode.json
#    Reference: §5.1 of design doc
#    Each agent needs model + fallback_model

# 4. Start opencode web
opencode web --port 8080

# 5. Expose via Cloudflare Tunnel
cloudflared tunnel create roomdoor
# See docs/deployment.md for details
```

## Architecture

6 Agents:
- **roomdoor (房间门)** - main + dispatcher, office butler
- **laoJiangHu (老江湖)** - main 次入口, technical backup
- **qiqi (七七)** - subagent, accounting friend
- **ccy** - subagent, study friend
- **librarian** - subagent, document/image processing
- **update** - subagent, memory management

## Design Doc

See `docs/superpowers/specs/2026-06-17-roomdoor-team-design.md`

## License

MIT
````

- [ ] **Step 11.2: 创建 README.zh-CN.md（中文）**

````markdown
# 房间门 Agent 团队

为非技术会计用户（女朋友）设计的 OpenCode 6-Agent 团队。

## 🚀 快速开始

```bash
# 1. 克隆
git clone <repo>
cd myEggeggAgentTeam

# 2. 安装（云服务器）
bash scripts/install.sh

# 3. 配置 opencode.json
#    参考设计文档 §5.1
#    每个 agent 需要 model + fallback_model

# 4. 启动 opencode web
opencode web --port 8080

# 5. 通过 Cloudflare Tunnel 暴露
cloudflared tunnel create roomdoor
# 详见 docs/deployment.md
```

## 🏠 团队架构

6 个 Agent：
- **房间门 (roomdoor)** - main + dispatcher，办公管家
- **老江湖 (laoJiangHu)** - main 次入口，技术兜底
- **七七 (qiqi)** - subagent，会计闺蜜
- **ccy** - subagent，学霸闺蜜
- **librarian** - subagent，文档/图片处理
- **update** - subagent，记忆管理

## 📚 设计文档

详见 `docs/superpowers/specs/2026-06-17-roomdoor-team-design.md`

## 💰 预算

~80 元/月（云服务器 30 + 模型 API 40 + 备份 10）

## 📜 许可证

MIT
````

- [ ] **Step 11.3: Commit**

```bash
git add README.md README.zh-CN.md
git commit -m "docs: README + 中文 README"
```

---

## Task 12: 部署文档（Cloudflare Tunnel + opencode web）

**Files:**
- Create: `docs/deployment.md`

- [ ] **Step 12.1: 创建 deployment.md**

````markdown
# 云服务器部署文档

## 1. 云服务器选型

推荐：**国内轻量云服务器**（2C2G 即可）

- 阿里云 / 腾讯云 / 华为云 轻量应用服务器
- 带宽 5Mbps（够 web UI 用）
- 系统：Ubuntu 24.04 LTS

## ⚠️ 物理隔离（v4 关键设计）

云服务器上**只安装房间门团队**——与老江湖本机的编程团队（ohMeisijiyaCode）**完全隔离**：

| 项 | 云服务器（房间门）| 老江湖本机（编程团队）|
|----|-----------------|---------------------|
| `~/.config/opencode/` | **独立** | **独立** |
| AGENTS.md | 房间门团队 | 编程团队 |
| opencode.json | 房间门 6 Agent | 编程 10 Agent |

**为什么**：避免编程团队的 AGENTS.md 规范（karpathy / TDD / 英文注释）污染房间门团队 + 模型配额独立。

## 2. 基础环境安装

```bash
# SSH 登录后
sudo apt update && sudo apt install -y nodejs npm git curl
sudo npm install -g @opencode-ai/opencode npx
```

## 3. 部署房间门团队

```bash
# 克隆项目
git clone <repo> /opt/myEggeggAgentTeam
cd /opt/myEggeggAgentTeam

# 安装
bash scripts/install.sh

# 配置 opencode.json（参考设计文档 §5.1）
vim ~/.config/opencode/opencode.json
```

## 4. 配置 opencode.json

```json
{
  "agent": {
    "roomdoor":  { "model": "<your-high-model-id>", "fallback_model": "<your-mid-model-id>" },
    "laoJiangHu":   { "model": "<your-high-model-id>", "fallback_model": "<your-mid-model-id>" },
    "qiqi":      { "model": "<your-high-model-id>", "fallback_model": "<your-mid-model-id>" },
    "librarian": { "model": "<your-high-model-id>", "fallback_model": "<your-mid-model-id>" },
    "ccy":       { "model": "<your-mid-model-id>", "fallback_model": "<your-high-model-id>" },
    "update":    { "model": "<your-mid-model-id>", "fallback_model": "<your-high-model-id>" }
  }
}
```

## 5. 启动 opencode web

```bash
# 前台启动（测试用）
opencode web --port 8080

# 后台启动（systemd）
sudo tee /etc/systemd/system/opencode-web.service << 'EOF'
[Unit]
Description=OpenCode Web Service
After=network.target

[Service]
Type=simple
User=ubuntu
ExecStart=/usr/local/bin/opencode web --port 8080
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable --now opencode-web
```

## 6. Cloudflare Tunnel 配置

```bash
# 安装 cloudflared
curl -fsSL https://pkg.cloudflare.com/cloudflare-main.gpg | sudo tee /usr/share/keyrings/cloudflare-main.gpg >/dev/null
echo 'deb [signed-by=/usr/share/keyrings/cloudflare-main.gpg] https://pkg.cloudflare.com/cloudflared focal main' | sudo tee /etc/apt/sources.list.d/cloudflared.list
sudo apt update && sudo apt install -y cloudflared

# 登录 Cloudflare
cloudflared tunnel login

# 创建 tunnel
cloudflared tunnel create roomdoor

# 配置 config.yml
mkdir -p ~/.cloudflared
cat > ~/.cloudflared/config.yml << 'EOF'
tunnel: <your-tunnel-id>
credentials-file: /home/ubuntu/.cloudflared/<your-tunnel-id>.json

ingress:
  - hostname: roomdoor.your-domain.com
    service: http://localhost:8080
  - service: http_status:404
EOF

# 路由 DNS
cloudflared tunnel route dns roomdoor roomdoor.your-domain.com

# 启动 tunnel（systemd）
sudo cloudflared service install
sudo systemctl enable --now cloudflared
```

## 7. 验证

- 浏览器访问 https://roomdoor.your-domain.com
- 应该看到 opencode web 界面
- @房间门 测试对话

## 8. 备份

```bash
# 每月备份记忆
rsync -av ~/.roomdoor-memory/ /backup/roomdoor-$(date +%Y%m)/
```
````

- [ ] **Step 12.2: Commit**

```bash
git add docs/deployment.md
git commit -m "docs: 云服务器部署文档（Cloudflare Tunnel + opencode web）"
```

---

## Task 13: Smoke Test（MVP 验收）

**Files:**
- Modify: `docs/audit/2026-06-17-smoke-test-result.md` (create)（v5.1 修订：audit 目录未创建，文件可放 `docs/superpowers/specs/` 或跳过此 task）

- [ ] **Step 13.1: 执行 smoke test**

测试场景："@房间门 帮我做一个周报 PPT"

预期流程：
1. 女朋友 @房间门
2. 房间门识别任务（PPT → 派 librarian）
3. 房间门 @librarian "把 Markdown 转成 PPT"
4. librarian 调用 doc-processing skill + anthropics/pptx skill
5. 输出 PPT 文件路径

- [ ] **Step 13.2: 记录测试结果**

```markdown
# Smoke Test Result

**日期**: YYYY-MM-DD
**测试场景**: "@房间门 帮我做一个周报 PPT"

## 验证项

- [ ] 房间门能识别 PPT 任务
- [ ] 房间门能 @ librarian dispatch
- [ ] librarian 能调用 pptx skill
- [ ] 输出 PPT 文件路径
- [ ] 整个流程 < 5 分钟

## 结果

[待填]

## 通过标准

- [ ] 5/5 验证项通过
- [ ] 输出文件存在且可打开
```

- [ ] **Step 13.3: Commit**

```bash
# v5.1 修订：audit 目录未创建（设计文档 §7.2 移除）
# 改为可选提交——如果没有 smoke test 文件，commit 跳过 audit 目录
git add docs/audit/ 2>/dev/null || true
git commit -m "test: MVP smoke test" || echo "smoke test 文件未生成，跳过 commit"
```

---

## ✅ MVP 完成检查清单

- [ ] 6 个 Agent 都注册到 `~/.config/opencode/agents/`
- [ ] 3 个 MVP 必做 skill 装好（dispatch-protocol / memory-manager / doc-processing + memory-loader）
- [ ] 4 个记忆种子文件创建
- [ ] AGENTS.md 模板含系统欢迎语
- [ ] install.sh 一键跑通
- [ ] 部署文档（Cloudflare Tunnel + opencode web）
- [ ] 1 个 smoke test 通过

**通过即 MVP 完成**，进入 v1.0 阶段（补 4 个 skill + 5 集成场景）。

---

## 后续阶段

### v1.0 完整版（独立 plan）

- 补 4 个 skill：veteran-mode / accounting-companion / learning-companion（ccy 的 prompt 内嵌即可，无需单独 skill）
- 5 个集成测试场景
- AGENTS.md 实际验证
- 记忆系统 1 周不膨胀验证

### v2.0 扩展版（独立 plan）

- 第三方会计 skill 扩展到 5 个
- 退场机制实现（§6.7）
- 跨机器迁移方案
- 8 个场景完整跑通

---

**END OF MVP PLAN**

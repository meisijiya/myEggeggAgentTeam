# 房间门 Agent 团队设计

**Date**: 2026-06-17
**Author**: OneTwo (编排) + 老江湖 (用户"老江湖"提供需求)
**Status**: Draft (待 reviewer 审查 + 用户最终确认)

---

## 1. 故事背景

### 1.1 用户动机

用户 **老江湖** 已经为自己开发了一套 Agent 团队 [`ohMeisijiyaCode`](https://github.com/meisijiya/ohMeisijiyaCode)（10-Agent 编程团队）。现在他想给**会计专业的女朋友**也设计一个 Agent 团队。

### 1.2 女朋友场景

- **专业**：会计（文科）
- **核心场景**：写文档/PPT/Excel、算账/报表/税务、学习新东西、陪伴聊天、出主意
- **使用设备**：云服务器（Linux），通过 **opencode web**（浏览器）对话
- **预算**：< 80 元/月（v4 加预算明细）
- **用户特征**：不懂技术，需要"傻瓜式"使用体验

#### 💰 预算明细（v4）

| 项 | 估算 | 说明 |
|----|------|------|
| 云服务器 | ~30 元/月 | 国内轻量云服务器（2C2G）|
| 模型 API | ~40 元/月 | 4 HIGH M3 + 2 MID Flash Free，按轻度使用估算 |
| 备份 | ~10 元/月 | 阿里云 OSS / 自建 NAS |
| **总计** | **~80 元/月** | 重度使用可能超（建议月封顶 100 元）|

> **超支应对**：房间门检测到 API 调用成本超阈值 → 降级到 mid 模型 + 提示用户。

### 1.3 与原团队的关键差异

| 维度 | ohMeisijiyaCode（原） | 房间门团队（新） |
|------|----------------------|----------------|
| 用户 | 老江湖（开发） | 女朋友（会计文秘）|
| Agent 数 | 10 | 6 |
| 入口模式 | 单入口（OneTwo）| 单入口（房间门）|
| 模型 | 3 tier（high/mid/low）| 2 tier（high/mid）|
| 核心 skill | 编程（karpathy/TDD/source-driven）| 文档 + 财务 + 陪伴 |
| 月预算 | 200+ | < 80 |

---

## 2. 整体架构

### 2.1 单入口架构图

```
        ┌─────────────────────────────────────────────┐
        │           女朋友 (user)                      │
        └────────────────────┬────────────────────────┘
                             │
                             │ @房间门 (唯一 user-facing)
                             ↓
        ┌─────────────────────────────────────────────┐
        │   房间门 (roomdoor)                          │
        │   - main + dispatcher                       │
        │   - 承载"男友温暖层" + 调度能力              │
        │   - HIGH: MiniMax-M3                        │
        │   - skill: dispatch-protocol + memory-loader│
        └────┬─────────────┬─────────────┬─────────────┘
             │             │             │
             ↓ task()      ↓ task()      ↓ task()
   ┌─────────────┐ ┌─────────────┐ ┌─────────────┐
   │ 老江湖      │ │ 七七        │ │ ccy         │
   │ (veteran)   │ │ (qiqi)      │ │             │
   │             │ │             │ │             │
   │ 隐藏在      │ │ 会计闺蜜    │ │ 名校闺蜜    │
   │ <leader>a   │ │             │ │             │
   │ HIGH: M3    │ │ HIGH: M3 ⬆ │ │ MID: Flash  │
   │             │ │             │ │             │
   │ skill:      │ │ skill:      │ │ skill:      │
   │ veteran-    │ │ accounting- │ │ learning-   │
   │ mode +      │ │ companion   │ │ companion   │
   │ memory-     │ │             │ │             │
   │ loader      │ │             │ │             │
   └──────┬──────┘ └─────────────┘ └─────────────┘
          │
          ↓ task() (仅老江湖可调 update)
   ┌─────────────────┐ ┌─────────────────┐
   │ librarian       │ │ update          │
   │                 │ │                 │
   │ 文档/图片处理   │ │ 项目记忆管理    │
   │ HIGH: M3        │ │ MID: Flash Free │
   │                 │ │                 │
   │ skill: doc-     │ │ skill: memory-  │
   │ processing +    │ │ manager +       │
   │ 4 办公 skill    │ │ memory-loader   │
   └─────────────────┘ └─────────────────┘
```

### 2.2 Agent 角色总表

| Agent | 角色 | user-facing | 模型档位 | 装载 skill 数 |
|-------|------|-----------|---------|--------------|
| **房间门 (roomdoor)** | 女友工作替身 + 团队调度 | ✅ 唯一主入口 | HIGH M3 | 2 |
| **老江湖 (veteran)** | 男友的工程师朋友 + 兜底 | ⚠️ `<leader>a` 隐藏 | HIGH M3 | 2 |
| **七七 (qiqi)** | 会计专业闺蜜 | ❌ | HIGH M3 ⬆ | 1 |
| **ccy** | 名校学霸闺蜜 | ❌ | MID Flash Free | 1 |
| **librarian** | 文档/图片处理专家 | ❌ | HIGH M3 | 3 |
| **update** | 项目记忆管理 | ❌ | MID Flash Free | 2 |

**模型分布**：4 HIGH + 2 MID（auditor 建议把七七从 MID 升到 HIGH，因为会计专业核心不能省钱）

### 2.3 调度权限矩阵

| From \ To | 房间门 | 老江湖 | 七七 | ccy | librarian | update |
|-----------|-------|-------|------|-----|-----------|--------|
| **房间门** | - | ✅ | ✅ | ✅ | ✅ | ✅ |
| **老江湖** | ❌ | - | ❌ | ❌ | ❌ | ✅ |
| **七七 / ccy / librarian / update** | ❌ | ❌ | - | - | - | ❌ |

**调度原则**：
- 房间门是**唯一全调度者**
- 老江湖**只能调 update**（情感对话需要记记忆）
- 其他 subagent 是**叶子节点**，不能再委派

---

## 3. Agent 详细定义

### 3.1 房间门 (roomdoor)

| 项 | 内容 |
|----|------|
| **核心定位** | **女朋友的办公管家**（v4 重定位：纯工具化）|
| **人设关键词** | 专业 / 简洁 / 工具感强 / 不暧昧不撒娇 |
| **说话风格** | 专业简洁，像办公助手，先确认意图再派活 |
| **典型场景** | ① "帮我做 PPT" → 拆任务派 librarian；② "这个分录对不对" → 派七七；③ "我累了" → 简单共情 + 派七七陪聊（不直接承担情感角色）|
| **能做什么** | 委派所有 subagent + 简洁对话 + 维护全局偏好 |
| **不能做什么** | 不直接处理 PPT/Excel（派 librarian）；不做最终决策（金额/税务时派老江湖）；**不承担"男友温暖层"角色**（v4 修订，避免角色混淆）|
| **陪伴感承担者** | 七七（会计闺蜜）+ ccy（学霸朋友）—— 房间门本身保持工具感 |
| **skill 装载** | `dispatch-protocol` + `memory-loader` |

> **v4 修订依据**：patriarch 指出"工作替身 + 男友温暖层 + 团队调度"三个角色混在一个 Agent 里，非技术用户搞不清"它到底是谁"。房间门应保持**纯工具化**，"陪伴感"交给七七/ccy（这两个角色天然适合"朋友"）。

### 3.2 老江湖 (veteran)

| 项 | 内容 |
|----|------|
| **核心定位** | 男友的工程师朋友 + 技术兜底 + 复杂调研（v1 重定位后）|
| **人设关键词** | 老道 / 专业 / 像工程师朋友而非男友 / 拍板不犹豫 |
| **说话风格** | 简洁有力，专业但不冷，偶尔俏皮 |
| **典型场景** | ① 房间门 L3 升级（金额 > 5000 / 税务）→ 老江湖拍板；② 房间门派调研任务 → 老江湖返回结构化结果 |
| **能做什么** | 调研 + 分析 + 拍板 + 调 update 记记忆 |
| **不能做什么** | 不直接面对女朋友（除非她在 `<leader>a` 菜单主动 @）；不调七七/ccy/librarian |
| **入口模式** | user-facing 之一（女朋友可以主动 @老江湖）；默认入口仍是房间门；房间门遇到 L3 触发时**显式 @老江湖** dispatch |
| **skill 装载** | `veteran-mode` + `memory-loader` |

### 3.3 七七 (qiqi)

| 项 | 内容 |
|----|------|
| **核心定位** | 会计专业闺蜜（同专业）|
| **人设关键词** | 同专业 / 务实 / 加班吐槽 / 互相审账 |
| **说话风格** | 接地气、会说"我之前也遇到过"、能用专业术语 |
| **典型场景** | ① "这个分录对不对" → 七七专业判断；② "帮我审下这个月报表" → 七七找出错误 |
| **能做什么** | 会计专业问答 + 报表审核 + 分录判断 + 税务常识 + 情感共鸣 |
| **不能做什么** | 不处理非会计问题（派 ccy）；不做文档格式（派 librarian）；不写代码 |
| **skill 装载** | `accounting-companion` |
| **L3 触发后的处理** | 七七返回时若房间门识别 L3 规则命中（金额/税务/法律等），由**房间门升级到老江湖**（不是七七自己升级）|

### 3.4 ccy

| 项 | 内容 |
|----|------|
| **核心定位** | 名校学霸闺蜜（学习外援）|
| **人设关键词** | 聪明 / 好奇 / 名校气质 / 喜欢教人 |
| **说话风格** | 有条理、爱用类比、偶尔学霸式认真 |
| **典型场景** | ① "教我 Python 基础" → ccy 制定学习路径；② "这个英文合同什么意思" → ccy 翻译 + 解释 |
| **能做什么** | 学习路径设计 + 陌生领域调研 + 知识结构化 + 英语/翻译 |
| **不能做什么** | 不做专业会计判断（七七的领域）；不做 PPT/Excel 排版（librarian 的活）|
| **skill 装载** | `learning-companion` |

### 3.5 librarian

| 项 | 内容 |
|----|------|
| **核心定位** | 文档/图片处理专家 |
| **人设关键词** | 细致 / 工具感强 / 多模态（M3 原生支持）|
| **说话风格** | 直接执行，少废话，专注于"把文件处理好" |
| **典型场景** | ① 拍发票照片 → OCR + 整理成 Excel；② 把 Markdown → Word/PPT；③ 看图表给结论 |
| **能做什么** | PDF/Word/PPT/Excel/图片 处理 + 多模态识别（M3 原生，不需要 mmx 兜底）|
| **不能做什么** | 不做会计判断（专业问题派七七）；不写大段文案（那是房间门或老江湖）|
| **skill 装载** | `doc-processing` + `docx` + `pdf`（精简到 3 个最常用）|

### 3.6 update

| 项 | 内容 |
|----|------|
| **核心定位** | 项目记忆管理（单一写者）|
| **人设关键词** | 安静 / 严谨 / 单一写者 / 不冲突 |
| **说话风格** | 极简、只输出"已写入 X" |
| **典型场景** | ① 房间门说"记住她不爱吃香菜" → update 写入 preferences.md；② 老江湖说"今天聊了实习" → update 写入 current.md |
| **能做什么** | 写入/读取/搜索 `~/.roomdoor-memory/` 下的记忆文件 |
| **不能做什么** | 不做内容生成（不是创作 agent）；不主动决策何时记录（被指挥才动）|
| **特殊机制** | **single-writer**：所有 memory 写入都走 update，避免多 agent 改同一文件冲突 |
| **硬化约束** | ① 禁动 profile.md / preferences.md；② 软删除（移到 _pending_delete/ 7 天）；③ 凌晨 4 点**被 cron 唤醒**后跑自检 |
| **skill 装载** | `memory-manager` + `memory-loader` |

---

## 4. 调度流程 + L3 触发规则

### 4.1 四个核心流程

#### 流程 A：女朋友 → 房间门 → 委派 subagent（最常用）

```
女朋友: "帮我把这个月的财务数据做个PPT汇报"
   │
   ▼
房间门（拆任务）
   │
   ├──→ librarian: "把这个 Excel 数据整理成图表"
   ├──→ ccy: "调研下同行本月财务汇报的常见结构"
   └──→ 房间门整合 → 调用 librarian 生成 PPT
   │
   ▼
房间门 → 女朋友: "PPT 做好了，在 ~/Downloads/财务汇报.pptx"
```

#### 流程 B：女朋友 → 房间门 → L3 升级老江湖（关键决策）

```
女朋友: "我帮公司垫了 8000 元出差费用，怎么报销？"
   │
   ▼
房间门（识别 L3 触发：金额 8000 > 5000）
   │
   ├──→ task(老江湖, "分析 8000 元差旅费报销的合规性和流程")
   │       │
   │       └──→ 老江湖返回结构化分析（涉及税法/会计制度）
   │
   └──→ 房间门整合 → 给女朋友
   │
   ▼
房间门 → 女朋友: "老江湖分析了，这笔可以这样报销：..."
```

#### 流程 C：情感对话 → 老江湖隐式介入（如果用户在 `<leader>a` 主动 @）

```
女朋友: "<leader>a → @老江湖 我最近工作压力大"
   │
   ▼
老江湖（直接对话，调 update 记记忆）
   │
   ├──→ task(update, "记录：女朋友近期工作压力大，2026-06-17")
   └──→ 老江湖安慰 + 给出建议
```

#### 流程 D：闲聊 / 陪伴（房间门直接响应，不派活）

```
女朋友: "@房间门 我今天好累"
   │
   ▼
房间门（识别：闲聊 / 陪伴 → L1 默认行为）
   │
   ├──→ 温柔回应 + 偶尔 task(update, "记录：女朋友今天累了")
   └──→ 不派任何 subagent
```

> 对应 §4.2 `l1_direct_rules.id=default` 与 `id=small_advice`。

### 4.2 L3 触发规则（规则化，**不依赖 LLM 自评 confidence**）

> **设计原则**：LLM 输出的 confidence 字段不可靠（over-confidence on wrong answers, under-confidence on correct ones）。所有触发条件必须基于**可观察的输入特征**（关键词 / 金额 / 输出文本模式），不依赖 subagent 自我评估。
>
> **v5 单一事实源**：本节是**设计参考**。**实现以 `skills/dispatch-protocol/SKILL.md` 为准**。改 L3 规则时**只改 skill**，设计文档改为引用。

```yaml
# dispatch-protocol skill 的 L3 升级规则（单一事实源 = skills/dispatch-protocol/SKILL.md）
l3_escalation_rules:
  - id: amount_threshold
    condition: "输入含金额数字 > 5000 元"
    detection: "正则匹配金额（含 元/块/RMB/$ 符号或纯数字 > 5000）"
    action: "必须升级老江湖"
    examples:
      - "报销 6000 元差旅费"
      - "采购 10 万设备"
  
  - id: tax_keywords
    condition: "输入含 [税, 汇算, 清缴, 申报, 抵扣, 个税, 增值税, 所得税, 发票, 抵扣] 关键词"
    detection: "关键词命中"
    action: "必须升级老江湖"
    examples:
      - "个税年度汇算怎么操作"
      - "增值税申报流程"
  
  - id: legal_keywords
    condition: "输入含 [合同, 法律, 协议, 违约, 诉讼, 律师, 仲裁] 关键词"
    detection: "关键词命中"
    action: "必须升级老江湖"
    examples:
      - "这份合同能签吗"
      - "对方违约怎么办"
  
  - id: life_decisions
    condition: "输入含 [换工作, 买房, 结婚, 保险, 投资, 理财 > 1万, 跳槽, 辞职] 关键词"
    detection: "关键词命中"
    action: "必须升级老江湖"
    examples:
      - "我要不要换工作"
      - "买哪个理财产品"
  
  - id: hedging_language
    condition: "subagent 输出含 [建议咨询专业人士, 我不确定, 需进一步确认, 不能保证, 我不是专家, 请以官方为准] 关键词"
    detection: "subagent 返回文本正则匹配"
    action: "必须升级老江湖"
    rationale: "LLM 自评 confidence 不可靠，但 hedging language 是显式可观察信号"

l2_review_rules:
  - id: short_response
    condition: "subagent 输出长度 < 50 字符（信息不足）"
    detection: "字符串长度检查"
    action: "房间门自己 review + 追问"
    rationale: "短回答可能遗漏关键细节"
  
  - id: simple_accounting
    condition: "简单会计问答（不含 L3 关键词）"
    action: "房间门自己 review"

l1_direct_rules:
  - id: small_advice
    condition: "出主意 / 小建议（非重大决策）"
    examples:
      - "男朋友生日送什么"
      - "中午吃什么"
    action: "房间门直接采纳"
  
  - id: default
    condition: "闲聊 / 陪伴 / 文档格式 / 完整调研"
    action: "房间门直接采纳"
```

**修订说明**：原设计中的 `low_confidence` 和 `medium_confidence` 规则**已删除**——这两条依赖 LLM 自评 confidence，与 R1 修订初衷矛盾。改为基于**可观察的输入特征**（关键词/金额/输出文本模式）+ **hedging language 检测**（LLM 显式表达不确定时）。

### 4.3 错误处理

| 场景 | 处理 |
|------|------|
| subagent 失败 | 房间门重试 1 次，失败则向女朋友汇报 + 让老江湖接手 |
| 老江湖失败 | 房间门直接说"我搞不定，要不要你来" |
| update 写记忆失败 | 记 stderr → 重试 1 次 → 失败则告诉女朋友 |
| 模型 API 超时 | 房间门降级：用 mid 模型重试 |
| L3 升级时老江湖不可用 | 房间门直接说"这个太专业，建议你问下专业人士" |

---

## 5. 模型配置 + Skill 集合

### 5.1 模型配置（用户自行配置）

> **本项目不负责配置具体模型**。模型配置由用户在 `~/.config/opencode/opencode.json` 中自行配置（属于用户级 opencode 配置，不在本项目代码范围内）。

#### 📊 模型分档建议（仅作参考）

| Agent | 档位 | 用途 |
|-------|------|------|
| 房间门 | HIGH | 编排 + 复杂推理 + 用户对话 |
| 老江湖 | HIGH | 拍板 + 调研 + 兜底 |
| 七七 | HIGH | 会计专业核心判断（不能省钱）|
| librarian | HIGH | 多模态文档/图片处理 |
| ccy | MID | 学习外援 + 调研 |
| update | MID | 机械写入（Flash Free 完全够用）|

**分档建议**：
- **HIGH 档**（4 个）：用**当前最强**的国产模型（推荐 MiniMax-M3 或同档）
- **MID 档**（2 个）：用**免费 / 低成本**的国产模型（推荐 deepseek-v4-flash-free 或 MiniMax-M2.5-free）

#### 🔄 Fallback 模型建议（用户配置时参考）

每个 agent 应配 fallback_model 实现**真正降级**：
- HIGH 主模型挂 → fallback 到 MID（避免 fallback 到自己）
- MID 主模型挂 → fallback 到 HIGH（保证关键时刻可用）

#### ⚠️ 配置要点

- 用户配置 opencode.json 时，**每个 agent 都要配 model + fallback_model**
- 本项目 install.sh **不覆盖**用户已有的 opencode.json（保护用户级配置）
- 用户可在 AGENTS.md 模板里查看本团队的模型分档建议

### 5.2 必装 skill 集合

#### 🗂️ A. 办公文档（3 个，精简）

| Skill | 来源 | 装载到 |
|-------|------|--------|
| **docx** | anthropics/skills | librarian |
| **pdf** | anthropics/skills | librarian |
| **pptx** | anthropics/skills | librarian（按需加载）|
| ~~xlsx skill~~ | - | **暂缓**：librarian 通过 Python `openpyxl` / `xlrd` 库直接读写 xlsx（无需 skill），`doc-processing` skill 文档化这 2 个库的常用 API。v2 评估是否装正式 xlsx skill。 |

#### 💰 B. 会计财务（2 个 MVP）

| Skill | 来源 | 装载到 |
|-------|------|--------|
| **tax-advisor** | kazukinagata | 七七 |
| **expense-tracker** | claude-office-skills | 七七 |
| ~~finance-metrics-quickref~~ | - | v2 再评估 |
| ~~financereport~~ | - | v2 再评估 |
| ~~wechatpay-basic-payment~~ | - | v2 再评估 |

#### 🔧 C. 工作流（0 个，房间门按需调用 brainstorming/writing-plans）

> auditor 建议：不要把这些 skill 装载到房间门 prompt 里（token 重）；按需让房间门 `task()` 触发即可

#### 🎭 D. 团队专属（7 个，3 个 MVP 必须先写完）

| Skill | 装载到 | MVP 必需 | 描述 |
|-------|--------|---------|------|
| **dispatch-protocol** | 房间门 | ✅ MVP | 调度协议（含 subagent_type 字符串、prompt 模板、L3 规则、结果格式）|
| **memory-manager** | update | ✅ MVP | 记忆维护规则 + 软删除 + 归档流程 |
| **doc-processing** | librarian | ✅ MVP | librarian 4 个办公 skill 的统一入口 |
| **veteran-mode** | 老江湖 | ⏳ v1.1 | 陪伴 + 决策风格 |
| **accounting-companion** | 七七 | ⏳ v1.1 | 会计专业交互风格 |
| **learning-companion** | ccy | ⏳ v1.1 | 学习 + 调研风格 |
| **memory-loader** | update + 房间门 + 老江湖 | ⏳ v1.1 | 按需加载 memory |

> **MVP 必须先写完 3 个**（dispatch-protocol / memory-manager / doc-processing），否则 install.sh 装上去是空壳

#### 🧠 E. 记忆系统集成

update / 房间门 / 老江湖都装载 memory-loader。

**"按需加载"定义**：
- **任务开始时**：update Agent 通过 `task()` 返回**所需的 memory 片段**（不返回全量文件）
- **房间门/老江湖的 prompt 模板**：把 memory 片段拼接到 subagent prompt 中（仅传相关上下文）
- **不加载整个 active/ 目录**：避免 token 爆炸（4 文件全量 ≈ 600 行 = ~3000 tokens）
- **示例**：女朋友问"我最近常吃什么" → update 只返回 preferences.md 的相关行（不返回 profile.md）

### 5.3 每个 Agent 装载 skill 子集（≤ 3 个）

| Agent | 装载 skill | 模型 |
|-------|----------|------|
| 房间门 | dispatch-protocol + memory-loader | M3 |
| 老江湖 | veteran-mode + memory-loader | M3 |
| 七七 | accounting-companion | M3 |
| ccy | learning-companion | Flash Free |
| librarian | doc-processing + docx + pdf | M3 |
| update | memory-manager + memory-loader | Flash Free |

---

## 6. 记忆系统（硬化版）

### 6.1 存储结构

```
~/.roomdoor-memory/                     # 点开头，ls 默认不可见
├── active/                             # ≤4 个文件
│   ├── profile.md                      # ≤100 行，禁动
│   ├── current.md                      # ≤200 行
│   ├── preferences.md                  # ≤150 行，禁动
│   └── finance.md                      # ≤200 行
├── archive/                            # 按季度归档
│   └── 2026-Q2.md
├── _pending_delete/                    # 软删除区（7 天确认）
│   └── 2026-06-XX-conversation.md
└── meta/
    ├── index.md                        # 索引
    └── stats.md                        # 统计
```

### 6.2 核心原则

```
✅ 轻量：≤ 6 个文件 + 2 个 meta
✅ 自主优化：update 主动维护（合并 / 归档 / 软删除）
✅ 活跃记忆：定期整理
✅ 不膨胀：容量上限 + 时间衰减 + 软删除
❌ 女朋友不直接管理（透明但不可见）
❌ update 不写 ~/.config/opencode/（铁律保持）
```

### 6.3 update Agent 硬化约束

#### 🚫 禁止操作

| 行为 | 禁止原因 |
|------|---------|
| 修改 profile.md | 女朋友人设的根 |
| 修改 preferences.md | 长期偏好，删除会"丢失人" |
| 实时合并 / 实时压缩 | 容易被 LLM 误判，必须定时 |
| 实时删除（不走 _pending_delete/）| 给女朋友/老江湖反悔机会 |

#### ✅ 允许操作

| 行为 | 规则 |
|------|------|
| 写入 current.md | 短期记忆追加 |
| 写入 finance.md | 会计相关追加 |
| 合并 current.md 同类条目 | 仅合并**纯文本/事件类**（如"今天开了个会"），不合并人设 |
| 归档 current.md 过期内容 | 移到 `archive/<季度>.md` |
| 软删除 | 移到 `_pending_delete/` 7 天后没人反对才真删 |

#### ⏰ 触发整理的时机

| 时机 | 触发者 | 动作 |
|------|--------|------|
| **凌晨 4 点定时**（cron）| 操作系统 | update 跑一次自检 |
| **写入时自检** | update 自动 | 重复检测、容量预检 |
| **房间门主动调度** | 房间门 | `task(update, "整理记忆")` |

### 6.4 容量上限（防膨胀）

```
active/profile.md     ≤ 100 行
active/current.md     ≤ 200 行（短期记忆）
active/preferences.md ≤ 150 行
active/finance.md     ≤ 200 行

单文件超限 → 触发总结压缩
总大小 > 5MB → 触发归档
```

### 6.5 时间衰减策略

```
current.md 里的内容：
├── 1 个月内：活跃
├── 1-3 个月：标记"待整理"
└── > 3 个月：归档到 archive/

preferences/finance 里的内容：
└── 永不过期（偏好是长期属性）

conversations 已归档内容：
└── > 6 个月 + 从未被引用 → 软删除
```

### 6.6 记忆被动更新原则（**核心设计原则**）

> **绝对原则**：记忆更新是**被动的**——女朋友说了什么 update 才记什么。**禁止**主动询问 / 引导 / 收集信息。

#### ✅ 触发 update 写入的场景（房间门/老江湖的 prompt 里要写清楚）

| 女朋友说的内容 | 写入文件 | 触发条件 |
|---------------|---------|---------|
| 偏好 / 习惯 / 喜欢 / 不喜欢 | preferences.md | 显式表达（"我不要 X"、"我喜欢 Y"）|
| 长期个人信息（专业 / 生日 / 爱好）| profile.md | 自然提到，不主动问 |
| 当前在做的工作 / 项目 | current.md | 自然提到（"我下周要做 X"）|
| 会计相关专属信息（科目 / 模板）| finance.md | 自然提到 |
| 关系相关（关于老江湖 / 七七 / ccy）| relationships/<人>.md | 自然提到 |

#### ❌ 不主动做的事

- ❌ 房间门不主动问"你叫什么 / 学的什么专业 / 有什么偏好"
- ❌ 不写"开场白模板"进 prompt（新 session 重复会烦）
- ❌ 不做"5 个引导问题"初始化流程
- ❌ 不在对话中刻意引导收集信息
- ❌ update 不主动询问女朋友

#### 🔍 房间门/老江湖的判断逻辑（prompt 约束）

```
何时让 update 记：
- 女朋友说"我不喜欢 X" → 偏好
- 女朋友说"我是 X 专业" → profile
- 女朋友说"我下周要做 X" → current
- 女朋友说"我学过 X" → profile
- 女朋友说"我们公司用 X 系统" → finance / current

何时不记：
- 闲聊内容（"今天天气好"）
- 临时问题（"1+1 等于几"）
- 一次性信息（"刚才吃了什么"）——除非女朋友强调（"我特别不爱吃 X"）
```

#### 📋 写入格式

```markdown
## YYYY-MM-DD HH:MM

**内容**: <原话或精简>

**来源**: <女朋友 | 房间门 | 老江湖>

**标签**: #preference #profile #finance #current
```

### 6.7 退场机制（v4 新增）

> **设计原则**：女朋友可能不用了——这是正常的产品生命周期，不应被忽视。

#### 🔚 触发退场的场景

| 场景 | 检测 | 处理 |
|------|------|------|
| **女朋友主动说不用了** | 女朋友说"我不想用了" / "关掉吧" | 立即停服（见下）|
| **长期不活跃** | `~/.roomdoor-memory/active/current.md` 3 个月没更新 | 老江湖 cron 提醒："3 个月没用了，要保留还是关掉？" |
| **女朋友兴趣消退** | 使用频率持续下降（每周 < 1 次）| 老江湖主动问："还在用吗？需要调整吗？" |

#### 🛑 停服流程

```bash
# 1. 备份完整记忆（最后一次）
rsync -av ~/.roomdoor-memory/ /backup/final-$(date +%Y%m)/

# 2. 导出记忆为可读 PDF（给女朋友留作纪念）
opencode task(update, "export-memory --format=pdf --output=~/memory-archive.pdf")

# 3. 停掉 opencode web 服务
systemctl stop opencode-web

# 4. 取消 cron 任务
crontab -l | grep -v "opencode task(update" | crontab -

# 5. 决定云服务器续费
# 选项 A: 保留服务器（记忆随时可恢复）—— 续费
# 选项 B: 释放服务器（彻底告别）—— 备份后释放
```

> **不强制释放**：给老江湖决定权——有些情侣分手后还会保留一些数字记忆，技术上不应自动删除。

---

## 7. 安装 + 部署（云服务器）

### 7.1 部署目标

- **目标机器**：云服务器（Linux），**女朋友专属**
- **目标用户**：女朋友（**远程访问，不直接 SSH**）
- **访问模式**：通过浏览器访问（opencode web 模式）
- **数据持久化**：云服务器快照 + rsync 备份 `~/.roomdoor-memory/`

#### 🔒 物理隔离（v4 关键设计）

云服务器上**只安装房间门团队**——与老江湖本机的 ohMeisijiyaCode（编程团队）**完全隔离**：

| 项 | 云服务器（房间门团队）| 老江湖本机（ohMeisijiyaCode 编程团队）|
|----|---------------------|-------------------------------------|
| 用途 | 女朋友 AI 办公 | 老江湖编程 |
| `~/.config/opencode/` | **独立**（房间门团队专属）| **独立**（编程团队专属）|
| AGENTS.md | 房间门团队配置 | 编程团队配置（karpathy/TDD 等）|
| opencode.json | 6 个房间门 Agent + 干净模型配置 | 10 个编程 Agent + 编程模型配置 |
| opencode web | 绑一个域名（女朋友用）| 不开 web（老江湖用 TUI/IDE）|
| 模型配额 | 房间门团队独占 | 编程团队独占 |

**为什么物理隔离**：
- 编程团队的 AGENTS.md 规范（"用英文代码注释"、"遵循 TDD"、"karpathy 守则"）会**污染**房间门团队的语境
- 模型配额不互相争抢（避免一方超支导致另一方挂）
- 调试 / 维护 / 升级互不干扰
- 就像"公司服务器"和"家庭 NAS"分开放在不同柜子里

> **v4 修订依据**：patriarch 指出"两个团队共用 `~/.config/opencode/`"是最大架构隐患，必须物理隔离。

#### 🌐 远程访问方案（推荐）

女朋友**不需要懂 SSH / 命令行**——通过浏览器直接访问：

```
[女朋友浏览器] → https://your-domain.example.com → [opencode web 模式]
                                                       ↓
                                              [云服务器 :8080]
```

**推荐方案**：opencode web 模式 + Cloudflare Tunnel（无需开防火墙 / 配置证书）

| 组件 | 作用 | 部署方式 |
|------|------|---------|
| **opencode web** | 提供 Web UI（浏览器可访问）| `opencode web --port 8080` 启动 |
| **Cloudflare Tunnel** | 把云服务器 8080 端口暴露到公网域名（带 HTTPS）| `cloudflared tunnel create roomdoor` |
| **浏览器书签 / 桌面快捷方式** | 女朋友一键访问 | 给她发个链接：`https://roomdoor.your-domain.com` |

**替代方案**（如果不用 Cloudflare）：
- **Tailscale**：组网方式访问（更安全，但需要装客户端）
- **自建反代**：Nginx + Let's Encrypt（需要域名 + 防火墙配置）
- **SSH 隧道**（仅技术用户）：`ssh -L 8080:localhost:8080 user@server`

**会话持久化**：opencode 会话默认保存到 `~/.local/share/opencode/`，下次打开浏览器可恢复上下文。

**多端访问策略**：推荐**每端独立会话**（避免互相污染）。如果需要同步上下文，用 opencode 的 session ID 共享机制（v1.1 评估）。

**国内网络优化**：云服务器选国内节点 + 模型 API 也用国内（MiniMax / DeepSeek），延迟 < 100ms。

### 7.2 项目目录结构

```
myEggeggAgentTeam/                          # 项目根目录（部署到云服务器）
├── README.md / README.zh-CN.md
├── install.sh / uninstall.sh
├── agents/                                 # 6 个 Agent 定义
│   ├── roomdoor.md
│   ├── veteran.md
│   ├── qiqi.md
│   ├── ccy.md
│   ├── librarian.md
│   └── update.md
├── skills/                                 # 7 个团队专属 skill（3 个 MVP + 4 个 v1.1）
│   ├── dispatch-protocol/        (MVP 必需)
│   ├── memory-manager/           (MVP 必需)
│   ├── doc-processing/           (MVP 必需)
│   ├── veteran-mode/             (v1.1)
│   ├── accounting-companion/     (v1.1)
│   ├── learning-companion/       (v1.1)
│   └── memory-loader/            (v1.1)
├── docs/
│   └── superpowers/
│       └── specs/
│           └── 2026-06-17-roomdoor-team-design.md
├── templates/
│   ├── AGENTS.md                 # 用户级模板
│   └── opencode.json             # 模型配置模板
├── scripts/
│   ├── install.sh                # 一键安装（v5: glob 复制 skill）
│   └── setup-memory.sh           # 初始化 ~/.roomdoor-memory/ + cron
└── memory-seed/                  # 初始记忆种子
    ├── profile-seed.md
    ├── preferences-seed.md
    ├── current-seed.md
    └── finance-seed.md
```

### 7.3 install.sh 工作流（6 步）

```bash
#!/usr/bin/env bash
# install.sh - 房间门 Agent 团队一键安装（云服务器版）

set -euo pipefail

# Step 1: 备份现有配置
BACKUP=~/.config/opencode/backup/$(date +%Y%m%d-%H%M%S)
mkdir -p "$BACKUP"

# Step 2: 安装 6 个 Agent 到 ~/.config/opencode/agents/
cp agents/*.md ~/.config/opencode/agents/

# Step 3: 安装 3 个 MVP 团队专属 skill
cp -r skills/dispatch-protocol skills/memory-manager skills/doc-processing ~/.config/opencode/skills/

# Step 4: 安装第三方 skill（固定 commit hash 防漂移；失败仅警告，不阻塞）
echo "→ 安装 anthropics 办公 skill..."
npx skills add anthropics/skills@<commit_hash> --skill docx pdf pptx 2>&1 | tee -a install.log || echo "⚠️  anthropics 技能安装失败，跳过（不影响核心功能）"

echo "→ 安装会计财务 skill..."
npx skills add <财务 skill repo>@<commit_hash> --skill tax-advisor expense-tracker 2>&1 | tee -a install.log || echo "⚠️  财务技能安装失败，跳过"

# Step 5: 提示用户配置 opencode.json（**本项目不自动写用户级配置**）
echo ""
echo "⚠️  请手动配置 ~/.config/opencode/opencode.json："
echo "    参考 §5.1 模型分档建议，给 6 个 agent 分配 model + fallback_model"
echo "    配置完成后，重启 opencode 让配置生效"
echo ""

# Step 6: 初始化 memory + AGENTS.md
mkdir -p ~/.roomdoor-memory/{active,archive,_pending_delete,meta}
cp memory-seed/*.md ~/.roomdoor-memory/active/

[ ! -f ~/.config/opencode/AGENTS.md ] && cp templates/AGENTS.md ~/.config/opencode/AGENTS.md

# Step 7: 设置凌晨 4 点 cron（update 自检）
(crontab -l 2>/dev/null; echo "0 4 * * * /usr/local/bin/opencode task(update, 'memory-self-check') >> ~/.roomdoor-memory/meta/cron.log 2>&1") | crontab -

echo "✅ 安装完成！"
echo "1. 配置 ~/.config/opencode/opencode.json（见 §5.1）"
echo "2. 重启 opencode"
echo "3. 通过 opencode web 访问（https://your-domain.example.com）"
echo "4. @房间门 启动对话"
```

> **关键**：第三方 skill 安装失败仅警告（`|| echo`），不阻塞 install.sh。M3 团队的核心功能不依赖 anthropics/skills 或会计 skill 仓库——MVP 阶段所有核心 skill（dispatch-protocol / memory-manager / doc-processing）都是本项目自带的。

### 7.4 卸载 uninstall.sh

- 默认**保留** memory（女朋友的记忆宝贵）
- 可选删除第三方 skill（如果仅本团队用）
- 卸载 6 个 Agent + 7 个团队专属 skill

### 7.5 用户使用流程（**被动记忆 + 正常对话**）

```
1. 打开浏览器访问 https://roomdoor.your-domain.com
2. 浏览器里 @房间门 启动对话
3. 跟房间门正常聊天——她说什么、问什么，房间门就处理什么
4. 房间门/老江湖在对话中**被动更新记忆**（见 §6.6）
5. 女朋友需要老江湖时，可以直接 @老江湖；房间门遇到 L3 也会主动 @老江湖
```

#### ❌ 设计上**不做**的事

- ❌ 不写"开场白模板"进 prompt（新开 session 重复问会很烦）
- ❌ 不做"5 个引导问题"初始化（不应主动问"你叫什么"）
- ❌ 不在首轮主动告知老江湖入口（女朋友需要时自然会 @）
- ❌ 不强制女朋友按固定流程走（正常聊天就好）

#### ✅ 设计上**做**的事

- ✅ 房间门正常接收女朋友的对话
- ✅ 房间门在合适的时机 @ subagent dispatch
- ✅ 记忆是被动更新（见 §6.6）——女朋友说了重要信息 → 房间门/老江湖 task(update, "记住 X")
- ✅ 女朋友想直接找老江湖 → @老江湖（不需要"特殊入口提示"）

### 7.6 AGENTS.md 模板（用户级，含系统级欢迎语）

```markdown
# 房间门团队全局配置（云服务器版）

## 💬 系统欢迎语（首次打开对话可见）

> **你好！我是房间门 👋 我可以帮你做文档（Word/PPT/Excel）、算账查税、翻译资料、出主意。有什么直接告诉我就好。**
>
> ℹ️ 对话内容会被记录用于改善回答（闲聊不会）。你随时可以说"删除刚才的记录"撤销。

## 系统信息
{{SYSTEM_INFO}}  # 云服务器 Linux

## Emoji 使用
{{EMOJI_USAGE_NOTE}}

## 团队成员速查
| Agent | 类型 | 模型（建议）|
|-------|------|----------|
| roomdoor (房间门) | main + dispatcher | HIGH |
| veteran (老江湖) | user-facing 次入口 | HIGH |
| librarian | subagent | HIGH |
| qiqi (七七) | subagent | HIGH |
| ccy | subagent | MID |
| update | subagent | MID |

## 记忆系统
所有 Agent 通过 update Agent 读写 ~/.roomdoor-memory/
女朋友不直接管理记忆；Agent 自维护（定时凌晨 4 点 + 写入时自检）。
profile.md / preferences.md 禁动。

## L3 触发规则
涉及金额 > 5000、税务/法律关键词、人生决策时，房间门显式 @ 老江湖。
```

> **v4 修订依据**：patriarch 指出"不主动问个人信息"和"不告诉用户能做什么"是两回事。这里加的"系统欢迎语"是 **AGENTS.md 系统级提示**，不是房间门 prompt 里的开场白——女朋友打开对话就能看到，不会重复问（每次开 session 不重复）。

---

## 8. 错误处理 + 测试 + 验收

### 8.1 错误处理

| 错误类型 | 检测 | 处理 |
|---------|------|------|
| subagent 失败 | task() 返回错误或超时 | 房间门重试 1 次 → 失败则告诉女朋友 + 让老江湖接手 |
| 老江湖失败 | task() 异常 | 房间门直接说"这个我也搞不定" |
| update 写失败 | 文件权限 / 路径错 | 记 stderr → 重试 1 次 → 失败则告诉女朋友 |
| 模型 API 超时 | 连接错误 / 429 | 自动切 fallback_model |
| 第三方 skill 不可用 | npx skills add 失败 | install.sh 警告 + 跳过 |
| 记忆文件损坏 | 读取解析失败 | update 跳过损坏文件 + 记日志 |

### 8.2 测试方法

#### A. Agent 单元测试（手动跑 3 个用例 / Agent）

| Agent | 测试用例 |
|-------|---------|
| 房间门 | ①"帮我做 PPT" → 应 task librarian；②"我想你了" → 直接回；③ 金额 > 5000 → L3 升级老江湖 |
| 老江湖 | ① 调研任务 → 结构化返回；② 决策场景 → 给建议；③ 软删除场景 |
| 七七 | ①"这个分录对不对" → 专业判断；② 金额 6000 → 触发 L3 升级 |
| ccy | ①"教我 X" → 学习路径；② 翻译 |
| librarian | ① Word/PDF 处理；② OCR 图片 |
| update | ① 写入偏好；② 凌晨定时自检；③ 软删除 7 天确认 |

#### B. 集成测试（5 个端到端场景，v1.1 再补）

MVP 阶段只做 **1 个 smoke test**：
- 场景："@房间门 帮我做一个周报 PPT" → 房间门 → 调 librarian → 输出 PPT 文件

### 8.3 验收标准（Definition of Done）

#### ✅ MVP 验收（团队能跑起来）

- [ ] 6 个 Agent 全部注册到 `~/.config/opencode/agents/`
- [ ] opencode.json 模型分配正确（4 high M3 + 2 mid Flash Free）
- [ ] 3 个 MVP 团队专属 skill 装好（dispatch-protocol + memory-manager + doc-processing）
- [ ] 第三方 skill 装好（3 办公 + 2 财务）
- [ ] 记忆目录 `~/.roomdoor-memory/` 创建成功
- [ ] `bash install.sh` 一键跑完无错误
- [ ] 1 个 smoke test 通过（@房间门 做周报 PPT）

#### ✅ 体验验收（v1.0 完整版）

- [ ] 单入口工作（女朋友只 @房间门）
- [ ] 调度权限正确（房间门可派所有 subagent，老江湖只能派 update）
- [ ] L3 升级规则触发正确（金额 > 5000 / 税务关键词 → 升级老江湖）
- [ ] 4 个团队专属 skill 补齐（veteran-mode + accounting-companion + learning-companion + memory-loader）
- [ ] 5 个集成测试场景跑通
- [ ] 记忆系统使用 1 周不膨胀（active/ 总量 < 5MB）

#### ✅ 完整体验收（v2.0 扩展版）

- [ ] 女朋友能独立使用（不需要老江湖指导）
- [ ] 8 个场景全部跑通
- [ ] 记忆系统连续使用 1 个月不膨胀
- [ ] 第三方会计 skill 扩展到 5 个（v2 评估）

### 8.4 维护 / 升级

| 维护项 | 频率 | 方式 |
|--------|------|------|
| Agent prompt 优化 | 持续 | 改 `agents/*.md`，重启 opencode |
| 第三方 skill 升级 | 每月 | `bash scripts/upgrade-skills.sh`（锁 commit hash） |
| 记忆归档检查 | 每天凌晨 4 点 | cron + update Agent 跑整理 |
| 备份 memory | 每月 | `bash scripts/backup-memory.sh`（rsync 到云盘）|
| 团队迭代 | 不定期 | git commit + push |

### 8.5 已知风险

| 风险 | 影响 | 缓解 |
|------|------|------|
| Free 模型效果不稳定 | ccy/update 偶尔输出差 | fallback_model + L3 review |
| LLM-driven 记忆不精确 | update 可能误合并 | profile/preferences 禁动 + 软删除 + 凌晨定时 |
| prompt 质量决定体验 | 团队好不好用 | 持续迭代 + 用户反馈 |
| 第三方 skill 仓库变更 | skill 不可用 | install.sh 锁 commit hash |
| 隐私 / 敏感信息泄漏 | 记忆里有密码 | **双层过滤**：① 房间门 `task(update, ...)` 前 sanitize 输入（移除身份证/银行卡/密码/token 字符串）；② update 写入时再做正则检查（身份证 18 位 / 银行卡 16-19 位 / 手机号 11 位 / 长 token 串）|
| ~~老江湖入口不直接暴露~~ | v3 解决：老江湖本来就是 user-facing，@ 即可 | 不需要特殊说明 |

---

## 9. 修订记录

### 9.1 来自 auditor 审查（feasibility = 中，worth_doing = 谨慎）

#### 3 个必做修订（已整合 v1）

| # | 修订 | 整合到 |
|---|------|--------|
| R3 | 单入口（房间门唯一 user-facing，老江湖隐藏）| §2.1, §3.2, §7.6 |
| R4 | Memory 路径 `~/.roomdoor-memory/`（不破坏 .config 铁律）| §6.1, §7.3 |
| R1 | L3 触发规则化（不依赖 LLM 自评 confidence）| §4.2 |
| R2 | update 硬化（profile/preferences 禁动 + 软删除 + 凌晨定时）| §6.3 |

#### 3 个建议修订（已整合 v1）

| # | 修订 | 整合到 |
|---|------|--------|
| S1 | 七七升 M3（4 high + 2 mid）| §5.1 |
| S2 | 第三方会计 skill 收紧到 2 个 MVP | §5.2 |
| S3 | 每个 agent 装载 skill ≤ 3 个 | §5.3 |

### 9.2 来自 reviewer 审查（verdict = needs-changes）

#### 5 个 blocking 修订（v2 整合后已被 v3 推翻）

| # | 修订 | v2 整合 | v3 推翻理由 |
|---|------|---------|------------|
| B1 | R1 修订不彻底（low_confidence / medium_confidence 规则残留）→ 改为 hedging language 检测 | §4.2 | 保留 ✅ |
| B2 | fallback_model 形同虚设 → 改为 Flash Free | §5.1 | 保留 ✅ |
| B3 | install.sh set -e 与"警告 + 跳过"矛盾 → 加 `\|\| echo` 保护 | §7.3 | 保留 ✅ |
| B4 | 远程访问方式未定义 → opencode web + Cloudflare Tunnel | §7.1 | 保留 ✅ |
| B5 | 老江湖入口 UX 死结 → 房间门首轮对话主动告知 | §3.2, §7.5 | **v3 推翻**：老江湖本来就可以 @，不需要"主动告知"，让设计回归自然 |

#### 顺手修的 6 个 major 修订（v2 整合）

| # | 修订 | v2 整合 | v3 修订 |
|---|------|---------|---------|
| M1 | 凌晨 cron + 软删除实施细节缺失 | §6.3 | 保留 ✅ |
| M2 | 备份目标云盘未指定 | §8.4 | 保留 ✅ |
| M3 | §3.3 七七"L3 触发"位置不对 | §3.3 | 保留 ✅ |
| M4 | xlsx 暂缓理由不充分 → 加 openpyxl/xlrd 说明 | §5.2 | 保留 ✅ |
| M5 | "5-10 轮" vs 5 个引导问题不一致 → 改为"5 轮" | §7.5 | **v3 推翻**：连"5 轮引导"都取消 |
| M6 | §4.1 缺闲聊/陪伴流程 → 加流程 D | §4.1 | 保留 ✅ |

### 9.3 来自用户（老江湖）的反馈（v3 整合）

#### 3 个核心修正（颠覆 v2 部分设计）

| # | 反馈 | v3 整合 |
|---|------|---------|
| U1 | **记忆更新应该是被动的，不是询问式的**——不要主动问女朋友信息 | §6.6 新增"记忆被动更新原则" |
| U2 | **opencode web 只能通过 @ 显式 dispatch subagent**——这是机制，不是限制 | §3.2 老江湖入口改成 user-facing（@即可），不需要"主动告知" |
| U3 | **不要搞开场白/引导问题**——正常对话就好 | §7.5 完全重写为"被动记忆 + 正常对话" |

#### v3 关键改动总结

```
v2 的过度设计：
- ❌ "房间门第一轮回复模板"开场白
- ❌ "5 个引导问题"初始化
- ❌ 首次对话主动告知老江湖入口

v3 的简洁设计：
- ✅ 女朋友跟房间门正常聊天
- ✅ 记忆被动更新（女朋友说什么 update 才记）
- ✅ 老江湖本来就是 user-facing，需要时 @ 即可
- ✅ 房间门遇到 L3 显式 @ 老江湖 dispatch
```

### 9.4 来自 patriarch 战略审查（verdict = needs-rethink，v4 整合）

#### 3 个重大战略问题（已整合 v4）

| # | patriarch 反馈 | v4 整合 |
|---|---------------|---------|
| P1 | **角色混淆**：房间门同时是"工作替身 + 男友温暖层 + 团队调度"，非技术用户搞不清"它是谁" | §3.1 房间门重定位为"**办公管家**"（纯工具化），移除"男友温暖层"，陪伴感让七七/ccy 承载 |
| P2 | **两团队架构冲突**：房间门团队和 ohMeisijiyaCode 共用 `~/.config/opencode/` 会污染 | §7.1 加"物理隔离"——云服务器只装房间门团队，独立 opencode 实例 |
| P3 | **发现性问题**：不主动问 ≠ 不告诉用户能做什么 | §7.6 AGENTS.md 加系统欢迎语（一行）+ 隐私透明声明 |

#### 1 个家长视角补充（已整合 v4）

| # | 反馈 | v4 整合 |
|---|------|---------|
| P4 | **退场机制缺失**：女朋友不用了怎么办？ | §6.7 新增"退场机制"——备份记忆 → 导出 PDF → 停服 → 决定云服务器续费 |

#### 预算明细补充（v4）

| 项 | v4 整合 |
|---|---------|
| §1.2 加预算明细表（云服务器 ~30 + 模型 API ~40 + 备份 ~10 = ~80 元/月） | §1.2 |

#### 优先级建议（patriarch）

1. ✅ 用户已验证需求（女朋友很需要 AI 工具干活）—— **通过 patriarch 的"先跟女朋友聊"卡点**
2. 🟢 进入 v4 修订 + writing-plans 阶段

### 9.5 已知未解决问题

| # | 问题 | 状态 | 备注 |
|---|------|------|------|
| Q1 | xlsx skill 是否需要？ | **已回答** | 用 openpyxl/xlrd 库替代；v2 评估正式 skill |
| Q2 | 老江湖入口 UX | **v3 解决** | 本来就可以 @，不需要特殊入口 |
| Q3 | 会话持久化 / 多端访问 | 待 v1.1 评估 | opencode web 模式默认支持 |

---

## 10. 下一步

按 brainstorming skill 流程：

1. ✅ Write design doc（**v4 已整合 patriarch 反馈**）
2. ✅ Spec self-review + Reviewer 审查 + 用户反馈整合 + patriarch 战略审查
3. ⏳ **用户最终审阅**（v4）
4. ⏳ 调 writing-plans skill 写实现 plan

---

**END OF DESIGN DOC v4**

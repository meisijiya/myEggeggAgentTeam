---
name: baoyu-translate
description: 专业中英/多语种翻译。触发场景：用户要求翻译文档、IFRS 准则、英文财报、外文合同、政策文件、学术论文；说"翻译" "translate" "改成中文" "改成英文" "convert to Chinese" "localize" "精翻" "快翻" "这篇文章翻译一下"。支持三档模式：quick（短文本快速）/ normal（标准分析+翻译）/ refined（出版级，含审校润色）。支持风格（formal/technical/business/academic 等）和受众（general/technical/academic/business）自定义。
version: 1.0.0
---

# 专业翻译器

三档翻译工作流。**由 LLM 直接执行**，不依赖外部脚本。

## 三档模式

| 模式 | 触发关键词 | 工作流 | 适用场景 |
|---|---|---|---|
| **quick** | "快翻" "quick" "直接翻译" "快速翻译一下" | 直接翻译 → 输出 | 短文本、邮件、便条 |
| **normal**（默认） | 其他未明确指明 | 分析 → 翻译 → 输出 | 文章、报告、博客、一般文档 |
| **refined** | "精翻" "refined" "publication quality" "proofread" "精细翻译" "润色一下" | 分析 → 翻译 → 审校 → 润色 → 输出 | 出版、正式文件、IFRS 准则、合同 |

**升级路径**：normal 完成后，用户说"继续润色"或"refine" → 转入 refined 的审校润色步骤。

## 风格预设（voice & tone）

| 值 | 效果 |
|---|---|
| `storytelling`（默认） | 流畅叙事、转场自然、表达生动 |
| `formal` | 专业、结构化、中性、无口语 |
| `technical` | 精准、文档化、术语密集、不修饰 |
| `literal` | 贴近原文结构、保留句式、改动最小 |
| `academic` | 学术、严谨、复杂句可、引用感知 |
| `business` | 简洁、结果导向、行动导向、要点式 |
| `humorous` | 保留并适配幽默、机智、还原笑点 |
| `conversational` | 口语化、友好、像在跟朋友解释 |
| `elegant` | 文学化、考究、韵律、措辞精细 |

用户也可自定义风格，如 `--style "诗意抒情"`。

## 受众预设

| 值 | 效果 |
|---|---|
| `general`（默认） | 通用读者，专业术语加注 |
| `technical` | 工程师/开发者，少注常见技术词 |
| `academic` | 研究者/学者，正式、术语精准 |
| `business` | 商务人士，友好解释技术概念 |

用户也可自定义受众。

## 核心翻译原则（所有模式通用）

1. **重写而非直译**：像目标语言的母语作者从零写就。质量检测："读起来像目标语言原生文章吗？"
2. **准确性优先**：事实、数据、逻辑必须与原文一致
3. **自然流畅**：用目标语言的惯用语序；拆长句；习语/隐喻按"意思"翻译，不按字面
4. **术语一致**：用规范译法；首次出现时在括号内加注原文
5. **保留格式**：所有 markdown 格式（标题、粗体、斜体、图片、链接、代码块）原样保留
6. **主动解释**：对目标读者可能陌生的概念，加粗括号注释 `（**解释**）`；宁少勿多
7. **Frontmatter 处理**：源文件若有 YAML frontmatter，源字段加 `source` 前缀（camelCase），新增译文字段，跳过 `title` 若正文已有 H1

## 工作流

### Quick 模式
1. 接收输入（文件路径 / URL / 内联文本）
2. 直接翻译
3. 保存到输出文件
4. 汇报

### Normal 模式
1. 接收输入
2. **分析** → 输出 `01-analysis.md`（领域、语气、术语、翻译难点）
3. **组装 prompt + 翻译** → 输出 `translation.md`
4. 提示用户："翻译完成。回复 **继续润色** 或 **refine** 可进入审校润色步骤。"

### Refined 模式
1. 接收输入
2. **分析** → `01-analysis.md`
3. **组装 prompt** → `02-prompt.md`
4. **初稿** → `03-draft.md`
5. **审校**（批判性 review）→ `04-critique.md`（诊断：准确性、欧化语、策略执行、表达问题）
6. **修订** → `05-revision.md`（应用审校意见）
7. **润色** → `translation.md`（最终出版级译文）
8. 汇报

## 输出位置

- 输入是文件 → `{源文件目录}/{源文件名}-{目标语言}/`
- 输入是 URL/文本 → 先保存到 `translate/{slug}.md`，输出到 `translate/{slug}-{目标语言}/`

输出目录文件名约定：

| 文件 | 模式 | 说明 |
|---|---|---|
| `translation.md` | 所有 | 最终译文（**始终是这个文件名**） |
| `01-analysis.md` | normal/refined | 内容分析 |
| `02-prompt.md` | normal/refined | 组装好的翻译 prompt |
| `03-draft.md` | refined | 审校前的初稿 |
| `04-critique.md` | refined | 审校意见（仅诊断） |
| `05-revision.md` | refined | 修订稿 |

## 实用建议（针对会计场景）

- **IFRS 准则翻译**：用 `technical` 或 `academic` 风格，受众 `technical`，normal 或 refined 模式
- **英文财报翻译**：用 `business` 风格，受众 `business`
- **学术论文翻译**：用 `academic` 风格，受众 `academic`，refined 模式
- **政策文件翻译**：用 `formal` 风格，受众 `general`
- **长文档**（>4000 字）：建议 normal 模式（LLM 会分段保持术语一致）

## 重要提示

- **不调用外部 API**——翻译由 LLM 自己执行（不调 mmx、不调 OpenAI）
- **保持原文所有事实**——不增删数据/案例/逻辑
- **保留 markdown 格式**——不要把 `**粗体**` 翻译掉
- 中英文混排时确保空格规范

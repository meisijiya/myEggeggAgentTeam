---
name: baoyu-diagram
description: 绘制专业 SVG 图表。触发场景：用户要求画流程图、架构图、审批流、时序图、组织结构图、状态机、思维导图、ER 图、UML 类图、数据流图、决策树、网络拓扑、税务申报流程、报销流程、内控架构等任何结构/逻辑/流程的视觉化。也包括 "画个图" "画一个架构图" "draw me a diagram" "flowchart" "sequence diagram" "画流程" 等说法。输出单一自包含的 .svg 文件。
version: 1.0.0
---

# SVG 图表生成器

根据用户需求生成**单一自包含的 `.svg` 文件**。设计风格为深色主题（slate-900 背景 + 网格），所有元素直接写在 SVG 里，无需外部依赖（仅可选用 Google Fonts 引用）。

## 支持的图表类型

| 类型 | 适用场景 |
|---|---|
| **Architecture** | 系统组件关系、前后端分层、区域边界 |
| **Flowchart** | 决策逻辑、流程步骤（**会计常用**：审批流、税务申报、报销流程） |
| **Sequence** | 时序交互（多角色/系统之间的调用） |
| **Structural** | 类图、ER 图、组织结构、UML |
| **Mind Map** | 头脑风暴、主题展开 |
| **Timeline** | 时间轴、里程碑 |
| **Illustrative** | 概念说明、对比、可视化隐喻 |
| **State Machine** | 状态转换、生命周期 |
| **Data Flow** | 数据加工管道（输入→处理→存储） |

## 设计系统

### 配色（语义化）

| 类别 | 填充 rgba | 描边色 | 用途 |
|---|---|---|---|
| Primary | `rgba(8, 51, 68, 0.4)` | `#22d3ee` 青 | 前端、用户面、输入 |
| Secondary | `rgba(6, 78, 59, 0.4)` | `#34d399` 翠 | 后端、服务、处理 |
| Tertiary | `rgba(76, 29, 149, 0.4)` | `#a78bfa` 紫 | 数据库、存储、持久化 |
| Accent | `rgba(120, 53, 15, 0.3)` | `#fbbf24` 琥珀 | 云、基础设施、区域 |
| Alert | `rgba(136, 19, 55, 0.4)` | `#fb7185` 玫红 | 安全、错误、警告 |
| Connector | `rgba(251, 146, 60, 0.3)` | `#fb923c` 橙 | 消息总线、队列、中间件 |
| Neutral | `rgba(30, 41, 59, 0.5)` | `#94a3b8` 石板 | 外部、通用、未知 |
| Highlight | `rgba(59, 130, 246, 0.3)` | `#60a5fa` 蓝 | 当前步骤、激活态、焦点 |

流程图/时序图按**角色**（actor/decision/process）配色，不按技术。

### 字体

```svg
<style>
  @import url('https://fonts.googleapis.com/css2?family=JetBrains+Mono:wght@400;500;600;700&display=swap');
  text { font-family: 'JetBrains Mono', 'SF Mono', 'Cascadia Code', monospace; }
</style>
```

中文字符处理：加 `'Noto Sans SC', 'PingFang SC', sans-serif`，并加宽 box（CJK 字符更宽）。

字号规范：
- 标题：16px / 700
- 组件名：11-12px / 600
- 子标签：9px / 400 / `#94a3b8`
- 注释：8px / 400
- 箭头标签：7-8px

### 背景 + 网格

```svg
<defs>
  <pattern id="grid" width="40" height="40" patternUnits="userSpaceOnUse">
    <path d="M 40 0 L 0 0 0 40" fill="none" stroke="#1e293b" stroke-width="0.5"/>
  </pattern>
</defs>
<rect width="100%" height="100%" fill="#0f172a"/>
<rect width="100%" height="100%" fill="url(#grid)"/>
```

### 箭头标记

```svg
<marker id="arrow" markerWidth="10" markerHeight="7" refX="9" refY="3.5" orient="auto">
  <polygon points="0 0, 10 3.5, 0 7" fill="#64748b"/>
</marker>
```

需要彩色箭头时按颜色复制（如 `arrow-cyan` 用 `#22d3ee`）。

## 核心组件模板

### 矩形（服务/流程节点）

```svg
<!-- 遮罩层：不透明背景隐藏下方的箭头 -->
<rect x="100" y="100" width="160" height="60" rx="6" fill="#0f172a"/>
<!-- 视觉层：半透明填充 + 描边 -->
<rect x="100" y="100" width="160" height="60" rx="6" fill="rgba(8,51,68,0.4)" stroke="#22d3ee" stroke-width="1.5"/>
<text x="180" y="125" fill="white" font-size="11" font-weight="600" text-anchor="middle">节点名</text>
<text x="180" y="141" fill="#94a3b8" font-size="9" text-anchor="middle">描述</text>
```

**关键**：必须有遮罩层（不透明 #0f172a），否则半透明填充会让下方箭头透出来。

### 决策菱形（流程图）

```svg
<g transform="translate(CX, CY)">
  <polygon points="0,-35 50,0 0,35 -50,0" fill="#0f172a"/>
  <polygon points="0,-35 50,0 0,35 -50,0" fill="rgba(120,53,15,0.3)" stroke="#fbbf24" stroke-width="1.5"/>
  <text y="4" fill="white" font-size="10" font-weight="600" text-anchor="middle">条件?</text>
</g>
```

出口箭头标注 "是/否"（或 "Yes/No"）。

### 数据库圆柱

```svg
<g transform="translate(X, Y)">
  <rect x="0" y="10" width="120" height="50" rx="2" fill="#0f172a"/>
  <ellipse cx="60" cy="10" rx="60" ry="12" fill="#0f172a"/>
  <ellipse cx="60" cy="60" rx="60" ry="12" fill="#0f172a"/>
  <rect x="0" y="10" width="120" height="50" fill="rgba(76,29,149,0.4)"/>
  <ellipse cx="60" cy="10" rx="60" ry="12" fill="rgba(76,29,149,0.4)" stroke="#a78bfa" stroke-width="1.5"/>
  <ellipse cx="60" cy="60" rx="60" ry="12" fill="rgba(76,29,149,0.4)" stroke="#a78bfa" stroke-width="1.5"/>
  <line x1="0" y1="10" x2="0" y2="60" stroke="#a78bfa" stroke-width="1.5"/>
  <line x1="120" y1="10" x2="120" y2="60" stroke="#a78bfa" stroke-width="1.5"/>
  <text x="60" y="40" fill="white" font-size="11" font-weight="600" text-anchor="middle">DB Name</text>
</g>
```

### 区域边界（分组）

```svg
<rect x="X" y="Y" width="W" height="H" rx="12" fill="none" stroke="#fbbf24" stroke-width="1" stroke-dasharray="8,4"/>
<text x="X+12" y="Y+16" fill="#fbbf24" font-size="9" font-weight="600">区域名</text>
```

### 安全组（嵌套边界）

```svg
<rect x="X" y="Y" width="W" height="H" rx="8" fill="none" stroke="#fb7185" stroke-width="1" stroke-dasharray="4,4"/>
<text x="X+10" y="Y+14" fill="#fb7185" font-size="8" font-weight="500">VPC / Security Group</text>
```

## 布局规范（避免重叠）

- 组件高度：50-70px（标准），80-120px（复杂）
- 组件间距：垂直 ≥40px，水平 ≥30px
- 箭头标签：距 box 边缘 ≥10px
- 区域边界内边距：20px
- viewBox：所有内容 + 30px padding（不设固定 width/height，让 SVG 响应式缩放）
- 标题块：左上角，距顶 20px
- 图例：右下角或底部，至少 20px 距最低元素

## 各类型布局要点

### 流程图（会计最常用）
- 主流程：自顶向下
- 决策菱形：出口箭头标注 "是/否"
- 起止节点：圆角矩形（用 Highlight 颜色突出 happy path）

### 架构图
- 流向：自左向右或自顶向下
- 相关服务用区域边界圈起来
- 数据库放底部或右侧
- 服务间用总线/中间件连接

### 时序图
- Actor 在顶部（方框）
- Lifeline：垂直虚线
- 消息箭头：水平（实线=同步、虚线=返回）
- 时间向下
- 复杂情况给消息编号

### 类图/结构图
- 分隔框：上=类名 / 中=属性 / 下=方法
- 关系线：实线+实心菱形=组合、实线+空心菱形=聚合、虚线箭头=依赖、实线+三角=继承

### 思维导图
- 中心节点向外辐射
- 用三次贝塞尔曲线画有机分支
- 不同分支用不同配色
- 字号随层级递减

### 时间线
- 水平或垂直主轴线
- 事件标记：圆/菱形
- 描述文字在轴线两侧交替（避免重叠）
- 用颜色分类事件类型

### 状态机
- 状态：圆角矩形（复合状态双边框）
- 初始：实心圆 / 终止：靶心
- 自转换：用曲线箭头
- 转换标签格式：`event [guard] / action`

### 数据流图
- 流程：圆角矩形
- 数据存储：圆柱
- 外部实体：方框
- 数据流：带标签的箭头

## 输出规则

1. **单一自包含 `.svg` 文件**——只引用 Google Fonts，不引外部资源
2. 设 `viewBox` 适配内容 + 30px padding；**不**设固定 width/height（响应式）
3. 根 `<svg>` 标签必须有 `xmlns="http://www.w3.org/2000/svg"`
4. `<style>` / `<defs>` / markers / patterns 全部放在 SVG 顶部
5. 用 `text-anchor="middle"` 居中文本
6. 中文字符：font-family 加 `'Noto Sans SC', 'PingFang SC'`，box 加宽
7. **保存位置**：
   - 输入是文件 → `{输入文件目录}/diagram/`
   - 输入是文本/对话 → `{项目目录}/diagram/{主题slug}/`
   - 目录不存在则创建

## 生成流程

1. **识别图表类型**：从用户描述判断（"审批流"→Flowchart，"系统组件"→Architecture，"用户-系统交互"→Sequence...）
2. **规划布局**：列出所有节点、确定分组和流向、计算坐标
3. **按 z-order 写 SVG**：
   - 背景填充 + 网格
   - 区域/分组边界（虚线）
   - 连接箭头和线
   - 遮罩层（不透明 #0f172a）覆盖组件位置
   - 组件 box（半透明 + 描边）
   - 文字标签
   - 图例（右下角）
   - 标题块（左上角）
4. **校验**：间距不重叠、图例不压边界、viewBox 够大
5. **写文件**：用 Write 工具保存 .svg
6. **汇报**：告诉用户文件路径，如果需要 PNG 转换（可选）

## PNG 转换（可选）

如需 PNG（PPT/Word 嵌入用），优先用系统 rsvg-convert（轻量）：

```bash
rsvg-convert -w 2400 input.svg -o output.png
```

或用 ImageMagick：

```bash
convert -density 200 input.svg output.png
```

如果都没装，告诉用户安装 `librsvg2-bin`：

```bash
sudo apt install librsvg2-bin
```

## 重要提示

- **不要调用任何外部 AI 模型**（图像/视频 API）——这是纯 SVG 绘制，LLM 自己写代码
- **不要省略遮罩层**——半透明 box 漏箭头是常见错误
- **不要把标题放在视图内**——标题块在左上角，viewBox padding 已经算好
- 中文字符务必测试渲染——CJK 字符宽度跟 ASCII 差异大

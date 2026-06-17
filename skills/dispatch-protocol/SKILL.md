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

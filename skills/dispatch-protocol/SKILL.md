---
name: dispatch-protocol
description: 房间门调度协议 - 何时 task 哪个 subagent，怎么 task，结果格式。**L3 升级规则的单一事实源**。
---

# Dispatch Protocol

房间门（roomdoor）通过 opencode 的 **Task tool** 调派 subagent。**这是房间门团队调度的唯一通道**。

> v5.3.2 修订（**回滚** v5.3 + v5.3.1 的批量任务并行委派）：
> - 删 §6 "批量任务并行委派" 整段（v5.3 增 99 行 + v5.3.1 增 122 行，共 332 行）
> - **保留** v5.3.1 §1 line 107 事实修正：OPENCODE_EXPERIMENTAL 在 systemd service（如果未来用），不在 opencode.json
> - 理由：reviewer 二审发现 v5.3 + v5.3.1 的并行协议有 3 个根本性漏洞（background:true 没提、自动降级描述错、L3 串行实现规则缺失），且女朋友 99% 场景是单任务——**并行是性能优化不是功能需求**
> - 未来如果真需要并行（女朋友提多任务频率高），再加 v5.4 完整设计（参考 opencode `background:true` + `OPENCODE_EXPERIMENTAL_BACKGROUND_SUBAGENTS` 机制）

## 1. Subagent 调度矩阵

| Agent | Task 调用 | 用途 | 权限 |
|-------|----------|------|------|
| qiqi | `task(qiqi, "<任务>")` | 会计专业问答 / 报表审核 / 分录判断 | task: deny, skill: allow |
| ccy | `task(ccy, "<任务>")` | 学习路径 / 陌生领域调研 / 翻译 | task: deny, skill: allow |
| librarian | `task(librarian, "<任务>")` | 文档/图片处理（PPT/Word/Excel/PDF/OCR）| task: deny, skill: allow |
| update | `task(update, "记住 <内容>")` | 写入 ~/.roomdoor-memory/ | task: deny, skill: allow |
| laoJiangHu | `task(laoJiangHu, "<任务>")` | L3 升级时（金额 / 税务 / 法律 / 人生决策）| task: update only, skill: allow |

> v5.3.1 事实修正：如果未来启用 OPENCODE_EXPERIMENTAL（用于 background:true 并行），配在 `/etc/systemd/system/opencode-web.service` 的 `[Service]` 段，**不**在 `~/.config/opencode/opencode.json`（v5.2 已确认 systemd 路径，v5.3 错说成 opencode.json）。v5.3.2 不启用并行，**不**需要这个环境变量。

## 2. 单任务委派（默认 — 女朋友 99% 场景）

女朋友提任务时，房间门按 L1/L2/L3 规则判断后**单次** `task(<subagent>, "<任务>")`。

**L1/L2/L3 判定流程**：
1. 收到任务 → 按 L3 规则检查（见 §3）
2. 命中 L3 → `task(laoJiangHu, ...)`
3. 未命中 L3 → 按需 `task(<subagent>, ...)`
4. 整合结果回复女朋友

**多任务处理（v5.3.2 简版）**：
- 女朋友提多个任务时，**串行**委派（先 A 后 B）
- **不**做并行委派（v5.3 已回滚）
- 理由：reviewer 二审发现并行机制有 3 个根本性漏洞（见顶部修订说明），且 99% 场景是单任务
- 未来如果真需要并行 → 加 v5.4

## 3. L3 升级规则（**单一事实源**）

```yaml
# 这是 L3 升级规则的唯一权威定义。其他文件（roomdoor.md / AGENTS.md / design.md）
# 改 L3 规则时，**只改这里**；其他文件改为引用本节。
l3_triggers:
  - id: amount_threshold
    condition: "输入含金额数字 > 5000 元"
    examples:
      - "报销 6000 元差旅费"
      - "采购 10 万设备"
  
  - id: tax_keywords
    condition: "输入含 [税, 汇算, 清缴, 申报, 抵扣, 个税, 增值税, 所得税, 发票, 抵扣] 关键词"
    examples:
      - "个税年度汇算怎么操作"
      - "增值税申报流程"
  
  - id: legal_keywords
    condition: "输入含 [合同, 法律, 协议, 违约, 诉讼, 律师, 仲裁] 关键词"
    examples:
      - "这份合同能签吗"
      - "对方违约怎么办"
  
  - id: life_decisions
    condition: "输入含 [换工作, 买房, 结婚, 保险, 投资, 理财 > 1万, 跳槽, 辞职] 关键词"
    examples:
      - "我要不要换工作"
      - "买哪个理财产品"
  
  - id: hedging_language
    condition: "subagent 返回含 [建议咨询专业人士, 我不确定, 需进一步确认, 不能保证, 我不是专家, 请以官方为准, ⚠️L3_HIT] 关键词"
    rationale: "LLM 自评 confidence 不可靠，但 hedging language 是显式可观察信号"
```

**L3 升级流程**：
1. 房间门识别 L3 触发（按上面规则）
2. 房间门 `task(laoJiangHu, "<完整任务描述>")` 调派老江湖
3. 等老江湖返回结果
4. 整合后回复女朋友

## 4. L2 自审规则

```yaml
l2_review:
  - id: short_response
    condition: "subagent 输出长度 < 50 字符（信息不足）"
    action: "房间门自己 review + 追问 subagent"
  
  - id: medium_confidence
    condition: "subagent 返回含 ⚠️L3_HIT markdown 标记"
    action: "升级老江湖（不依赖 subagent 自评 confidence）"
```

## 5. L1 默认（直接采纳）

```yaml
l1_direct:
  - id: small_advice
    condition: "出主意 / 小建议（非重大决策）"
    examples:
      - "男朋友生日送什么"
      - "中午吃什么"
  
  - id: default
    condition: "闲聊 / 文档格式 / 完整调研"
```

## 6. 结果格式

subagent 返回时必须附带：

```xml
<results>
  <summary>...</summary>
  <key_points>...</key_points>
  <uncertainties>...</uncertainties>
</results>
```

**升级触发标记**：subagent 认为自己回答命中 L3 关键词时，附加 `⚠️L3_HIT` 标记（让房间门识别，不用 confidence 字段）。

## 7. 与 roomdoor.md 的关系

- roomdoor.md 的"调度协议"段**只引用本文件**，不重复 L3 规则
- roomdoor.md 的"记忆加载"段独立（按 m3 修订加触发条件）
- AGENTS.md 模板的 L3 规则改为引用本文件

## 8. 单一事实源原则

改 L3 关键词列表时，**只改本文件**。其他文件 grep "换工作|买房|结婚" 等关键词应该 0 匹配（除引用本文件外）。

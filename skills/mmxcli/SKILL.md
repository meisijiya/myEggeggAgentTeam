---
name: mmxcli
description: 通过 mmx CLI 调用 MiniMax 多模态能力（**主**用：search 上网搜索；**次**用：vision 识图兜底；**辅**用：image/video/audio 生成）。房间门当前模型 `opencode/deepseek-v4-flash-free` **不**支持原生多模态，**用 mmx vision 兜底**。所有 mmx 调用会上传内容到 MiniMax API（隐私披露在 SKILL.md）。
---

# mmxcli

通过 `mmx` CLI 调 MiniMax 多模态能力。

## v5.3.4-7 关键设计

房间门当前模型 `opencode/deepseek-v4-flash-free` **不**支持原生多模态：
- ✅ **主**用 mmx search（**补** M3 网络能力）
- ✅ **次**用 mmx vision（**补** M3 多模态识图能力）—— **v5.3.4-7 修订**重**新**启用
- ✅ **辅**用 mmx image / video / audio generate（**不**常**用**，但**保**留）

如**果** roomdoor **改**回 M3（**有**多模态）：
- mmx vision **可**省**略**（M3 原生支持）
- mmx search 仍**用**（M3 **没**网络）

## 触发场景

- 房间门**当**前模型（deepseek-flash）**不**支持**原**生**多**模**态**识**图**时
- 用**户**问"**会**计**政**策 / **税**法 / 行业**标**准"等**网**上**资**料
- **需**要生成**图**片 / 视频 / 语**音**（女朋友偶**尔**要**广**告**图**）
- **查**配额 / **认**证**状**态

## 安装

```bash
# 用户机器（mmx-cli v1.0.16，**不**是空包 "mmx"）
npm install -g mmx-cli

# 认证（OAuth 流，需**浏**览器）
mmx auth login

# 验证
mmx --version  # mmx 1.0.x
mmx quota      # 查配额
```

## 子命令速查

| 子命令 | 用途 | 房间门场景 |
|--------|------|----------|
| `mmx search <query>` | **网**搜索（**主**用）| **查**资**料** / 政策 / 法规 |
| `mmx vision describe <image>` | **识**图（**次**用）| 房间门**当**前模型**不**支持多模态时**兜**底 |
| `mmx image generate <prompt>` | 生成**图**（**辅**用）| 女朋友**广**告**图** |
| `mmx video generate <prompt>` | 生成**视**频 | （**极**少用）|
| `mmx speech synthesize <text>` | 文本**转**语**音** | （**极**少用）|
| `mmx music generate` | 生成**音**乐 | （**极**少用）|
| `mmx quota` | 查**配**额 | **避**免**超**额 |
| `mmx auth status` | 查**认**证**状**态 | login 后**验**证 |

## 典型用法

### 1. 上网搜索（最常用）

```bash
# 基本搜索
mmx search "2026 年增值税申报新规"

# 中文搜索（**推**荐）
mmx search "中国 个人所得税 年度汇算清缴 2026"

# JSON 输**出**（**结**果**易** parse）
mmx search "会计政策 2026" --output json

# **指**定**区**域（global / cn）
mmx search "test" --region cn
```

**输出**格式：JSON `{"organic": [{"title", "link", "snippet", "date"}]}`。

### 2. 识图（兜底当前模型不支持多模态）

```bash
# 单图
mmx vision describe ~/workSpace/inbox/发票_2026-06-17.jpg

# 简写（mmx-cli 1.0.16）
mmx vision photo.jpg
```

**输出**：自然语言**描**述（"这张图**片**显**示** ..."）。

**何时用** vs **何时委派 librarian**：

| 场景 | 用什么 |
|------|-------|
| 1 张图 | roomdoor **自**己**调** mmx vision（**快**）|
| 2-4 张图 | 房**间**门调 mmx vision **批**量**调**用 |
| 5+ 张图 | **委**派 librarian（librarian 用 M3，**可**批**处**理） |

### 3. 图片生成

```bash
# 生成图片
mmx image generate "现代风格办公室，落地窗，下午阳光"

# JSON 输出（拿 URL）
mmx image generate "阳光办公室" --output json
```

**输出**：JSON 含 URL（**下**载后**存**到 `~/workSpace/outbox/`）。

### 4. 配额检查

```bash
# **生**成**图**片
mmx image generate "现代风格办公室，落地窗，下午阳光"

# JSON 输**出**（拿 URL）
mmx image generate "阳光办公室" --output json
```

**输出**：JSON 含 URL（**下**载后**存**到 `~/workSpace/outbox/`）。

### 4. 配额**检**查

```bash
# 看**剩**余配额
mmx quota

# JSON 输**出**
mmx quota --output json
```

**重要**：**每**次 mmx 调**用**消耗配额——**使**用**前**先 `mmx quota` 看**剩**余。

## 隐私披露（**重**要）

- ⚠️ **所**有 mmx 调**用**（search / vision / image / video / audio）**都**会**上**传**到 MiniMax API
  - global 区域：`api.minimax.io`
  - cn 区域：`api.minimaxi.com`
- ⚠️ mmx search 把**你**的**查**询**问**题**上**传**到 MiniMax 服务**器**
- ⚠️ **mmx vision 把**你**的**图**片**文**件**上**传**到 MiniMax 服务**器**（**敏**感图**片**如身份**证** / **银**行**卡**截**图** 风**险**最**高**）
- ⚠️ mmx image generate 把**你**的**图**像**描**述**（prompt）**上**传**到 MiniMax
- ⚠️ **建**议**敏**感**问**题**不**用 mmx search（**例**如**个**人**信**息 / **商**业**机**密 / **未**公开**财**务**数**据**）
- ⚠️ **建**议**敏**感 prompt **不**用 mmx image generate
- ⚠️ **建**议**敏**感**图**片**不**用 mmx vision

## 限**制**与**注**意

- ❌ **不**支持中文文件名（**路**径**含**中文**可**能**报**错）——**用** UUID / 英文**名**字
- ⚠️ mmx auth login **需**要 OAuth 流——**需**要**浏**览器
- ⚠️ `mmx vision` **对**乱**码** / 模**糊**图**片**效果**一**般——提示用户**重**新**拍**照
- ⚠️ 配额**有**限——**避**免**频**繁**调**用**（**搜**索**一**次**计**一**次** / 识**图**一**次**计**一**次**）

## 失败**排**查

| **现**象 | **原**因 | **修**复 |
|---------|--------|---------|
| `No credentials found` | **没** login | `mmx auth login` |
| `No quota remaining` | 配额**用**完 | **等**下**个**计**费**周**期** |
| 搜**索**无结**果** | query **太**特**殊** | 改**用**更**通**用**的**关键词 |
| image generate **返**回**空** | prompt **被**安全**过**滤 | 改 prompt |

## 房间门使用**建**议**

| **场**景 | **建**议 |
|---------|--------|
| 女友**友**问"2026 **个**税**申**报**新**规" | 房间门 bash: `mmx search "2026 个税申报新规"` |
| 女友**友**发**发**票**照**片（**1-4** **张**）| 房间门 bash: `mmx vision describe <image>` |
| 女友**友**发**发**票**照**片（5+ **张**）| **委**派 librarian：task(librarian, "识图批处理 <图**片**列**表>") |
| 女友**友**要**广**告**图** | 房间门 bash: `mmx image generate "..."` |

## 关键约束

- **路径白名**单：mmx vision 的**图**片路**径**应**在** `~/workSpace/inbox/` `outbox/` `projects/`
- mmx search **不**接**文**件**路**径**—— **只**接 query
- **不**允许 `~/.roomdoor-memory/` ——**隐**私**内**容
- **不**允许 `~/.ssh/` `~/.aws/` `~/.config/` ——**敏**感**配**置
- mmx image generate **不**接**图**片**文**件**—— **只**接 prompt
- **路**径**白**名**单**适**用**于** mmx vision**识**图**，mmx search/image generate **只**用 prompt

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

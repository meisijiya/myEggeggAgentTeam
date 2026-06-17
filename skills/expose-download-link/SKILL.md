---
name: expose-download-link
description: 暴露文件下载链接 — 把文件复制/链接到 ~/workSpace/public/，通过 nginx 12121 端口的临时 URL 让用户下载。**严格隔离**：只暴露 public/ 目录的文件名，nginx autoindex off，禁止 .. 路径遍历。
---

# Expose Download Link

通过 nginx 反向代理 + 严格路径白名单，给用户**临时下载链接**。

## 核心原则（v5.3.4-4 用户硬性要求）

> ⚠️ **切记**：不能通过 12121 端口浏览文件系统。所有文件**不能**都暴露到公网。

**安全约束**：
1. nginx `autoindex off`（**不**列目录）
2. nginx `root` 指向**单一**目录 `~/workSpace/public/`
3. nginx `try_files $uri =404`（**不**解析 `..`）
4. LLM **不**能直接调 nginx reload（**必须**通过本 skill）
5. LLM **不**能修改 nginx config（**只**能创建 public/ 下的 symlink）

## 触发场景

- LLM 创建了文件（PPT/Excel/Word/报告/PDF）
- 用户说"我需要下载" / "暴露链接" / "分享" / "发给我"
- 用户问"我刚才的 PPT 在哪"

**不**触发：
- 单纯说"做好了"——**先**问用户
- 内部文件（如 ~/.roomdoor-memory/active/foo.md）——**不**暴露
- 临时文件（~/workSpace/temp/）——**不**暴露

## 操作流程

### Step 1: 用户确认

LLM **必须**问用户："需要通过临时下载链接分享吗？" 等用户**明确**确认再执行。

### Step 2: 生成 token + **复制**文件（不**用** symlink）

> **v5.3.4-4 修订**：nginx 默认 `disable_symlinks on`（**不**跟 symlink）。**用** `cp` 不用 `ln -s` 更**安全**（nginx **不**解析 symlink，**不**会**链**到**外**部文件）。

```bash
# 1. 生成 32 字符 random token（无 - 字符，避免 nginx 解析问题）
TOKEN=$(head -c 16 /dev/urandom | xxd -p)

# 2. 源文件路径（必须是 ~/workSpace/outbox/ 或 ~/workSpace/projects/ 下的文件）
SOURCE="$1"  # 如 /home/ubuntu/workSpace/outbox/2026-06-17_报告.docx

# 3. 验证源文件在工作目录（防止任意路径泄露）
case "$SOURCE" in
    /home/ubuntu/workSpace/outbox/*|/home/ubuntu/workSpace/projects/*|/home/ubuntu/workSpace/inbox/*)
        ;;
    *)
        echo "❌ 源文件必须 ~/workSpace/ 下的 outbox/projects/inbox"
        exit 1
        ;;
esac

# 4. 验证源文件存在 + 是普通文件（不是目录、不是 symlink）
if [ ! -f "$SOURCE" ] || [ -L "$SOURCE" ]; then
    echo "❌ 源文件必须存在 + 是普通文件 + 不是 symlink"
    exit 1
fi

# 5. 复制到 public/（**不**用 symlink，更**安全**）
cp -p "$SOURCE" ~/workSpace/public/"$TOKEN"
chmod 644 ~/workSpace/public/"$TOKEN"
```

### Step 3: 返回 URL

```
✅ 暴露链接已生成：

📎 文件名：2026-06-17_报告.docx
🔗 URL：http://<CLOUD_SERVER_IP>:12121/<token>
⏰ 链接：nginx 会话期间有效（重启 / 清理 public/ 后失效）
```

### Step 4: 清理（用户可要求）

```bash
rm ~/workSpace/public/<token>
```

## Nginx 配置（运维层面）

`/etc/nginx/conf.d/roomdoor-public.conf`:

```nginx
server {
    listen 12121;
    server_name _;
    
    # 严格安全配置
    autoindex off;
    
    # 唯一暴露目录
    root /home/ubuntu/workSpace/public;
    
    # 默认拒绝所有
    location / {
        try_files $uri =404;
    }
    
    # 隐藏 nginx 版本
    server_tokens off;
}
```

**重载**：`sudo nginx -s reload`

## 已知限制

- ❌ **不**支持中文文件名（symlink 没问题，但 URL 字符需 URL-encode）
- ❌ **不**支持目录下载（只支持单文件）
- ❌ **不**支持断点续传（HTTP Range）—— 女友场景不需要
- ❌ **不**支持密码保护（**靠** token 隐式保护——32 字符 random 足够强）

## 故障排查

| 现象 | 原因 | 修复 |
|------|------|------|
| 404 | symlink 不存在 | `ls -la ~/workSpace/public/` |
| 403 | nginx 权限问题 | `sudo nginx -T | grep "12121"` |
| 502 | nginx 没起 | `sudo systemctl status nginx` |
| symlink 死链 | 源文件被删 | `readlink -f <token>` |

## 与 roomdoor.md 的关系

- **触发**：roomdoor LLM 读完本 skill 知道何时调
- **不**直接调：roomdoor 调 LLM agent 写文件 → roomdoor **问**用户 → 用户确认 → roomdoor 调 bash **执行** symlink + 返回 URL
- **不**改 AGENTS.md 规则：本 skill 内容**已经**在 roomdoor prompt 引用

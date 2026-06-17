# 安全配置（v5.3.4-11 引入）

## 原则

**所有敏感信息不在 git 历史中 commit**。代码和文档使用**占位符**，部署时手动替换为实际值。

## 占位符清单

| 占位符 | 含义 | 替换为（示例）|
|--------|------|------------|
| `<CLOUD_SERVER_IP>` | 云服务器公网 IP | `42.x.x.x`（你的服务器 IP）|
| `<WEB_USERNAME>` | opencode web 认证用户名 | 你自己设置（如 `ljh`）|
| `<WEB_PASSWORD>` | opencode web 认证密码 | 强密码（如 16+ 字符）|
| `<SSH_KEY_FILENAME>` | SSH 私钥文件名 | `your-key.pem` |
| `<SSH_KEY_PATH>` | SSH 私钥完整路径 | `~/.ssh/your-key.pem` |

## 替换占位符

部署前，运维人员需把占位符替换为实际值。**不要**在 commit 中包含实际值。

### 1. 替换 systemd service 文件

`/etc/systemd/system/opencode-web.service`：

```ini
Environment=OPENCODE_SERVER_USERNAME=<WEB_USERNAME>
Environment=OPENCODE_SERVER_PASSWORD=<WEB_PASSWORD>
```

替换为：

```ini
Environment=OPENCODE_SERVER_USERNAME=your-username
Environment=OPENCODE_SERVER_PASSWORD=YourStrongPassword123!
```

### 2. SSH 部署命令

```bash
# 本地
scp -i <SSH_KEY_PATH> agents/*.md ubuntu@<CLOUD_SERVER_IP>:~/.config/opencode/agents/
```

替换为：

```bash
scp -i ~/.ssh/your-key.pem agents/*.md ubuntu@42.x.x.x:~/.config/opencode/agents/
```

## 敏感信息清单（v5.3.4-11 起每次部署都检查）

- [ ] opencode web 用户名/密码（systemd Environment）
- [ ] 云服务器 IP（文档和脚本中的 `<CLOUD_SERVER_IP>`）
- [ ] SSH 私钥路径（`<SSH_KEY_PATH>` / `<SSH_KEY_FILENAME>`）
- [ ] mmx-cli OAuth 凭据（`~/.mmx/config.json`，**不**进 git）
- [ ] mmx-cli API key（如果有，**不**进 git）

## 部署前 checklist

1. `grep -r "42\|10\." --include="*.md" --include="*.sh"` 应**无**真实 IP（**只**有占位符）
2. `grep -r "<WEB_USERNAME>\|<WEB_PASSWORD>" --include="*.md" --include="*.sh"` 应**无**真实用户名/密码
3. `git log --oneline | grep -E "password|secret|token|key"` 应**无**敏感关键词
4. `git status` 应**无**待 commit 的占位符替换

## 紧急情况

如果**意外** commit 了敏感信息：

```bash
# 1. 立即修改密码/密钥
# 2. 用 git filter-repo 清理历史
git filter-repo --path docs/operations.md --invert-paths
git filter-repo --replace-text expressions.txt  # 替换敏感内容
git push --force  # 如果有远程仓库
# 3. 重新部署
```

## 为什么不用环境变量

- systemd Environment 已在用（OPENCODE_SERVER_USERNAME/PASSWORD）
- 但 ops 脚本（ops-start.sh 等）为了**运维人员**直接查看方便，**硬编码**了配置
- **未来 v5.5+** 计划：把 ops 脚本的硬编码改成读取 `~/.config/opencode/.env` 文件

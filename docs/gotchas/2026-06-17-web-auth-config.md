# 2026-06-17 — systemd 服务密码明文暴露在命令行参数

> **status**: ACTIVE
> **avoidability_score**: 5
> **category**: security

## 症状

之前 MiniMax 多 Agent 部署时，在 SCREEN 会话中通过命令启动 opencode：

```bash
OPENCODE_SERVER_USERNAME=<WEB_USERNAME> OPENCODE_SERVER_PASSWORD=<WEB_PASSWORD> opencode web --port 8080
```

SSH 后用 `ps aux | grep opencode`——所有环境变量明文出现在进程列表里（任何能跑 `ps` 的用户都能看到密码）。

## 根因

**Linux `/proc/PID/environ` 和 `ps aux` 会暴露启动进程时的所有环境变量**。在命令行（shell 前缀赋值）设置敏感信息等于公开密码。这不是 opencode 的安全问题，是 Linux 进程隔离的基本知识。

## 修复

使用 systemd unit 的 `[Service]` 段通过 `Environment=` 设置敏感变量——不走命令行：

```ini
[Service]
Environment=OPENCODE_SERVER_USERNAME=<WEB_USERNAME>
Environment=OPENCODE_SERVER_PASSWORD=<WEB_PASSWORD>
ExecStart=/usr/local/bin/opencode web --port 8080
```

更安全的做法：使用 `EnvironmentFile=/etc/opencode-secrets.env`，权限 `600`。

## 触发场景

任何时候在 Linux 服务器上通过命令行启动带密码/API key/token 的服务：

- `VAR=value command`（当前 shell 暴露）
- SCREEN / tmux 中 `export VAR=value && command`
- Docker `-e` 参数（`docker inspect` 可见）

## 预防步骤

1. **绝不**在命令行前缀/export 中放敏感信息
2. 使用 systemd `Environment=` 或 `EnvironmentFile=`（权限 600）
3. 使用 Docker secrets（swarm mode）或 Kubernetes secrets
4. 部署后检查：`ps aux | grep opencode` 不应看到密码
5. review checklist 加一条：**ssh/secrets 是否通过安全通道传递**

## 教训

敏感信息（密码/API key/token）必须用 systemd `EnvironmentFile=` 或独立 secret 文件，**绝对不要进命令行参数**。`ps aux` 可见就不是秘密。

## 验证

```bash
ps aux | grep opencode
# 输出不应包含 OPENCODE_SERVER_USERNAME 或 OPENCODE_SERVER_PASSWORD
# 应只显示 opencode web --port 8080
```

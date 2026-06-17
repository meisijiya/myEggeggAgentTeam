---
status: accepted
date: 2026-06-17
---

# ADR-0001: 选择 opencode web + Cloudflare Tunnel 作为远程访问方案

## Context and Problem Statement

房间门团队部署在云服务器上，需要让用户（女朋友，不懂技术）通过浏览器远程访问。需要解决：1) 无公网 IP 的云服务器外部访问；2) 零配置 UX（用户只需点链接）；3) 不需要维护额外 VPN / 跳板机。

## Considered Options

1. **opencode web + Cloudflare Tunnel**（选择）—— opencode 自带 web 模式（--port），配合 Cloudflare Tunnel 对外暴露。
   - ✅ Pro: opencode 原生支持，无额外中间层
   - ✅ Pro: Cloudflare Tunnel 免公网 IP，自带 DNS + 登录认证
   - ✅ Pro: 零配置 UX——用户只记一个 URL
   - ❌ Con: 依赖 cloudflared 客户端版本兼容性
   - ❌ Con: Cloudflare Tunnel 到 opencode web 之间无额外加密（但走 HTTPS 到 CF）

2. **NGINX 反向代理 + Let's Encrypt**
   - ✅ Pro: 成熟方案，文档丰富
   - ❌ Con: 需要公网 IP；需要证书管理；多了 NGINX 维护成本

3. **frp (fast reverse proxy)**
   - ✅ Pro: 内网穿透方案
   - ❌ Con: 需要公网中转服务器（又一台）；配置复杂；不适合非技术用户

4. **直接 SSH 端口转发**
   - ✅ Pro: 无需额外服务
   - ❌ Con: 需要用户 SSH 客户端；clientside 配置门槛高

## Decision Outcome

Chosen: "**opencode web + Cloudflare Tunnel**", 因为与 opencode 深度集成，最小化外部依赖，且对最终用户完全透明——一个浏览器 URL 即可访问。

### Consequences

- ✅ 部署简化——systemd 启动 opencode web + cloudflared 两个服务即可
- ✅ 用户侧零配置——只需浏览器
- ✅ Cloudflare Tunnel 自带仪表盘查看连接状态
- ❌ 依赖 cloudflared apt 源——需要匹配 Ubuntu 版本代号（`noble` vs `focal`）
- ❌ 如果用户在中国大陆，Cloudflare 可能被干扰——需要备选方案（见 follow-up）

## Follow-up

- 监控中国大陆访问稳定性；如有问题，添加备选 SSH 端口转发方案
- 确保 `deployment.md §6` 中 Cloudflare apt 源使用 `noble`（匹配 Ubuntu 24.04）

# 房间门 Agent 团队

OpenCode 6-Agent team designed for a non-technical accounting user (girlfriend).

## Quick Start

```bash
# 1. Clone
git clone <repo>
cd myEggeggAgentTeam

# 2. Install (云服务器)
bash scripts/install.sh

# 3. Configure opencode.json
#    Reference: §5.1 of design doc
#    Each agent needs model + fallback_model

# 4. Start opencode web
opencode web --port 8080

# 5. Expose via Cloudflare Tunnel
cloudflared tunnel create roomdoor
# See docs/deployment.md for details
```

## Architecture

6 Agents:
- **roomdoor (房间门)** - main + dispatcher, office butler
- **veteran (老江湖)** - main 次入口, technical backup
- **qiqi (七七)** - subagent, accounting friend
- **ccy** - subagent, study friend
- **librarian** - subagent, document/image processing
- **update** - subagent, memory management

## Design Doc

See `docs/superpowers/specs/2026-06-17-roomdoor-team-design.md`

## License

MIT

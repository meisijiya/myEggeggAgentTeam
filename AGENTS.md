# AGENTS.md — 房间门团队项目级开发约定

> ⚠️ 这是**项目根目录**的开发规范，不要与 `templates/AGENTS.md`（房间门 Agent 团队 prompt 模板）混淆。

## 开发约定

### 编码风格

1. **TDD 优先**：功能开发先写测试，再写实现。修复 bug 先写回归测试。
2. **DRY 但不提前抽象**：3 次重复才考虑抽象——过早提取会引入不必要的复杂性。
3. **YAGNI**：只实现当前需求明确需要的功能。不要"以防万一"加字段/接口/配置。
4. **函数级注释**：每个公开函数/方法写 1-3 行注释说明意图（what + why，不是 how）。
5. **中文注释 + 英文代码**：注释用中文（面向团队），代码标识符用英文。

### 代码审查

6. **自审优先**：每个 commit 前先 `git diff` 自审——检查是否有遗留的 debug 日志、TODO mock、硬编码凭据。
7. **PR 前 full review**：提交 PR 前必须过一遍完整的代码审查 checklist（功能完整性、边界条件、安全、错误处理、向后兼容）。
8. **reviewer 制度**：重要改动（架构变更、部署脚本、opencconfig 改动）需要 reviewer（老江湖）通过后方可合并。

### Commit 规范

9. **约定式提交**：`<type>(<scope>): <description>`，支持类型：`feat` / `fix` / `docs` / `chore` / `refactor` / `test` / `style`。
10. **粒度**：一个 commit 只做一件事。不混 "fix bug + refactor + add feature"。
11. **信息完整**：commit body 写明 why（非 what——what 看 diff 就行）。

### 项目元信息

12. **single-writer**：CONTEXT.md / AGENTS.md / docs/adr/ / docs/gotchas/ 仅由 `update` Agent 写入，其他 Agent 只读。
13. **gotcha 准入门槛**：避免性自评 < 3 分不记录（防止文档膨胀）。
14. **不删改旧记录**：术语弃用标记 `_Deprecated`，ADR 弃用标记 `superseded`，gotcha 自动归档基于 mtime。

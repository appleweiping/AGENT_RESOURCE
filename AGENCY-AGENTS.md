# Agency Agents (agency-agents-zh) — Claude Code 子代理

215+ 个即插即用的中文 AI 专家角色（覆盖工程/设计/营销/产品/游戏/安全/金融等 18 部门），
来自开源项目 [agency-agents-zh](https://github.com/jnMetaCode/agency-agents-zh)。

## 这个目录里是什么

`~/.claude/agents/agency/`（= `D:\devtools\claude\agents\agency\`）里放的是 **T1 精选常驻集**
（约 30 个真正跨项目通用的技术类子代理）。它们的 `description` 会注入每个 session 的路由上下文，
所以只放最常用的，避免上下文膨胀。

> 已用官方文档核实（Claude Code v2.1.161）：`~/.claude/agents/` 下**所有** agent（含子目录，递归）
> 的 `description` 都会进入主 agent 的自动路由上下文。211 个全装 ≈ 1 万 token/session，故采用分层。

## 三层结构

| 层 | 位置 | 内容 | 代价 |
|----|------|------|------|
| **T0 源** | `D:\agent-resources\repos\agency-agents-zh` | 全部 211 个原始 agent（中文 name） | 0，纯仓库 |
| **T0.5 暂存** | `D:\agent-resources\staging\agency-claude` | 全部 211 个 **slug 化、无 BOM** 副本（Claude Code 合规） | 0，按需取用 |
| **T1 常驻** | `~/.claude/agents/agency/` | 精选 ~30 个常驻全局 | ~描述 token/session |
| **T2 按需** | 任意项目 `.claude/agents/agency/` | 用命令把分类/全量灌进某项目 | 仅该项目 |

## 为什么要 slug 化（关键设计）

源仓库每个 agent 的 frontmatter `name:` 都是中文（如 `安全工程师`），且有重名。
Claude Code 子代理标识**只**来自 `name` 字段，且必须是「小写字母+连字符」，中文名无法被 `/name` 调用、
重名会被静默丢弃。所以暂存步骤把 `name:` 改写成「文件名 slug」（如 `engineering-security-engineer`），
中文名保留在 `description`/正文。**不要直接把仓库里的原始文件复制进 agents 目录。**

## 怎么用

```powershell
# 安装/重置精选常驻集（默认行为，会先刷新暂存）
install-agency
install-agency -Curated -NoRebuild      # 只装精选，不重建暂存

# 按需把某分类装到全局
install-agency -Category marketing
install-agency -Category engineering

# 把全部 211 个装到全局（重：~1万 token/session，谨慎）
install-agency -All

# 把分类/全量装到某个项目（只影响该项目，不污染全局）
install-agency -Category engineering -Project D:\Research\CSATG-EDA
install-agency -All -Project .          # 当前目录

# 查看分类与数量
install-agency -List
```

在 Claude Code 对话里用 `/<slug>` 显式调用，例如 `/engineering-security-engineer`，
或直接描述任务让主 agent 自动路由。

## 维护

- 上游更新后：`cd D:\agent-resources\repos\agency-agents-zh; git pull`，然后 `install-agency`（会自动重建暂存）。
- 其他工具（Codex/Cursor）的集成文件：`scripts\convert.ps1 -Tool codex|cursor`，
  之后**必须**跑 `agency-fix-integration-bom.ps1` 去掉 BOM（否则 TOML/.mdc 解析失败）。

## 脚本清单（都在 `D:\devtools\`）

- `agency-build-staging.ps1` — 生成 slug 化无 BOM 暂存副本
- `install-agency.ps1` / `install-agency.cmd` — 安装器（T1 常驻 / T2 按需）
- `agency-fix-integration-bom.ps1` — 去掉 convert.ps1 产生的 BOM

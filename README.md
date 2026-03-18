# zNAS CLI

zNAS 是 Zettos NAS 的命令行工具，供 AI Agent（Claude Code / Codex / OpenClaw 等）以技能（Skill）方式操控 NAS。

## 支持平台

| 平台 | 架构 | 文件名 |
|------|------|--------|
| Linux | x86_64 | `znas-linux-x86_64.tar.gz` |
| Linux | aarch64 | `znas-linux-aarch64.tar.gz` |
| macOS | Apple Silicon | `znas-macos-aarch64.tar.gz` |

## 安装

### 1. 克隆仓库

```bash
git clone git@github.com:zettlab/zettos-skills.git
cd zettos-skills
```

### 2. 下载二进制包

前往本仓库的 [Releases](../../releases) 页面，下载你平台对应的 `.tar.gz` 文件，放到仓库的 `releases/` 目录下。

### 3. 运行安装脚本

```bash
# 交互式安装（会提示选择 agent 类型）
bash install.sh

# 指定 agent 类型
bash install.sh --agent claudecode
bash install.sh --agent codex
bash install.sh --agent openclaw

# 自定义 skill 目录
bash install.sh --agent custom --skills-dir ~/.local/share/my-agent/skills
```

安装脚本会：
- 解压二进制到 `/usr/local/bin`（无权限时自动降级到 `~/.local/bin`）
- 将 6 个 Skill 复制到对应 agent 的 skill 目录

### 4. 验证

```bash
znas --version
```

## Skills

仓库 `skills/` 目录包含 6 个 AI Agent 技能：

| Skill | 用途 |
|-------|------|
| `znas-shared` | 共享配置：网关连接、认证、通用规则 |
| `znas-file` | 文件管理：浏览、上传、下载、搜索、分享 |
| `znas-settings` | 系统设置：网络、存储、用户、安全等 |
| `znas-app-store` | 应用商店：安装、更新、卸载应用 |
| `znas-docker` | Docker 管理：容器、镜像、网络、卷 |
| `znas-desktop-shell` | 桌面功能：资源监控、任务中心、消息 |

## Agent Skill 目录默认路径

| Agent | 默认路径 |
|-------|----------|
| Claude Code | `~/.claude/skills/` |
| Codex | `~/.codex/skills/` |
| OpenClaw | `~/.agents/skills/` |

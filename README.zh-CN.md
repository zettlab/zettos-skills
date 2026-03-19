# zNAS CLI

[English](README.md)

zNAS 是 ZettOS NAS 的命令行工具，并随仓库提供一组 Skill，供 Claude Code、Codex、OpenClaw 等 AI Agent 通过统一接口操控 NAS。

## 支持平台

| 平台 | 架构 | 发布文件 |
| --- | --- | --- |
| Linux | x86_64 | `znas-linux-x86_64.tar.gz` |
| Linux | aarch64 | `znas-linux-aarch64.tar.gz` |
| macOS | Apple Silicon | `znas-macos-aarch64.tar.gz` |

暂不支持 macOS `x86_64`。

## 安装

### 1. 克隆仓库

```bash
git clone git@github.com:zettlab/zettos-skills.git
cd zettos-skills
```

### 2. 下载发布包

前往仓库的 [Releases](../../releases) 页面，下载当前平台对应的压缩包，并放到仓库本地的 `releases/` 目录下。

### 3. 运行安装脚本

```bash
# 交互式安装
bash install.sh

# 指定目标 agent
bash install.sh --agent codex
bash install.sh --agent claudecode
bash install.sh --agent openclaw

# 自定义 skill 目录
bash install.sh --agent custom --skills-dir ~/.local/share/my-agent/skills

# 自定义二进制安装目录
bash install.sh --agent codex --install-dir ~/.local/bin

# 使用默认选项进行非交互安装
bash install.sh --agent codex --yes
```

安装脚本会：

- 默认将 `znas` 二进制安装到 `/usr/local/bin`，如果目标目录不可写，会自动降级到 `~/.local/bin`。
- 将仓库内置的 6 个 Skill 复制到所选 agent 的 skill 目录。
- 在需要时提示把 `~/.local/bin` 加入 `PATH`。

### 4. 验证安装

```bash
znas --version
```

## 内置 Skills

仓库 `skills/` 目录包含 6 个 AI Agent Skill：

| Skill | 用途 |
| --- | --- |
| `znas-shared` | 共享配置、网关连接、认证和通用规则 |
| `znas-file` | 文件管理，包括浏览、上传、下载、搜索和分享 |
| `znas-settings` | 系统设置，如网络、存储、用户和安全 |
| `znas-app-store` | 应用商店操作，包括安装、更新和卸载 |
| `znas-docker` | Docker 管理，包括容器、镜像、网络及相关资源 |
| `znas-desktop-shell` | 桌面能力，如资源监控、任务中心和消息中心 |

## Agent Skill 默认目录

| Agent | 默认路径 |
| --- | --- |
| Claude Code | `~/.claude/skills/` |
| Codex | `~/.codex/skills/` |
| OpenClaw | `~/.agents/skills/` |

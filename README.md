# zNAS CLI

[简体中文](README.zh-CN.md)

zNAS is a command-line tool for Zettos NAS. It is packaged together with Skill bundles so AI agents such as Claude Code, Codex, and OpenClaw can operate a NAS through a consistent interface.

## Supported Platforms

| Platform | Architecture | Release Archive |
| --- | --- | --- |
| Linux | x86_64 | `znas-linux-x86_64.tar.gz` |
| Linux | aarch64 | `znas-linux-aarch64.tar.gz` |
| macOS | Apple Silicon | `znas-macos-aarch64.tar.gz` |

macOS `x86_64` is not supported.

## Installation

### 1. Clone the repository

```bash
git clone git@github.com:zettlab/zettos-skills.git
cd zettos-skills
```

### 2. Download the release archive

Open the [Releases](../../releases) page, download the archive for your platform, and place it under the local `releases/` directory in this repository.

### 3. Run the installer

```bash
# Interactive install
bash install.sh

# Specify the target agent
bash install.sh --agent codex
bash install.sh --agent claudecode
bash install.sh --agent openclaw

# Custom skill directory
bash install.sh --agent custom --skills-dir ~/.local/share/my-agent/skills

# Override the binary install directory
bash install.sh --agent codex --install-dir ~/.local/bin

# Non-interactive install with defaults
bash install.sh --agent codex --yes
```

The installer will:

- Extract the `znas` binary into `/usr/local/bin` by default, and fall back to `~/.local/bin` if the target directory is not writable.
- Copy the 6 bundled Skills into the selected agent skill directory.
- Offer to add `~/.local/bin` to `PATH` when needed.

### 4. Verify the installation

```bash
znas --version
```

## Included Skills

The `skills/` directory contains 6 AI agent Skills:

| Skill | Purpose |
| --- | --- |
| `znas-shared` | Shared configuration, gateway connectivity, authentication, and common rules |
| `znas-file` | File management, including browse, upload, download, search, and sharing |
| `znas-settings` | System settings such as network, storage, users, and security |
| `znas-app-store` | App Store operations, including install, update, and uninstall |
| `znas-docker` | Docker management for containers, images, networks, and related resources |
| `znas-desktop-shell` | Desktop features such as resource monitoring, task center, and messages |

## Default Agent Skill Directories

| Agent | Default Path |
| --- | --- |
| Claude Code | `~/.claude/skills/` |
| Codex | `~/.codex/skills/` |
| OpenClaw | `~/.agents/skills/` |

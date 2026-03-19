# zNAS CLI

[简体中文](README.zh-CN.md)

zNAS is a command-line tool for ZettOS NAS. It is packaged together with Skill bundles so AI agents such as Claude Code, Codex, and OpenClaw can operate a NAS through a consistent interface.

## Supported Platforms

| Platform | Architecture | Release Archive |
| --- | --- | --- |
| Linux | x86_64 | `znas-linux-x86_64.tar.gz` |
| Linux | aarch64 | `znas-linux-aarch64.tar.gz` |
| macOS | Apple Silicon | `znas-macos-aarch64.tar.gz` |

macOS `x86_64` is not supported.

## Installation

### Recommended: one-command install from GitHub

```bash
curl -fsSL https://github.com/zettlab/zettos-skills/releases/latest/download/install_release_znas.sh | bash
```

Install non-interactively for a specific agent:

```bash
curl -fsSL https://github.com/zettlab/zettos-skills/releases/latest/download/install_release_znas.sh | bash -s -- --agent codex --yes
curl -fsSL https://github.com/zettlab/zettos-skills/releases/latest/download/install_release_znas.sh | bash -s -- --agent claudecode --yes
curl -fsSL https://github.com/zettlab/zettos-skills/releases/latest/download/install_release_znas.sh | bash -s -- --agent openclaw --yes
```

Custom install locations:

```bash
curl -fsSL https://github.com/zettlab/zettos-skills/releases/latest/download/install_release_znas.sh | bash -s -- \
  --agent custom \
  --skills-dir ~/.local/share/my-agent/skills \
  --install-dir ~/.local/bin \
  --yes
```

The online installer will:

- Download the latest GitHub Release archive for your platform automatically.
- Download the matching repository source archive for the same release tag.
- Install the `znas` binary into `/usr/local/bin` by default, and fall back to `~/.local/bin` if the target directory is not writable.
- Copy the 6 bundled Skills into the selected agent skill directory.
- Offer to add `~/.local/bin` to `PATH` when needed.

The installer script itself is served from the GitHub Release assets, so the entrypoint is versioned and does not drift with `main`.

### Verify the installation

```bash
znas --version
```

### Alternative: install from a local clone

If you prefer to install from a checked-out repository, you can still use the local installer:

```bash
git clone https://github.com/zettlab/zettos-skills.git
cd zettos-skills

# Download the release archive for your platform into ./releases first
bash install.sh --agent codex --yes
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

#!/usr/bin/env bash
set -euo pipefail

BIN_NAME="znas"
DEFAULT_INSTALL_DIR="/usr/local/bin"
DEFAULT_CODEX_SKILLS_DIR="${HOME}/.codex/skills"
DEFAULT_CLAUDE_SKILLS_DIR="${HOME}/.claude/skills"
DEFAULT_OPENCLAW_SKILLS_DIR="${HOME}/.agents/skills"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RELEASES_DIR="$SCRIPT_DIR/releases"
SKILLS_DIR_SRC="$SCRIPT_DIR/skills"
SKILLS=(
  "znas-shared"
  "znas-file"
  "znas-settings"
  "znas-app-store"
  "znas-docker"
  "znas-desktop-shell"
)

AGENT=""
SKILLS_DIR=""
INSTALL_DIR="$DEFAULT_INSTALL_DIR"
YES=0

usage() {
  cat <<'EOF'
Usage: install.sh [options]

Install the znas binary and 6 AI agent skills.

Prerequisites:
  Download the binary archive for your platform from the GitHub Release page
  and place it in the releases/ directory next to this script.

Options:
  --agent <codex|claudecode|openclaw|custom>
                                       Target agent type
  --skills-dir <dir>                   Override skill install directory
  --install-dir <dir>                  Override binary install directory
  --yes                                Non-interactive install using defaults
  -h, --help                           Show this help
EOF
}

require_cmd() {
  local cmd="$1"
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "error: required command not found: $cmd" >&2
    exit 1
  fi
}

detect_platform() {
  local os arch
  os="$(uname -s)"
  arch="$(uname -m)"

  case "$os" in
    Linux) os="linux" ;;
    Darwin) os="macos" ;;
    *)
      echo "error: unsupported operating system: $os" >&2
      exit 1
      ;;
  esac

  case "$arch" in
    x86_64|amd64) arch="x86_64" ;;
    aarch64|arm64) arch="aarch64" ;;
    *)
      echo "error: unsupported architecture: $arch" >&2
      exit 1
      ;;
  esac

  if [[ "$os" == "macos" && "$arch" == "x86_64" ]]; then
    echo "error: macOS x86_64 is not supported" >&2
    exit 1
  fi

  echo "${os}-${arch}"
}

asset_name_for_platform() {
  echo "znas-${1}.tar.gz"
}

prompt_agent() {
  if [[ -n "$AGENT" ]]; then
    return
  fi
  if [[ ! -r /dev/tty ]]; then
    echo "error: interactive mode requires a terminal; rerun with --agent codex|claudecode|openclaw" >&2
    exit 1
  fi
  cat <<'EOF'
Select agent:
  1) codex
  2) claudecode
  3) openclaw
  4) custom skills dir
EOF
  local answer=""
  while [[ -z "$answer" ]]; do
    read -r -p "Choice [1-4]: " answer </dev/tty
    case "$answer" in
      1) AGENT="codex" ;;
      2) AGENT="claudecode" ;;
      3) AGENT="openclaw" ;;
      4) AGENT="custom" ;;
      *) answer="" ;;
    esac
  done
}

prompt_custom_skills_dir() {
  if [[ -n "$SKILLS_DIR" ]]; then
    return
  fi
  if [[ ! -r /dev/tty ]]; then
    echo "error: custom skills dir requires --skills-dir when no terminal is available" >&2
    exit 1
  fi
  local answer=""
  while [[ -z "$answer" ]]; do
    read -r -p "Custom skills dir: " answer </dev/tty
  done
  SKILLS_DIR="$answer"
}

resolve_default_skills_dir() {
  case "$AGENT" in
    codex) echo "$DEFAULT_CODEX_SKILLS_DIR" ;;
    claudecode) echo "$DEFAULT_CLAUDE_SKILLS_DIR" ;;
    openclaw) echo "$DEFAULT_OPENCLAW_SKILLS_DIR" ;;
    custom) echo "$SKILLS_DIR" ;;
    *)
      echo "error: unsupported agent: $AGENT" >&2
      exit 1
      ;;
  esac
}

ensure_writable_dir() {
  local desired="$1"
  if [[ -d "$desired" || ! -e "$desired" ]]; then
    mkdir -p "$desired" 2>/dev/null || true
  fi
  if [[ -w "$desired" ]]; then
    echo "$desired"
    return
  fi
  local fallback="${HOME}/.local/bin"
  mkdir -p "$fallback"
  echo "$fallback"
}

path_contains_dir() {
  local dir="$1"
  local entry=""
  local old_ifs="$IFS"
  IFS=':'
  for entry in $PATH; do
    if [[ "$entry" == "$dir" ]]; then
      IFS="$old_ifs"
      return 0
    fi
  done
  IFS="$old_ifs"
  return 1
}

detect_shell_rc() {
  local shell_name
  shell_name="$(basename "${SHELL:-}")"
  case "$shell_name" in
    zsh) echo "${HOME}/.zshrc" ;;
    bash) echo "${HOME}/.bashrc" ;;
    *)
      if [[ -n "${ZDOTDIR:-}" ]]; then
        echo "${ZDOTDIR}/.zshrc"
      else
        echo "${HOME}/.profile"
      fi
      ;;
  esac
}

maybe_offer_path_update() {
  local bin_dir="$1"
  if [[ "$bin_dir" != "${HOME}/.local/bin" ]]; then
    return
  fi
  if path_contains_dir "$bin_dir"; then
    return
  fi

  local rc_file
  rc_file="$(detect_shell_rc)"
  local export_line='export PATH="$HOME/.local/bin:$PATH"'

  echo
  echo "warning: ${bin_dir} is not currently in PATH"

  if [[ "$YES" -eq 1 || ! -r /dev/tty ]]; then
    echo "Add this line to ${rc_file}, then reload your shell:"
    echo "  ${export_line}"
    return
  fi

  local answer=""
  read -r -p "Add ~/.local/bin to PATH in ${rc_file} now? [Y/n]: " answer </dev/tty
  answer="${answer:-Y}"
  if [[ ! "$answer" =~ ^[Yy]$ ]]; then
    echo "skipped PATH update"
    echo "Add this line to ${rc_file}, then reload your shell:"
    echo "  ${export_line}"
    return
  fi

  mkdir -p "$(dirname "$rc_file")"
  touch "$rc_file"
  if ! grep -Fq "$export_line" "$rc_file"; then
    printf '\n%s\n' "$export_line" >> "$rc_file"
    echo "updated PATH in ${rc_file}"
  else
    echo "PATH line already present in ${rc_file}"
  fi
  echo "Run one of these to use znas in the current shell:"
  echo "  source ${rc_file}"
  echo "  export PATH=\"\$HOME/.local/bin:\$PATH\""
}

extract_binary_from_archive() {
  local archive="$1"
  local out_dir="$2"
  mkdir -p "$out_dir"
  tar -xzf "$archive" -C "$out_dir"
  if [[ -x "$out_dir/$BIN_NAME" ]]; then
    echo "$out_dir/$BIN_NAME"
    return
  fi
  if [[ -x "$out_dir/bin/$BIN_NAME" ]]; then
    echo "$out_dir/bin/$BIN_NAME"
    return
  fi
  local found
  found="$(find "$out_dir" -type f -name "$BIN_NAME" -perm -u+x | head -n 1 || true)"
  if [[ -z "$found" ]]; then
    echo "error: binary $BIN_NAME not found inside archive" >&2
    exit 1
  fi
  echo "$found"
}

install_skills() {
  local src_dir="$1"
  local target_dir="$2"
  mkdir -p "$target_dir"
  local skill
  for skill in "${SKILLS[@]}"; do
    if [[ ! -d "$src_dir/$skill" ]]; then
      echo "error: skill directory not found: $src_dir/$skill" >&2
      exit 1
    fi
    rm -rf "$target_dir/$skill"
    cp -R "$src_dir/$skill" "$target_dir/$skill"
  done
}

# --- parse args ---

while [[ $# -gt 0 ]]; do
  case "$1" in
    --agent)
      AGENT="${2:-}"
      shift 2
      ;;
    --skills-dir)
      SKILLS_DIR="${2:-}"
      shift 2
      ;;
    --install-dir)
      INSTALL_DIR="${2:-}"
      shift 2
      ;;
    --yes)
      YES=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "error: unknown argument: $1" >&2
      exit 1
      ;;
  esac
done

require_cmd tar
require_cmd install

# --- detect platform and check binary ---

PLATFORM="$(detect_platform)"
ASSET_NAME="$(asset_name_for_platform "$PLATFORM")"
ASSET_PATH="$RELEASES_DIR/$ASSET_NAME"

if [[ ! -f "$ASSET_PATH" ]]; then
  echo "error: binary archive not found: $ASSET_PATH" >&2
  echo >&2
  echo "Please download '$ASSET_NAME' from the GitHub Release page" >&2
  echo "and place it in the releases/ directory:" >&2
  echo "  $RELEASES_DIR/" >&2
  exit 1
fi

# --- check skills ---

if [[ ! -d "$SKILLS_DIR_SRC" ]]; then
  echo "error: skills directory not found: $SKILLS_DIR_SRC" >&2
  echo "Make sure you cloned the full repository." >&2
  exit 1
fi

# --- agent selection ---

if [[ "$YES" -eq 0 ]]; then
  prompt_agent
fi

if [[ -z "$AGENT" ]]; then
  echo "error: --agent is required in non-interactive mode" >&2
  exit 1
fi

case "$AGENT" in
  codex|claudecode|openclaw|custom) ;;
  *)
    echo "error: --agent must be codex, claudecode, openclaw, or custom" >&2
    exit 1
    ;;
esac

if [[ "$AGENT" == "custom" ]]; then
  prompt_custom_skills_dir
fi

if [[ -z "$SKILLS_DIR" ]]; then
  SKILLS_DIR="$(resolve_default_skills_dir)"
fi

# --- install ---

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

echo "zNAS installer"
echo "  platform:   ${PLATFORM}"
echo "  agent:      ${AGENT}"
echo "  binary:     ${ASSET_PATH}"
echo "  skills src: ${SKILLS_DIR_SRC}"
echo "  skills dst: ${SKILLS_DIR}"
echo

BINARY_PATH="$(extract_binary_from_archive "$ASSET_PATH" "$TMP_DIR/bin-extract")"
TARGET_BIN_DIR="$(ensure_writable_dir "$INSTALL_DIR")"
install -m 0755 "$BINARY_PATH" "$TARGET_BIN_DIR/$BIN_NAME"
install_skills "$SKILLS_DIR_SRC" "$SKILLS_DIR"
maybe_offer_path_update "$TARGET_BIN_DIR"

hash -r 2>/dev/null || true

echo
echo "installed binary: $TARGET_BIN_DIR/$BIN_NAME"
echo "installed skills:"
for skill in "${SKILLS[@]}"; do
  echo "  - $SKILLS_DIR/$skill"
done
echo
"$TARGET_BIN_DIR/$BIN_NAME" --version

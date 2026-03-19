#!/usr/bin/env bash
set -euo pipefail

BIN_NAME="znas"
REPO_OWNER="zettlab"
REPO_NAME="zettos-skills"
GITHUB_API="https://api.github.com/repos/${REPO_OWNER}/${REPO_NAME}"
GITHUB_INSTALLER_URL="https://github.com/${REPO_OWNER}/${REPO_NAME}/releases/latest/download/install_release_znas.sh"
DEFAULT_INSTALL_DIR="/usr/local/bin"
DEFAULT_CODEX_SKILLS_DIR="${HOME}/.codex/skills"
DEFAULT_CLAUDE_SKILLS_DIR="${HOME}/.claude/skills"
DEFAULT_OPENCLAW_SKILLS_DIR="${HOME}/.agents/skills"
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
RELEASE_TAG=""

usage() {
  cat <<EOF
Usage: install_release_znas.sh [options]

Install the latest zNAS release from GitHub together with 6 AI agent skills.

Examples:
  curl -fsSL ${GITHUB_INSTALLER_URL} | bash
  curl -fsSL ${GITHUB_INSTALLER_URL} | bash -s -- --agent codex --yes

Options:
  --agent <codex|claudecode|openclaw|custom>
                                       Target agent type
  --skills-dir <dir>                   Override skill install directory
  --install-dir <dir>                  Override binary install directory
  --version <tag>                      Install a specific GitHub release tag
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
  cat <<EOF
Select agent and skills install directory:
  1) codex (${DEFAULT_CODEX_SKILLS_DIR})
  2) claudecode (${DEFAULT_CLAUDE_SKILLS_DIR})
  3) openclaw (${DEFAULT_OPENCLAW_SKILLS_DIR})
  4) custom skills dir (for other agents or a manual path)

Binary install directory:
  default: ${DEFAULT_INSTALL_DIR}
  fallback when not writable: ${HOME}/.local/bin
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
    read -r -p "Custom skills dir (absolute path or ~-based path): " answer </dev/tty
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

fetch_latest_release_tag() {
  local api_url="${GITHUB_API}/releases/latest"
  local response
  response="$(curl -fsSL "$api_url")"
  local tag
  tag="$(printf '%s\n' "$response" | sed -n 's/^[[:space:]]*"tag_name":[[:space:]]*"\([^"]*\)".*/\1/p' | head -n 1)"
  if [[ -z "$tag" ]]; then
    echo "error: failed to determine latest release tag from ${api_url}" >&2
    exit 1
  fi
  echo "$tag"
}

download_file() {
  local url="$1"
  local output="$2"
  curl -fL --retry 3 --connect-timeout 15 -o "$output" "$url"
}

find_extracted_root() {
  local parent="$1"
  local extracted
  extracted="$(find "$parent" -mindepth 1 -maxdepth 1 -type d | head -n 1 || true)"
  if [[ -z "$extracted" ]]; then
    echo "error: failed to locate extracted source directory under $parent" >&2
    exit 1
  fi
  echo "$extracted"
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
    --version)
      RELEASE_TAG="${2:-}"
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

require_cmd curl
require_cmd tar
require_cmd install

PLATFORM="$(detect_platform)"
ASSET_NAME="$(asset_name_for_platform "$PLATFORM")"

if [[ -z "$RELEASE_TAG" ]]; then
  RELEASE_TAG="$(fetch_latest_release_tag)"
fi

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

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

ASSET_URL="https://github.com/${REPO_OWNER}/${REPO_NAME}/releases/download/${RELEASE_TAG}/${ASSET_NAME}"
SOURCE_TARBALL_URL="https://github.com/${REPO_OWNER}/${REPO_NAME}/archive/refs/tags/${RELEASE_TAG}.tar.gz"
ASSET_PATH="${TMP_DIR}/${ASSET_NAME}"
SOURCE_TARBALL_PATH="${TMP_DIR}/source.tar.gz"
SOURCE_EXTRACT_DIR="${TMP_DIR}/source"

echo "Downloading ${ASSET_NAME} from release ${RELEASE_TAG}..."
download_file "$ASSET_URL" "$ASSET_PATH"

echo "Downloading skills source for ${RELEASE_TAG}..."
mkdir -p "$SOURCE_EXTRACT_DIR"
download_file "$SOURCE_TARBALL_URL" "$SOURCE_TARBALL_PATH"
tar -xzf "$SOURCE_TARBALL_PATH" -C "$SOURCE_EXTRACT_DIR"

SOURCE_ROOT="$(find_extracted_root "$SOURCE_EXTRACT_DIR")"
SKILLS_DIR_SRC="${SOURCE_ROOT}/skills"

if [[ ! -d "$SKILLS_DIR_SRC" ]]; then
  echo "error: skills directory not found in downloaded source archive" >&2
  exit 1
fi

echo
echo "zNAS installer"
echo "  release:    ${RELEASE_TAG}"
echo "  platform:   ${PLATFORM}"
echo "  agent:      ${AGENT}"
echo "  binary:     ${ASSET_URL}"
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

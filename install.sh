#!/usr/bin/env bash
set -euo pipefail

# SpSk installer -- clones the repo and symlinks into Claude Code plugins directory

REPO_URL="https://github.com/spsk-dev/tasteful-design.git"
PLUGIN_DIR="${HOME}/.claude/plugins"
PLUGIN_NAME="spsk"

echo "SpSk Installer"
echo "=============="
echo ""

# Check prerequisites
if ! command -v git &>/dev/null; then
  echo "Error: git is not installed. Install git and try again."
  exit 1
fi

if ! command -v claude &>/dev/null; then
  echo "Error: Claude Code CLI not found. Install from https://claude.ai/code and try again."
  exit 1
fi

# Determine source directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [[ -f "${SCRIPT_DIR}/.claude-plugin/plugin.json" ]]; then
  # Running from within the repo
  SOURCE_DIR="${SCRIPT_DIR}"
  echo "Using local repo at ${SOURCE_DIR}"
else
  # Clone to a temp location
  SOURCE_DIR="${TMPDIR:-/tmp}/spsk-install"
  if [[ -d "${SOURCE_DIR}" ]]; then
    echo "Updating existing clone..."
    git -C "${SOURCE_DIR}" pull --quiet
  else
    echo "Cloning SpSk..."
    git clone --quiet "${REPO_URL}" "${SOURCE_DIR}"
  fi
fi

# Create plugins directory
mkdir -p "${PLUGIN_DIR}"

# Create symlink
if [[ -L "${PLUGIN_DIR}/${PLUGIN_NAME}" ]]; then
  echo "Removing existing symlink..."
  rm "${PLUGIN_DIR}/${PLUGIN_NAME}"
elif [[ -e "${PLUGIN_DIR}/${PLUGIN_NAME}" ]]; then
  echo "Error: ${PLUGIN_DIR}/${PLUGIN_NAME} exists and is not a symlink. Remove it manually and try again."
  exit 1
fi

ln -s "${SOURCE_DIR}" "${PLUGIN_DIR}/${PLUGIN_NAME}"

echo ""
echo "Installed SpSk to ${PLUGIN_DIR}/${PLUGIN_NAME}"
echo ""
echo "Run /code-review or /design-review to get started."

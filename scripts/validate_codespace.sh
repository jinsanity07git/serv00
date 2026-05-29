#!/usr/bin/env bash
set -euo pipefail

script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
repo_root=$(cd -- "$script_dir/.." && pwd)
recipe_path="$repo_root/recipes/The Economist.recipe"

install_system_deps() {
  if ! command -v apt-get >/dev/null 2>&1; then
    echo "apt-get is not available; install libegl1 libopengl0 libxcb-cursor0 xvfb and calibre manually." >&2
    return 1
  fi

  echo "Installing system dependencies used by the workflow..."
  sudo apt-get update
  sudo apt-get install -y libegl1 libopengl0 libxcb-cursor0 libxkbcommon0 libasound2t64 xvfb
}

ensure_calibre() {
  if command -v ebook-convert >/dev/null 2>&1; then
    return
  fi

  echo "ebook-convert not found; installing Calibre like the workflow does..."
  export DEBIAN_FRONTEND=noninteractive
  sudo -v
  wget -nv -O- https://download.calibre-ebook.com/linux-installer.sh | sudo sh /dev/stdin
}

check_python_deps() {
  echo "Installing Python dependencies used by run.py..."
  python -m pip install --upgrade pip
  python -m pip install paramiko requests livedc
}

run_recipe_check() {
  echo "Validating The Economist recipe with ebook-convert..."
  "$script_dir/manual_ebook_check.sh" "$recipe_path"
}

run_python_check() {
  local required_vars=(SSH_INFO PUSH MAIL TELEGRAM_CHAT_ID TELEGRAM_BOT_TOKEN ERECIPIENT EACCOUNT EPASSWORD)
  local missing=()

  for var in "${required_vars[@]}"; do
    if [[ -z "${!var:-}" ]]; then
      missing+=("$var")
    fi
  done

  if ((${#missing[@]} > 0)); then
    echo "Skipping run.py because these env vars are missing: ${missing[*]}" >&2
    return 0
  fi

  echo "Running run.py with provided environment variables..."
  python "$repo_root/run.py"
}

main() {
  cd "$repo_root"

  install_system_deps
  ensure_calibre
  check_python_deps

  echo "Checking Python syntax for run.py..."
  python -m compileall run.py

  run_recipe_check
  run_python_check

  echo "Codespace validation completed successfully."
}

main "$@"
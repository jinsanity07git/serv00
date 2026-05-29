#!/usr/bin/env bash
set -euo pipefail

ensure_calibre() {
  if command -v ebook-convert >/dev/null 2>&1; then
    return
  fi

  if command -v apt-get >/dev/null 2>&1; then
    echo "ebook-convert not found; attempting to install Calibre via apt-get" >&2
    export DEBIAN_FRONTEND=noninteractive
    if ! apt-get update; then
      echo "Failed to update apt repositories automatically; install Calibre manually to continue." >&2
      exit 127
    fi

    if ! apt-get install -y --no-install-recommends calibre; then
      echo "Failed to install Calibre via apt-get. Install it manually and re-run this script." >&2
      exit 127
    fi
    return
  fi

  echo "ebook-convert is not installed and automatic installation is unavailable. Install Calibre manually to run this check." >&2
  exit 127
}

ensure_calibre

export QTWEBENGINE_DISABLE_SANDBOX=${QTWEBENGINE_DISABLE_SANDBOX:-1}
export QTWEBENGINE_CHROMIUM_FLAGS=${QTWEBENGINE_CHROMIUM_FLAGS:---disable-gpu}

script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
repo_recipe="$script_dir/../recipes/The Economist.recipe"
if [[ -z "${1:-}" && -f "$repo_recipe" ]]; then
  recipe="$repo_recipe"
else
  recipe=${1:-The Economist.recipe}
fi
out_dir=${OUTPUT_DIR:-eco}
mkdir -p "$out_dir"
out_file="$out_dir/$(date +%Y%m%d).epub"

rm -f "$out_file"

echo "Running: ebook-convert \"$recipe\" \"$out_file\""
if command -v xvfb-run >/dev/null 2>&1; then
  convert_cmd=(xvfb-run ebook-convert)
  use_xvfb=true
else
  convert_cmd=(ebook-convert)
  use_xvfb=false
fi

echo "Using: ${convert_cmd[*]} \"$recipe\" \"$out_file\""
if ! "${convert_cmd[@]}" "$recipe" "$out_file"; then
  status=$?
  if [ "$use_xvfb" = true ]; then
    echo "xvfb-run failed to start or ebook-convert failed under Xvfb (status $status). Retrying without xvfb-run..." >&2
    if ! ebook-convert "$recipe" "$out_file"; then
      status=$?
      echo "ebook-convert (no Xvfb) exited with status $status. Check the log above for proxy/authentication errors or retry from a network that can reach The Economist." >&2
      exit "$status"
    fi
  else
    echo "ebook-convert exited with status $status. Check the log above for proxy/authentication errors or retry from a network that can reach The Economist." >&2
    exit "$status"
  fi
fi

if [[ ! -s "$out_file" ]]; then
  echo "ebook-convert completed but $out_file was not created or is empty" >&2
  exit 1
fi

if command -v unzip >/dev/null 2>&1; then
  if unzip -p "$out_file" | grep -q 'Article not available\.'; then
    echo "Warning: EPUB was generated but contains one or more fallback 'Article not available.' pages." >&2
    echo "This usually means the source site blocked both API and web JSON extraction for some articles; retry later or from a different network." >&2
  fi
fi

echo "Successfully generated $out_file"

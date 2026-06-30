#!/usr/bin/env bash
# Push /root/github-upload to GitHub (standalone repo or grok-local-bridge subpath)
set -euo pipefail

UPLOAD_DIR="${UPLOAD_DIR:-/root/github-upload}"
source "${TERMUX_HOME:-/data/data/com.termux/files/home}/mobile-tools/config/ecosystem.env" 2>/dev/null || true

OWNER="${GITHUB_BRIDGE_OWNER:-Developer-Dipshit}"
REPO="${GITHUB_UPLOAD_REPO:-samsung-s911w-re-catalog}"
BRANCH="${GITHUB_BRIDGE_BRANCH:-main}"
METHOD="${1:-auto}"  # auto | git | api | bridge

get_token() {
  if [[ -n "${GITHUB_TOKEN:-}" ]]; then
    echo "$GITHUB_TOKEN"
    return 0
  fi
  if command -v gh >/dev/null 2>&1; then
    gh auth token 2>/dev/null && return 0
  fi
  echo "ERROR: Set GITHUB_TOKEN or run: gh auth login" >&2
  return 1
}

git_push_standalone() {
  local token="$1"
  cd "$UPLOAD_DIR"
  if [[ ! -d .git ]]; then
    git init
    git branch -M "$BRANCH"
    git config user.email "${GIT_AUTHOR_EMAIL:-device-admin@local}"
    git config user.name "${GIT_AUTHOR_NAME:-Device Admin}"
    git add -A
    git commit -m "Add Samsung S911W reverse engineering catalog" || true
  fi
  local url="https://${token}@github.com/${OWNER}/${REPO}.git"
  git push -u "$url" "$BRANCH"
  echo "Pushed: https://github.com/${OWNER}/${REPO}"
}

api_push_bridge() {
  local token="$1"
  python3 - "$token" <<'PY'
import base64, json, os, sys, urllib.request
from pathlib import Path

token, upload = sys.argv[1], Path(os.environ.get("UPLOAD_DIR", "/root/github-upload"))
owner = os.environ.get("GITHUB_BRIDGE_OWNER", "Developer-Dipshit")
repo = os.environ.get("GITHUB_BRIDGE_REPO", "grok-local-bridge")
branch = os.environ.get("GITHUB_BRIDGE_BRANCH", "main")
prefix = os.environ.get("GITHUB_BRIDGE_PREFIX", "projects/samsung-s911w-re-catalog")

batches = json.loads((upload / "push_batches.json").read_text())
headers = {
    "Authorization": f"Bearer {token}",
    "Accept": "application/vnd.github+json",
    "Content-Type": "application/json",
    "X-GitHub-Api-Version": "2022-11-28",
}

def get_sha(path: str):
    req = urllib.request.Request(
        f"https://api.github.com/repos/{owner}/{repo}/contents/{path}?ref={branch}",
        headers=headers,
    )
    try:
        with urllib.request.urlopen(req, timeout=30) as resp:
            return json.loads(resp.read().decode()).get("sha")
    except Exception:
        return None

for batch_idx, batch in enumerate(batches, 1):
    for item in batch:
        path = item["path"]
        if not path.startswith("projects/"):
            path = f"{prefix}/{path}"
        content = item["content"]
        if isinstance(content, str):
            b64 = base64.b64encode(content.encode()).decode()
        else:
            b64 = base64.b64encode(content).decode()
        body = {"message": f"sync: RE catalog ({path})", "content": b64, "branch": branch}
        sha = get_sha(path)
        if sha:
            body["sha"] = sha
        req = urllib.request.Request(
            f"https://api.github.com/repos/{owner}/{repo}/contents/{path}",
            data=json.dumps(body).encode(),
            headers=headers,
            method="PUT",
        )
        with urllib.request.urlopen(req, timeout=60) as resp:
            result = json.loads(resp.read().decode())
            print(f"  ok: {path} ({result.get('commit', {}).get('sha', '')[:8]})")
    print(f"Batch {batch_idx} complete ({len(batch)} files)")

print(f"Bridge push done: https://github.com/{owner}/{repo}/tree/{branch}/{prefix}")
PY
}

main() {
  local token
  token="$(get_token)"
  case "$METHOD" in
    git) git_push_standalone "$token" ;;
    api|bridge) api_push_bridge "$token" ;;
    auto)
      if git_push_standalone "$token" 2>/dev/null; then
        return 0
      fi
      api_push_bridge "$token"
      ;;
    *) echo "Usage: $0 [auto|git|api|bridge]" >&2; exit 1 ;;
  esac
}

main
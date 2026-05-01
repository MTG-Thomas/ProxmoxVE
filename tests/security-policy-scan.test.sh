#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCANNER="$ROOT_DIR/scripts/security-policy-scan.sh"

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

assert_contains() {
  local needle="$1"
  local haystack="$2"

  if [[ "$haystack" != *"$needle"* ]]; then
    fail "expected output to contain: $needle"
  fi
}

assert_not_contains() {
  local needle="$1"
  local haystack="$2"

  if [[ "$haystack" == *"$needle"* ]]; then
    fail "expected output not to contain: $needle"
  fi
}

run_scan() {
  local target="$1"
  shift

  bash "$SCANNER" --root "$target" "$@" 2>&1
}

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

mkdir -p "$tmpdir/repo/ct" "$tmpdir/repo/install" "$tmpdir/repo/docs/security" "$tmpdir/repo/misc"

cat >"$tmpdir/repo/docs/security/script-security-model.md" <<'DOC'
# Script Security Model
DOC

cat >"$tmpdir/repo/ct/example.sh" <<'SCRIPT'
#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
var_unprivileged="${var_unprivileged:-0}"
SCRIPT

cat >"$tmpdir/repo/install/example-install.sh" <<'SCRIPT'
#!/usr/bin/env bash
sh <(curl -fsSL https://get.docker.com)
docker run --privileged example/image:latest
echo '{ "hosts": ["unix:///var/run/docker.sock", "tcp://0.0.0.0:2375"] }' >/etc/docker/daemon.json
SCRIPT

cat >"$tmpdir/repo/misc/ok.func" <<'SCRIPT'
#!/usr/bin/env bash
curl -fsSL "https://example.invalid/file.tar.gz" -o "$tmpdir/file.tar.gz"
SCRIPT

set +e
output="$(run_scan "$tmpdir/repo")"
status=$?
set -e

[[ "$status" -eq 1 ]] || fail "scanner should exit 1 when findings exist, got $status"
assert_contains "remote-code-execution" "$output"
assert_contains "pinned-version-required" "$output"
assert_contains "privileged-container-default" "$output"
assert_contains "docker-insecure-tcp" "$output"
assert_contains "container-privileged-run" "$output"
assert_contains "5 finding(s)" "$output"

set +e
advisory_output="$(run_scan "$tmpdir/repo" --advisory)"
advisory_status=$?
set -e

[[ "$advisory_status" -eq 0 ]] || fail "advisory mode should exit 0, got $advisory_status"
assert_contains "advisory mode" "$advisory_output"
assert_contains "5 finding(s)" "$advisory_output"

mkdir -p "$tmpdir/clean/ct" "$tmpdir/clean/docs/security"
cat >"$tmpdir/clean/ct/example.sh" <<'SCRIPT'
#!/usr/bin/env bash
source ./misc/build.func
var_unprivileged="${var_unprivileged:-1}"
SCRIPT
cat >"$tmpdir/clean/docs/security/script-security-model.md" <<'DOC'
# Script Security Model
DOC

clean_output="$(run_scan "$tmpdir/clean")"
assert_contains "0 finding(s)" "$clean_output"
assert_not_contains "remote-code-execution" "$clean_output"

mkdir -p "$tmpdir/git-repo/ct" "$tmpdir/git-repo/docs/security"
(
  cd "$tmpdir/git-repo"
  git init -q
  git config user.email "test@example.invalid"
  git config user.name "Test User"
  cat >docs/security/script-security-model.md <<'DOC'
# Script Security Model
DOC
  cat >ct/legacy.sh <<'SCRIPT'
#!/usr/bin/env bash
source <(curl -fsSL https://example.invalid/legacy.func)
SCRIPT
  git add .
  git commit -qm "baseline"
  cat >ct/new.sh <<'SCRIPT'
#!/usr/bin/env bash
source <(curl -fsSL https://example.invalid/new.func)
SCRIPT
)

set +e
changed_output="$(run_scan "$tmpdir/git-repo" --changed HEAD)"
changed_status=$?
set -e

[[ "$changed_status" -eq 1 ]] || fail "changed scan should exit 1 when findings exist, got $changed_status"
assert_contains "1 finding(s)" "$changed_output"
assert_contains "ct/new.sh" "$changed_output"
assert_not_contains "ct/legacy.sh" "$changed_output"

echo "security-policy-scan tests passed"

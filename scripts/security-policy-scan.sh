#!/usr/bin/env bash
# shellcheck disable=SC2016
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage: scripts/security-policy-scan.sh [--root PATH] [--changed REF] [--advisory] [--format text|markdown]

Scans shell scripts for security-sensitive patterns that require review before
public-repo acceptance. By default, exits 1 when findings are present.

Options:
  --root PATH       Repository root to scan. Defaults to current directory.
  --changed REF     Scan only shell files changed since REF. Uses git diff --name-only.
  --advisory        Report findings but exit 0.
  --format FORMAT   Output format: text or markdown. Defaults to text.
  -h, --help        Show this help.
USAGE
}

root="."
advisory=false
format="text"
changed_ref=""

while [[ $# -gt 0 ]]; do
  case "$1" in
  --root)
    [[ $# -ge 2 ]] || {
      echo "missing value for --root" >&2
      exit 64
    }
    root="$2"
    shift 2
    ;;
  --advisory)
    advisory=true
    shift
    ;;
  --changed)
    [[ $# -ge 2 ]] || {
      echo "missing value for --changed" >&2
      exit 64
    }
    changed_ref="$2"
    shift 2
    ;;
  --format)
    [[ $# -ge 2 ]] || {
      echo "missing value for --format" >&2
      exit 64
    }
    format="$2"
    shift 2
    ;;
  -h | --help)
    usage
    exit 0
    ;;
  *)
    echo "unknown argument: $1" >&2
    usage >&2
    exit 64
    ;;
  esac
done

case "$format" in
text | markdown) ;;
*)
  echo "unsupported --format: $format" >&2
  exit 64
  ;;
esac

root="$(cd "$root" && pwd)"
scan_scope="repository"
if [[ -n "$changed_ref" ]]; then
  scan_scope="changed files since $changed_ref"
fi

git_bin="git"
if [[ "$root" == /mnt/[a-zA-Z]/* ]] && command -v git.exe >/dev/null 2>&1; then
  git_bin="git.exe"
fi

declare -A rule_title=(
  [remote-code-execution]="Remote code is sourced or executed directly"
  [untrusted-upstream-bootstrap]="Runtime helper is bootstrapped from public upstream"
  [pinned-version-required]="Runtime dependency uses a floating latest reference"
  [privileged-container-default]="Container defaults to privileged mode"
  [docker-insecure-tcp]="Docker TCP socket is exposed without TLS"
  [container-privileged-run]="Docker container is launched with --privileged"
  [world-writable-permission]="World-writable permissions are applied"
  [unsafe-recursive-delete]="Recursive delete uses an unsafe or broad target"
  [missing-security-model]="Repository security model document is missing"
)

declare -A rule_guidance=(
  [remote-code-execution]="Fetch through a vetted helper that pins the expected repo ref and verifies content before sourcing or executing it."
  [untrusted-upstream-bootstrap]="Fork runtime scripts must bootstrap reviewed helpers from MTG-Thomas/ProxmoxVE unless a reviewer approves a documented exception."
  [pinned-version-required]="Prefer a manifest-pinned version, digest, or checksum. Floating latest is allowed only with an explicit exception."
  [privileged-container-default]="Default to unprivileged containers and document any app-specific exception in the privilege allowlist."
  [docker-insecure-tcp]="Do not expose Docker on tcp://0.0.0.0:2375. Require localhost-only, TLS, or an explicit break-glass path."
  [container-privileged-run]="Avoid --privileged Docker runs. Replace with targeted capabilities, devices, or documented exceptions."
  [world-writable-permission]="Use the narrowest owner/group/mode needed instead of chmod 777 or chmod -R 777."
  [unsafe-recursive-delete]="Use quoted, validated, non-empty targets and prefer helper wrappers for destructive cleanup."
  [missing-security-model]="Add docs/security/script-security-model.md before enabling this scanner as a required gate."
)

declare -A examples=()
declare -A counts=()
declare -a rule_order=()

record_finding() {
  local rule="$1"
  local file="$2"
  local line="$3"
  local text="$4"

  if [[ -z "${counts[$rule]+x}" ]]; then
    rule_order+=("$rule")
    counts[$rule]=0
    examples[$rule]=""
  fi

  counts[$rule]=$((counts[$rule] + 1))

  if [[ -z "${examples[$rule]}" ]]; then
    examples[$rule]="${file}:${line}: ${text}"
  fi
}

scan_line() {
  local file="$1"
  local line_no="$2"
  local line="$3"
  local rel="${file#"$root"/}"

  [[ "$line" =~ ^[[:space:]]*# ]] && return 0

  if [[ "$line" =~ source[[:space:]]+\<\(curl || "$line" =~ source[[:space:]]+\<\(wget ||
        "$line" =~ (^|[[:space:]])(bash|sh)[[:space:]]+\<\(curl ||
        "$line" =~ curl[^\|]*\|[[:space:]]*(bash|sh) ||
        "$line" =~ wget[^\|]*\|[[:space:]]*(bash|sh) ]]; then
    record_finding "remote-code-execution" "$rel" "$line_no" "$line"
  fi

  if [[ "$line" =~ :latest([^[:alnum:]_.-]|$) ||
        "$line" =~ releases/latest ||
        "$line" =~ /latest/download/ ||
        "$line" =~ get_latest_github_release ||
        "$line" =~ fetch_and_deploy_gh_release[^\#]*[\"\']latest[\"\'] ]]; then
    record_finding "pinned-version-required" "$rel" "$line_no" "$line"
  fi

  if [[ "$line" =~ var_unprivileged=\"\$\{var_unprivileged:-0\}\" ]]; then
    record_finding "privileged-container-default" "$rel" "$line_no" "$line"
  fi

  if [[ "$line" =~ tcp://0\.0\.0\.0:2375 ]]; then
    record_finding "docker-insecure-tcp" "$rel" "$line_no" "$line"
  fi

  if [[ "$line" =~ (^|[[:space:]])--privileged([[:space:]]|$|\\) ]]; then
    record_finding "container-privileged-run" "$rel" "$line_no" "$line"
  fi

  if [[ "$line" =~ chmod[[:space:]]+(-R[[:space:]]+)?777 ]]; then
    record_finding "world-writable-permission" "$rel" "$line_no" "$line"
  fi

  if [[ "$line" =~ rm[[:space:]]+-rf[[:space:]]+(/|\*|\"\$\{?[A-Za-z0-9_]+\}?\"?$) ]]; then
    record_finding "unsafe-recursive-delete" "$rel" "$line_no" "$line"
  fi
}

build_file_list() {
  if [[ -n "$changed_ref" ]]; then
    (
      cd "$root"
      {
        "$git_bin" diff --name-only --diff-filter=ACMRT "$changed_ref" -- '*.sh' '*.func' '*.bash'
        "$git_bin" ls-files --others --exclude-standard -- '*.sh' '*.func' '*.bash'
      } |
        sort -u |
        while IFS= read -r relpath; do
          case "$relpath" in
          scripts/security-policy-scan.sh | tests/security-policy-scan.test.sh) continue ;;
          esac
          [[ -n "$relpath" && -f "$root/$relpath" ]] && printf '%s\n' "$root/$relpath"
        done
    )
  else
    find "$root" \
      \( -path "$root/.git" -o -path "$root/.github/changelogs" \) -prune -o \
      -type f \( -name '*.sh' -o -name '*.func' -o -name '*.bash' \) -print
  fi
}

scan_files=()
while IFS= read -r file; do
  [[ -z "$file" ]] && continue
  scan_files+=("$file")
done < <(build_file_list)

if [[ "${#scan_files[@]}" -gt 0 ]]; then
  while IFS=$'\t' read -r rule file line_no text; do
  [[ -z "${rule:-}" ]] && continue
  rel="${file#"$root"/}"
  record_finding "$rule" "$rel" "$line_no" "$text"
  done < <(
    printf '%s\n' "${scan_files[@]}" |
      xargs awk '
      /^[[:space:]]*#/ { next }
      index($0, "raw.githubusercontent.com/community-scripts/ProxmoxVE/main") ||
      index($0, "git.community-scripts.org/community-scripts/ProxmoxVE/raw/branch/main") {
        print "untrusted-upstream-bootstrap\t" FILENAME "\t" FNR "\t" $0
      }
      (index($0, "source <(curl") || index($0, "source <(wget") ||
      index($0, "bash <(curl") || index($0, "sh <(curl") ||
      $0 ~ /curl[^|]*\|[[:space:]]*(bash|sh)/ ||
      $0 ~ /wget[^|]*\|[[:space:]]*(bash|sh)/) &&
      !($0 ~ /source <\(curl -fsSL https:\/\/raw\.githubusercontent\.com\/MTG-Thomas\/ProxmoxVE\/main\/misc\/[A-Za-z0-9_.-]+\.func\)/) {
        print "remote-code-execution\t" FILENAME "\t" FNR "\t" $0
      }
      $0 ~ /:latest([^[:alnum:]_.-]|$)/ ||
      index($0, "releases/latest") || index($0, "/latest/download/") ||
      index($0, "get_latest_github_release") ||
      index($0, "\"latest\"") || index($0, "'\''latest'\''") {
        print "pinned-version-required\t" FILENAME "\t" FNR "\t" $0
      }
      index($0, "var_unprivileged=\"${var_unprivileged:-0}\"") {
        print "privileged-container-default\t" FILENAME "\t" FNR "\t" $0
      }
      index($0, "tcp://0.0.0.0:2375") {
        print "docker-insecure-tcp\t" FILENAME "\t" FNR "\t" $0
      }
      $0 ~ /(^|[[:space:]])--privileged([[:space:]]|$|\\)/ {
        print "container-privileged-run\t" FILENAME "\t" FNR "\t" $0
      }
      $0 ~ /chmod[[:space:]]+(-R[[:space:]]+)?777/ {
        print "world-writable-permission\t" FILENAME "\t" FNR "\t" $0
      }
      $0 ~ /rm[[:space:]]+-rf[[:space:]]+(\/|\*|"\$\{?[A-Za-z0-9_]+\}?"?$)/ {
        print "unsafe-recursive-delete\t" FILENAME "\t" FNR "\t" $0
      }
      ' 2>/dev/null || true
  )
fi

if [[ ! -f "$root/docs/security/script-security-model.md" ]]; then
  record_finding "missing-security-model" "docs/security/script-security-model.md" 1 "required security model document is absent"
fi

finding_count="${#rule_order[@]}"
instance_count=0
for rule in "${rule_order[@]}"; do
  instance_count=$((instance_count + counts[$rule]))
done

if [[ "$format" == "markdown" ]]; then
  echo "## Script Security Policy Scan"
  echo
  echo "**Result:** ${finding_count} finding(s), ${instance_count} matching instance(s)"
  echo "**Scope:** ${scan_scope}"
  [[ "$advisory" == true ]] && echo "**Mode:** advisory mode"
  echo
  if [[ "$finding_count" -eq 0 ]]; then
    echo "No policy findings detected."
  else
    echo "| Rule | Instances | First example | Guidance |"
    echo "|------|-----------|---------------|----------|"
    for rule in "${rule_order[@]}"; do
      echo "| \`$rule\` | ${counts[$rule]} | \`${examples[$rule]}\` | ${rule_guidance[$rule]} |"
    done
  fi
else
  echo "Script security policy scan: ${finding_count} finding(s), ${instance_count} matching instance(s)"
  echo "Scope: ${scan_scope}"
  [[ "$advisory" == true ]] && echo "Running in advisory mode; findings will not fail the command."
  echo
  if [[ "$finding_count" -eq 0 ]]; then
    echo "No policy findings detected."
  else
    for rule in "${rule_order[@]}"; do
      echo "[$rule] ${rule_title[$rule]}"
      echo "  instances: ${counts[$rule]}"
      echo "  first: ${examples[$rule]}"
      echo "  guidance: ${rule_guidance[$rule]}"
      echo
    done
  fi
fi

if [[ "$finding_count" -gt 0 && "$advisory" != true ]]; then
  exit 1
fi

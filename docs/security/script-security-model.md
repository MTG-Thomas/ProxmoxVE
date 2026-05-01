# Script Security Model

This repository publishes shell scripts that users run as root on Proxmox hosts and inside newly created containers. Treat every script change as privileged automation, not as a normal application patch.

This model is fork-local policy for `MTG-Thomas/ProxmoxVE`. The upstream community project remains the source of the broader script catalog; this fork is where we make those scripts more conservative, explicit, and reviewable for sysadmin use.

## Trust Boundaries

- Host-side scripts can change Proxmox host storage, networking, VM/container configuration, and LXC device access.
- Container install scripts normally run as root inside the guest and can install packages, write services, create users, and store credentials.
- Remote downloads are part of the product, but remote code must be reviewed as a supply-chain boundary.
- Fork-owned runtime scripts must bootstrap shared helpers from this fork's `MTG-Thomas/ProxmoxVE` branch, not from the public upstream repository.
- Generated credentials, API tokens, and one-time bootstrap secrets must be treated as sensitive even when they are created locally.

## Baseline Rules

New or materially changed scripts should follow these rules unless a reviewer accepts a documented exception:

- Do not source or execute live remote code directly with `source <(curl ...)`, `bash <(curl ...)`, `sh <(curl ...)`, `curl ... | bash`, or similar patterns.
- The only allowed remote helper bootstrap pattern is a reviewed `source <(curl -fsSL https://raw.githubusercontent.com/MTG-Thomas/ProxmoxVE/main/misc/*.func)` call used by this fork's entry scripts.
- Prefer repository-local helpers or a fetch helper that pins an expected source ref and verifies downloaded content before execution.
- Avoid floating `latest` references for binaries, archives, Docker images, VM images, and installer scripts. Prefer an explicit version, digest, or checksum.
- Default LXC containers to unprivileged mode. Privileged containers require an app-specific reason.
- Avoid broad LXC device rules and Docker `--privileged`. Use targeted devices, groups, capabilities, or documented exceptions.
- Never expose the Docker API on `tcp://0.0.0.0:2375`. Localhost-only, TLS-protected, or documented break-glass access is required.
- Store generated credentials in files with mode `0600`, outside shared temporary locations. Redact secrets from logs and telemetry.
- Avoid `chmod 777`, broad recursive ownership changes, and unvalidated `rm -rf` targets.

## Exception Standard

Some apps genuinely need privileged behavior, vendor bootstrap installers, or fast-moving upstream releases. Exceptions should be explicit and easy to review:

- Name the script and the exact risky behavior.
- Explain why the safer default does not work.
- Describe the user-facing warning or prompt.
- Link to upstream documentation when possible.
- Prefer a narrow exception over a broad helper bypass.

## Scanner Role

`scripts/security-policy-scan.sh` is an advisory guardrail for this model. It intentionally reports rule families rather than every repeated line by default, so reviewers can see the shape of the risk without drowning in duplicate output.

For pull-request review, scan only changed shell files:

```bash
bash scripts/security-policy-scan.sh --changed origin/main --advisory
```

The current repository has many legacy findings. Until the backlog is retired, CI runs the scanner in advisory mode. New PRs should avoid adding findings, and hardening PRs should reduce the matching instance count.

## Hardening Order

1. Add policy checks and make new risky patterns visible.
2. Move helper loading to pinned, verified, repository-local or manifest-backed paths.
3. Add version/checksum metadata for high-risk downloads.
4. Normalize credential generation and storage.
5. Convert privileged container, device passthrough, and Docker socket behavior into allowlisted exceptions.
6. Promote the scanner from advisory to required once legacy findings are either fixed or documented.

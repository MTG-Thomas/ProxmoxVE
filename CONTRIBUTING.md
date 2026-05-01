# Contributing to the MTG Proxmox VE Helper-Scripts Fork

Welcome. This fork is maintained with a more conservative, sysadmin-oriented posture than the broad upstream catalog. Contributions should make the scripts easier to audit, safer to run as privileged automation, and more predictable on real Proxmox hosts.

The upstream documentation at **[community-scripts.org/docs](https://community-scripts.org/docs)** remains useful background. This fork adds local standards for security review, fork-owned helper loading, release pinning, and operational defaults.

---

## What This Fork Wants

Good contributions usually fall into one of these buckets:

- hardening existing scripts without changing their user-facing purpose
- replacing risky shell patterns with auditable helpers or narrower commands
- pinning high-risk downloads and documenting exceptions
- reducing privileged-container defaults where the app does not need them
- improving update/backup/restore safety
- improving local tests, advisory scanning, and documentation

This fork is not trying to be the fastest place to add new scripts. New application coverage should generally start upstream. Fork-local additions need a clear operational reason and a clear maintenance owner.

---

## Prerequisites

Before changing scripts, set up:

- **Visual Studio Code** with these extensions:
  - [Shell Syntax](https://marketplace.visualstudio.com/items?itemName=bmalehorn.shell-syntax)
  - [ShellCheck](https://marketplace.visualstudio.com/items?itemName=timonwong.shellcheck)
  - [Shell Format](https://marketplace.visualstudio.com/items?itemName=foxundermoon.shell-format)
- **ShellCheck** and **actionlint** locally. On Windows, both have native builds and can be installed with:

  ```powershell
  winget install --id koalaman.shellcheck
  winget install --id rhysd.actionlint
  ```

---

## Script Structure

Every script consists of two files:

| File                         | Purpose                                                 |
| :--------------------------- | :------------------------------------------------------ |
| `ct/AppName.sh`              | Container creation, variable setup, and update handling |
| `install/AppName-install.sh` | Application installation logic                          |

Use existing scripts in [`ct/`](ct/) and [`install/`](install/) as reference, but do not copy legacy risk patterns just because they already exist. Full upstream coding standards and annotated templates are at **[community-scripts.org/docs/contribution](https://community-scripts.org/docs/contribution)**.

---

## Contribution Process

### Adding a new script

This fork is intentionally cautious about new scripts. Prefer the upstream workflow unless the new script has a fork-specific operational purpose:

1. Fork [ProxmoxVED](https://github.com/community-scripts/ProxmoxVED) and clone it
2. Create a branch: `git switch -c feat/myapp`
3. Write your two script files:
   - `ct/myapp.sh`
   - `install/myapp-install.sh`
4. Test thoroughly in ProxmoxVED — run the script against a real Proxmox instance
5. Open a PR in **ProxmoxVED** for review and testing
6. Once accepted and verified there, the script can be considered for promotion upstream and then mirrored into this fork

Follow the coding standards at [community-scripts.org/docs/contribution](https://community-scripts.org/docs/contribution).

### Security policy checks

Script changes are reviewed against the repository's [script security model](docs/security/script-security-model.md). The advisory scanner can be run locally before opening a PR:

```bash
bash scripts/security-policy-scan.sh --advisory
```

To check only files changed from your current base branch:

```bash
bash scripts/security-policy-scan.sh --changed origin/main --advisory
```

On Windows, use Git Bash or WSL for the Bash scripts. ShellCheck and actionlint also have Windows builds and can be installed with:

```powershell
winget install --id koalaman.shellcheck
winget install --id rhysd.actionlint
```

The current repository still has legacy findings, so the GitHub Actions check is advisory. New and updated scripts should avoid adding live remote-code execution, floating high-risk downloads, unnecessary privileged containers, unauthenticated Docker socket exposure, broad `chmod 777`, or unsafe recursive deletion patterns.

When a risky pattern is genuinely required, document it in the PR. A good exception names the script, explains why the safer default does not work, describes any user-facing warning, and links to vendor or upstream documentation where possible.

---

### Fixing a bug or improving an existing script

Changes to scripts that already exist in this fork go directly here:

1. Fork **this repository** (ProxmoxVE) and clone it:

   ```bash
   git clone https://github.com/YOUR_USERNAME/ProxmoxVE
   cd ProxmoxVE
   ```

2. Create a branch:

   ```bash
   git switch -c fix/myapp-description
   ```

3. Make your changes to the relevant files in `ct/` and/or `install/`

4. Open a PR from your fork to `MTG-Thomas/ProxmoxVE/main`

Your PR should only contain the files you changed. Do not include unrelated modifications.

---

## Code Standards

Key rules at a glance:

- One script per service — keep them focused
- Naming convention: lowercase, hyphen-separated (`my-app.sh`)
- Shebang: `#!/usr/bin/env bash`
- Quote all variables: `"$VAR"` not `$VAR`
- Use lowercase variable names
- Do not hardcode credentials or sensitive values
- Prefer unprivileged containers. Privileged mode needs an app-specific reason.
- Prefer pinned versions, checksums, or digests for high-risk downloads.
- Avoid `curl | bash`, `bash <(curl ...)`, and `source <(curl ...)` except for reviewed fork-owned helper bootstraps.
- Avoid `chmod 777`, unauthenticated Docker TCP listeners, broad device grants, and unvalidated `rm -rf`.

Full standards and examples: **[community-scripts.org/docs/contribution](https://community-scripts.org/docs/contribution)**

---

## Developer Mode & Debugging

Set the `dev_mode` variable to enable debugging features when testing. Flags can be combined (comma-separated):

```bash
dev_mode="trace,keep" bash -c "$(curl -fsSL https://raw.githubusercontent.com/MTG-Thomas/ProxmoxVE/main/ct/myapp.sh)"
```

| Flag         | Description                                                  |
| :----------- | :----------------------------------------------------------- |
| `trace`      | Enables `set -x` for maximum verbosity during execution      |
| `keep`       | Prevents the container from being deleted if the build fails |
| `pause`      | Pauses execution at key points before customization          |
| `breakpoint` | Drops to a shell at hardcoded `breakpoint` calls in scripts  |
| `logs`       | Saves detailed build logs to `/var/log/community-scripts/`   |
| `dryrun`     | Bypasses actual container creation (limited support)         |
| `motd`       | Forces an update of the Message of the Day                   |

---

## Notes

- This repository does not currently carry the upstream website frontend. The GitHub Pages workflow publishes a small fork landing page.
- Upstream website metadata and catalog behavior live outside this fork. Do not assume a change here updates community-scripts.org.
- Keep PRs small and focused. One fix or feature per PR is ideal.
- PRs that fail CI checks will not be merged unless the failure is clearly unrelated and documented.

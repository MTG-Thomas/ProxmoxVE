# Proxmox VE helper scripts

This is the MTG-maintained fork of community-scripts/ProxmoxVE. Read [CONTRIBUTING.md](CONTRIBUTING.md) and [the script security model](docs/security/script-security-model.md) before changing privileged automation. `ct/` creation/update scripts pair with `install/` installers; `vm/`, `tools/`, and `turnkey/` own other operational surfaces.

Preserve upstream attribution and keep hardening changes small and auditable. New application coverage normally starts upstream; fork-local additions need an operational reason and maintenance owner. Review both launcher and installer, including loaded helpers, downloaded artifacts, update paths, and backup/restore behavior.

Default to unprivileged containers unless hardware, nesting, or device passthrough requires an explicit exception. Preserve reviewed fork-owned helper loading; upstream discovery pages may supply URLs that bypass this fork. Prefer pinned high-risk downloads and narrower permissions. Avoid unauthenticated Docker TCP sockets, broad privileged mode, `chmod 777`, unvalidated recursive deletion, and remote-code execution outside documented reviewed helper exceptions.

Run `bash scripts/security-policy-scan.sh --advisory`, or `bash scripts/security-policy-scan.sh --changed origin/main --advisory` for a scoped review. Follow applicable ShellCheck and actionlint checks in repository CI. Advisory scanner success is not proof of safe root execution. Use Git Bash or WSL for Bash checks on Windows.

Scripts can alter host storage, networking, services, credentials, containers, VMs, and application data. Source review does not authorize running them on a live Proxmox host. Verify the exact host, target IDs, changes, backup/recovery plan, and operator authorization first. Test lifecycle changes only in the approved environment and report static checks separately from actual creation, update, and recovery evidence. Preserve unrelated workloads and data.

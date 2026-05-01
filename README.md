<div align="center">
  <img src="https://raw.githubusercontent.com/MTG-Thomas/ProxmoxVE/main/misc/images/logo-81x112.png" height="112px" alt="Proxmox VE Helper-Scripts Logo" />

  <h1>MTG Proxmox VE Helper-Scripts</h1>
  <p><strong>A sysadmin-tilted fork of the Proxmox VE helper-script ecosystem</strong><br/>
  Built on the community-scripts foundation, maintained here with a stronger bias toward reviewability, conservative defaults, and operational safety.</p>

  <p>
    <a href="https://github.com/MTG-Thomas/ProxmoxVE"><img src="https://img.shields.io/badge/Fork-MTG--Thomas%2FProxmoxVE-2f6f4e?style=flat-square" /></a>
    <a href="https://github.com/community-scripts/ProxmoxVE"><img src="https://img.shields.io/badge/Upstream-community--scripts%2FProxmoxVE-4c9b3f?style=flat-square" /></a>
    <a href="docs/security/script-security-model.md"><img src="https://img.shields.io/badge/Security_model-documented-6c5ce7?style=flat-square" /></a>
    <a href="LICENSE"><img src="https://img.shields.io/badge/License-MIT-blue?style=flat-square" /></a>
  </p>
</div>

---

## What is this fork?

This fork keeps the useful breadth of the community Proxmox helper-script collection while shifting the maintenance posture toward production-minded administration.

The upstream project optimizes for broad community script availability. This fork keeps that base, but deliberately adds friction where friction helps operators:

- reviewed fork-local helper bootstraps instead of trusting public upstream helper code at runtime
- advisory security scanning for shell-script risk patterns
- preference for unprivileged containers, pinned versions, narrower permissions, and explicit exceptions
- smaller, auditable hardening PRs instead of sweeping unreviewable churn
- documentation that treats these scripts as privileged infrastructure automation

---

## Requirements

| Component      | Details                                          |
| -------------- | ------------------------------------------------ |
| **Proxmox VE** | Version 8.4, 9.0, or 9.1                         |
| **Host OS**    | Proxmox VE (Debian-based)                        |
| **Access**     | Root shell access on the Proxmox host            |
| **Network**    | Internet connection required during installation |

---

## Getting Started

This fork is intended for operators who are comfortable reading a script before running it as root. The safest workflow is:

1. Browse the script in this fork under `ct/`, `vm/`, `tools/`, or `turnkey/`.
2. Review the matching installer under `install/` when an LXC script uses one.
3. Check the [script security model](docs/security/script-security-model.md) for the current policy and known backlog.
4. Run from a Proxmox root shell only after you understand the host/container changes the script will make.
5. Prefer Advanced mode when deploying into production-like environments.

The public upstream website at [community-scripts.org](https://community-scripts.org) remains useful for discovery, screenshots, and broad script browsing. Commands copied from upstream pages may point at upstream code; adjust URLs to this fork when you want the MTG-reviewed runtime path.

---

## Operating Stance

These scripts are not ordinary application code. They are privileged automation that can change Proxmox host storage, networking, LXC device access, VM configuration, services, credentials, and application data.

Our bias in this fork:

- default to unprivileged containers unless the app has a real hardware, nesting, or device-passthrough need
- avoid live remote-code execution except for reviewed fork helper bootstraps
- pin high-risk downloads where practical
- avoid unauthenticated Docker TCP sockets, broad `--privileged`, `chmod 777`, and unvalidated recursive deletes
- preserve upstream attribution while making fork-local security decisions

See [docs/security/script-security-model.md](docs/security/script-security-model.md) for the working policy.

---

## How Scripts Work

Most container scripts follow the same pattern:

**Default mode** picks resource defaults and asks only the minimum required questions. In this fork, defaults should be conservative and easy to justify.

**Advanced mode** gives you control over container settings, networking, storage backends, and application-level configuration before anything is installed.

After installation, many containers ship with a post-install helper available from the Proxmox shell for updates, settings changes, troubleshooting, and log access.

---

## What's Included

The repository covers a wide range of categories. A few examples:

| Category        | Examples                                            |
| --------------- | --------------------------------------------------- |
| Home Automation | Home Assistant, Zigbee2MQTT, ESPHome, Node-RED      |
| Media           | Jellyfin, Plex, Radarr, Sonarr, Immich              |
| Networking      | AdGuard Home, Nginx Proxy Manager, Pi-hole, Traefik |
| Monitoring      | Grafana, Prometheus, Uptime Kuma, Netdata           |
| Databases       | PostgreSQL, MariaDB, Redis, InfluxDB                |
| Security        | Vaultwarden, CrowdSec, Authentik                    |
| Dev & Tools     | Gitea, Portainer, VS Code Server, n8n               |

> Browse the upstream catalog at **[community-scripts.org/categories](https://community-scripts.org/categories)**, then review the fork-local script before running it.

---

## Contributing

This fork accepts changes that improve operational reliability, script safety, maintainability, and compatibility with real Proxmox administration.

### Where to start

| I want to…                            | Go here                                                                                           |
| ------------------------------------- | ------------------------------------------------------------------------------------------------- |
| I want to…                            | Go here                                                                 |
| ------------------------------------- | ----------------------------------------------------------------------- |
| Harden or refactor an existing script | [Contributing Guidelines](CONTRIBUTING.md)                              |
| Report a fork-specific bug            | [Issues](https://github.com/MTG-Thomas/ProxmoxVE/issues)                |
| Report a security vulnerability       | [Security Policy](SECURITY.md)                                          |
| Compare with upstream                 | [community-scripts/ProxmoxVE](https://github.com/community-scripts/ProxmoxVE) |
| Add a brand-new upstream script       | Use the upstream process; this fork is not trying to replace ProxmoxVED |

### Before you open a PR

- This fork prioritizes hardening and refactoring existing scripts over adding new script surface area.
- Bug fixes and improvements to existing scripts belong in this repo when they serve the fork's operational posture. Read the [Contributing Guidelines](CONTRIBUTING.md) first.
- Keep PRs focused. One fix or feature per PR.
- Document privileged behavior, floating-version exceptions, generated credentials, network listeners, and destructive cleanup.

---

## Upstream Attribution

This repository is a fork of [community-scripts/ProxmoxVE](https://github.com/community-scripts/ProxmoxVE), which itself builds on the original work by [tteck](https://github.com/tteck). The scale and usefulness of this script catalog come from that community.

This fork is not an upstream replacement and does not speak for the community-scripts maintainers. Where this fork changes defaults, helper URLs, release pinning, or security checks, those decisions are local to `MTG-Thomas/ProxmoxVE`.

---

## License

This project is licensed under the [MIT License](LICENSE) — free to use, modify, and redistribute for personal and commercial purposes.

See the full license text in [LICENSE](LICENSE).

---

<div align="center">
  <sub>Built on the foundation of <a href="https://github.com/tteck">tteck</a>'s original work · <a href="https://github.com/tteck/Proxmox">Original Repository</a></sub><br/>
  <sub>Fork maintained with a sysadmin-first hardening posture · Upstream credit remains with the community-scripts project</sub><br/>
  <sub><i>Proxmox® is a registered trademark of <a href="https://www.proxmox.com/en/about/company">Proxmox Server Solutions GmbH</a></i></sub>
</div>

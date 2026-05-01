# Security Policy

This fork treats helper scripts as privileged infrastructure automation. Many
entry points are intended to run as root on a Proxmox host or inside a newly
created container, so security reports should be handled with the same care as
reports for deployment tooling.

## Supported Versions

This fork tracks the current Proxmox VE support window used by the upstream
project, with fork support focused on hardening, review, and validation of this
repository's script behavior:

| Version | Supported          |
| ------- | ------------------ |
| 9.1.x   | :white_check_mark: |
| 9.0.x   | :white_check_mark: |
| 8.4.x   | :white_check_mark: |
| 8.3.x   | Limited support* ❕ |
| 8.2.x   | Limited support* ❕ |
| 8.1.x   | Limited support* ❕ |
| 8.0.x   | Limited support* ❕ |
| < 8.0   | :x:                |

*Version 8.0.x - 8.3.x has limited support. Security updates may not be provided for all issues affecting this version.

*Debian 13 containers may fail to install. You can write `var_version=12` before the bash call.

---

## Reporting a Vulnerability

Do not publish exploit details in a public issue, pull request, Discord thread,
or discussion. Prefer GitHub private vulnerability reporting for
`MTG-Thomas/ProxmoxVE` when it is available. If private reporting is not
available, open a minimal public issue that asks for a private contact path and
does not include reproduction details.

Report fork-specific issues to this fork. Do not use the upstream
community-scripts Discord or contact address for vulnerabilities introduced by
this fork.

If the same vulnerability affects
[`community-scripts/ProxmoxVE`](https://github.com/community-scripts/ProxmoxVE),
also report it through the upstream project's preferred private channel.

When reporting a vulnerability, please provide:

- A clear description of the issue.
- The affected script, helper, workflow, or generated artifact.
- The affected Proxmox VE, Debian, or container versions.
- Safe reproduction steps, if they can be shared privately.
- Any suggested fix, mitigation, or upstream reference.

The repository's script-specific security expectations are documented in
[`docs/security/script-security-model.md`](docs/security/script-security-model.md).

---

## Response Process

1. **Acknowledgment**  
   - We will review and acknowledge private reports within **7 business days**.

2. **Assessment**  
   - Maintainers will verify whether the issue affects this fork, upstream, or both.
   - Depending on impact, a patch may be released immediately or scheduled for the next hardening pass.

3. **Resolution**  
   - Critical security fixes are prioritized over routine script refactors.
   - Non-critical issues may be documented, deferred, or declined with an explanation.

---

## Disclaimer

Not every risky script pattern is automatically a vulnerability. Reports may be
declined or reclassified if they are low-risk, out of scope for this fork, or a
documented operational exception. Public hardening ideas are still welcome as
normal issues or pull requests when they do not expose an active exploit path.

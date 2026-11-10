# Security policy

## Supported versions

Security fixes are generally made against the latest version on the default branch. There are no guaranteed backports for older versions.

## Reporting a vulnerability

Please do not report exploitable vulnerabilities in a public issue.

If GitHub's **Report a vulnerability** option is available in this repository's Security tab, use it to contact the maintainers privately. Otherwise, contact the repository owner privately through their GitHub profile. Include a concise description, affected component, impact, and safe reproduction details. Do not include real credentials, personal data, or data belonging to another user.

Please allow maintainers reasonable time to investigate and coordinate a fix before public disclosure. We will acknowledge reports and share status as we are able.

## Secrets and safety

Never commit Firebase service-account keys, passwords, Wi-Fi credentials, device tokens, private user data, or unredacted logs. Use a dedicated development Firebase project and local configuration files.

Alertify is a development project and is not a certified security, smoke, or fire alarm. See the safety limitations in [README.md](./README.md) before testing hardware.

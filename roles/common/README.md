# common

Prepares Ubuntu hosts for Pocket provider infrastructure.

Responsibilities:

- Validate supported Ubuntu releases.
- Install base packages.
- Create service users and directories.
- Configure safe system limits for relay workloads.
- Prepare firewall prerequisites.

Supported Ubuntu releases default to 22.04 and 24.04. Override `common_supported_ubuntu_versions` only after testing the target release.

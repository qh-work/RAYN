# Project Provenance

This document records the public authorship and canonical origin of RAYN Weather.

- Project: **RAYN Weather**
- Creator and maintainer: **QHWORK**
- Public GitHub identity: [@qh-work](https://github.com/qh-work)
- Canonical repository: <https://github.com/qh-work/RAYN>
- First public commit: `7120e4b0cfcfcc3977d2ae4d1d1bf41963babf4a`
- First public commit time: `2026-08-16T15:20:08+08:00`
- Signing key fingerprint: `SHA256:uEVPl4fz1ZCImZqbTbkfTAyqnhcq6QdcQiGzSleVnfs`

This public record intentionally uses the creator's established project identity, QHWORK. It does not publish or assert a legal name.

## Signature verification

Commits and annotated tags created after this provenance record are signed with the SSH key listed in [`.github/allowed_signers`](.github/allowed_signers). GitHub can independently associate that signing key with the `qh-work` account and display a **Verified** badge.

To verify the provenance commit after cloning the repository:

```sh
git -c gpg.format=ssh \
  -c gpg.ssh.allowedSignersFile=.github/allowed_signers \
  verify-commit HEAD
```

To verify the signed provenance tag:

```sh
git -c gpg.format=ssh \
  -c gpg.ssh.allowedSignersFile=.github/allowed_signers \
  verify-tag provenance-2026-08-17
```

The MIT license grants broad permission to use the project while retaining the copyright and attribution notice. Contributions by other authors remain attributable through Git history and pull requests.

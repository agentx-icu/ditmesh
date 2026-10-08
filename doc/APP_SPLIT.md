[简体中文](./APP_SPLIT.zh-CN.md)

# Application responsibilities

DitMesh and MorseCQ are independent applications preparing their first release.

| Application | Product | Identity and storage |
|---|---|---|
| DitMesh | Morse-only direct and group chat over Tox; Chat / Groups / Reference / Me | Local Tox identity, contacts, encrypted backups and conversations; `icu.agentx.ditmesh` |
| MorseCQ | Account-free offline learning; Learn / Reference / Me | Local learning progress, settings and recordings; `icu.agentx.morsecq` |

Both reuse the pure Morse engine and keying components. DitMesh also owns the Tim2Tox transport; MorseCQ has no transport, Tox identity or registration dependency. Neither application reads the other's data implicitly.

DitMesh's current encrypted backups support identity, chat components and restore previews. A `.tox` file imports a Tox identity for interoperability; it is not a full chat archive. Protect backup passphrases. MorseCQ persists learning locally without an account.

Source code was ported from MorseCQ revision `3ce9597`. The DitMesh Tim2Tox submodule is pinned to `093730ce346cef186bfd3d71214343b38d6c5ca6`. GPL-3.0 and third-party notices are retained.

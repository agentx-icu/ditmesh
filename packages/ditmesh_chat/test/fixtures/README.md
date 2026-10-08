# MorseCQ compatibility fixture

`morsecq_v2.mcqe` was exported by the unchanged MorseCQ v2 encoder at source
revision `3ce959715072bd41e1ade7020d66ca81d98050f7`, using
`Tim2ToxIdentityService.exportEncryptedBackup` and the source package's
`FakeChatEngine` / `FakeProfileCrypto` test implementations.

This is synthetic test data, not a real account or real cryptographic fixture.
The test passphrase is `legacy test passphrase`. It carries a synthetic identity
named `Legacy MorseCQ`, one inbound `CQ DE LEGACY` history row, a pinned
conversation, its `DE LEGACY` draft, and portable preferences. The fixture keeps
the actual source `morsecq-backup` manifest. DitMesh must validate it before an
explicit restore and write `ditmesh-backup` on a subsequent export.

SHA-256: `28389387a47977108261421ca2d6c32ef476f0d8639071458fde73634da0e8de`.

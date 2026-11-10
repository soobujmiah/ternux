# Ternux v1.4.0 updater migration fixture

These three source files are copied from the published `v1.4.0` Git tag at
commit `3e6c07e2afcb5f1e65ecd57af19b0382a948835a`: the installed dispatcher,
shared core, and legacy self-updater. They are retained as an immutable test
fixture so `tests/update_transaction.sh` can exercise the actual upgrade path
without network access or modifying the live Termux/PRoot installation.

The fixture test points the legacy updater at a task-local bare Git repository
whose `main` branch contains the checked-out v2 source. The fake
`proot-distro` command ensures the legacy path does not touch an installed guest.
This validates the source-level v1.4-to-v2 CLI transition; it does not replace
a published v2 release and physical-device migration test.

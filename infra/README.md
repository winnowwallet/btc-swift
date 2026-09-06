# CI infrastructure for the node-backed suite

`node-tests.yml` runs only the library differential suite on a dedicated macOS
runner with Swift, `bitcoin-cli`, and its own disposable custom-signet node.
It can be dispatched manually and is reused by the library release workflow.
PRs use hosted runners for unit, loopback, and iOS Keychain tests; they never
reach this persistent runner. App UI e2e runs in the app repository.

| Piece | Where it runs | Recreated by |
|---|---|---|
| Signet fixture (Core 31.1, custom signet) | a docker container on the host, RPC and P2P on the host's Tailscale address | `infra/fixture/bootstrap.sh` |
| macOS runner `macvm-N-btc` (labels `self-hosted, macOS, btc-swift, node-e2e`) | an OSX-KVM guest on the same host | `infra/runner/README.md` |

The current workflow uses localhost and cookie authentication. Repository
variables `BTC_SWIFT_DATADIR`, `BTC_SWIFT_RPC_PORT`, and `BTC_SWIFT_P2P_PORT`
select the dedicated runner's fixture. Provision it with
`scripts/signet-fixture up` using corresponding `WINNOW_DATADIR`,
`WINNOW_RPC_PORT`, and `WINNOW_P2P_PORT` values. The workflow verifies the node,
then runs `WINNOW_DIFF=1 swift test --filter DifferentialTests --no-parallel`.

The Docker bootstrap below is an alternative fixture layout for a separate
host; it is not the localhost/cookie configuration used by the current workflow.

## The fixture

```sh
# on the host, once per machine (or after losing the datadir)
git clone https://github.com/winnowwallet/btc-swift ~/src/btc-swift
cd ~/src/btc-swift/infra/fixture
WINNOW_RPCAUTH='rpcauth=winnow-ci:<salt>$<hash>' ./bootstrap.sh
```

Reruns are no-ops apart from the wallet check, so the same command repairs a
fixture whose container was removed or whose config drifted. A fresh datadir
starts a fresh chain at height 0, which every suite accepts: they mine what
they need. Copying a chain from elsewhere is never required.

The credential pair is created once: `rpcauth` line into the config through
`WINNOW_RPCAUTH`, `winnow-ci:<password>` into the repo secret. Bitcoin Core's
`share/rpcauth/rpcauth.py winnow-ci` prints both.

Local development keeps its own fixture on the developer's machine
(`scripts/signet-fixture up`, localhost, cookie auth). The two never share a
mempool, which matters: a transaction left in the CI fixture's mempool by a
local run once made a differential funding coinbase 770 sats too rich.

## The runner

See `infra/runner/README.md`. Cloning a macOS guest is an operator action on
the host; registering it and provisioning what the workflow needs is scripted.

## Checking

`node-tests.yml` verifies the P2P port and authenticated RPC before testing,
then uploads the differential log. Mining suites run serially so they cannot
race each other for the same tip. Unit tests run in their own CI job.

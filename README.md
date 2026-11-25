# Dummy KIO2-KIO13 Agents

An independent test-double project for KIO2 through KIO13. One standard-library Python image runs twelve containers, each with its existing agent identity and DNS endpoint. Each receiver prints the exact bounded task body and 72 hyphens, then returns a correlated success acknowledgement. It executes no tasks. Startup, health checks, and HTTP access logs remain silent.

## Build and Run

Docker Engine and the Compose plugin are required. Run from this project root:

```bash
make build
make run
```

All receivers join the external `kio1-network`; the run target creates it if absent. No ports are published. KIO1 reaches endpoints such as `http://kio7:8000/tasks`. Use separate terminals for KIO1 and UI. Build KIO1 from its own checkout and configure its local registry using its `agents.example.json`. The published [agents.dummy.json](agents.dummy.json) documents the receiver endpoints and can also be copied to a backend's deployment configuration.

Override `KIO_DUMMY_NETWORK` consistently with KIO1's `KIO1_NETWORK` and UI's `KIO_NETWORK` when using a different network. Agent service names and IDs must remain stable. Existing Compose project name `kio-dummies` and image `kio-dummy:latest` are preserved; do not run the old and new Compose stacks simultaneously on the same network.

## Testing

Python 3.10+ is sufficient; the runtime has no third-party dependencies:

```bash
make install
source .venv/bin/activate
make ci
make test-cov
```

The standalone suite does not import KIO1. Tests start disposable loopback receivers and check every agent identity, exact output, correlation, length bounds, misrouting, validation failures, and silent health checks.

Optional cross-project HTTP tests need an explicit KIO1 checkout and its runtime dependencies in the active environment:

```bash
source /path/to/kio1/.venv/bin/activate
make test-integration KIO1_SOURCE=/path/to/kio1 VENV=/path/to/kio1/.venv
```

These preserve twelve-agent sequential and parallel KIO1 dispatch coverage and verify the published registry against KIO1 validation. This is test-only coupling, not a build/runtime dependency. See [Development](docs/development.md) and the backend's workflow contract before replacing dummies with real receivers.

## Operations and Limits

For `server`, see the [deployment runbook](docs/deployment.md) for checkout, network and registry setup, health verification, updates, and troubleshooting. Ctrl+C in a local foreground run stops the dummy stack, not UI or KIO1.

Use synthetic data only. Bodies and malformed bounded JSON are printed without redaction. Dummies do not implement authentication, durable idempotency, capability validation, deadlines, durable results, or real UAV operations. Repeated tasks are printed again. Never expose receivers publicly or interpret their acknowledgement as completed work.

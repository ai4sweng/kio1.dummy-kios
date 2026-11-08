# Dummy Agent Implementation Guidance

## Ownership

[dummy_kios/server.py](../dummy_kios/server.py) implements a configured `ThreadingHTTPServer` with `GET /health` and `POST /tasks`. [compose.yaml](../compose.yaml) runs the same image once per KIO2-KIO13 identity. [agents.dummy.json](../agents.dummy.json) publishes matching task endpoints. None imports KIO1 or UI.

Preserve schema version 1.0, correlation fields, matching `Idempotency-Key`, the 1 MiB task bound, nonblank IDs, and rejection of a task addressed to another agent. Preserve exact-body output, print locking, and silent health/access behavior. Python runtime logic is unchanged by the project split.

## Verification

Activate this project's environment before writing or running tests. Reuse [tests/test_dummy_kios.py](../tests/test_dummy_kios.py), then run `make ci`. Run optional [tests/test_integration.py](../tests/test_integration.py) through `make test-integration` with an explicit KIO1 checkout and environment. Ordinary unit tests must not require sibling folders or model services.

The existing twelve-agent dispatch cases moved to the integration suite; their behavior was not removed. The already-retired KIO3-only tests are preserved unchanged in [tests/archive/test_dummy_kio3.py](../tests/archive/test_dummy_kio3.py), excluded through pytest's `norecursedirs`. They require an implementation that was already absent before this refactoring; do not treat them as active coverage.

## Real Receiver Boundary

This project is not a production receiver template. Real agents must implement authentication, persisted deduplication/results, deadline enforcement, validated capability/data contracts, and uncertainty handling as specified by KIO1's versioned workflow contract. Do not add simulated flight commands or reinterpret dummy receipts as safe actuation. Keep dummies private and use synthetic payloads.

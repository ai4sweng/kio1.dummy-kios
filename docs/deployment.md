# Deploy the dummy receivers on `server`

The dummy receivers run on the same Docker host and shared Docker network as KIO1. They do not publish host ports. This is a private test deployment: use synthetic payloads only, because task bodies are logged without redaction.

## 1. Prepare the checkout

Connect with `ssh server`. On the host, you need Git, Make, access to the Docker daemon, and the Docker Compose plugin with support for `up --wait`. You do not need a host Python environment.

Use the existing dummy-receiver checkout if there is one. For a first installation, run:

```bash
git clone https://github.com/ai4sweng/kio1.dummy-kios.git
cd kio1.dummy-kios
```

Select the branch or release approved for deployment before building. Run the remaining commands from this checkout.

## 2. Configure KIO1 connectivity

- The receivers use `kio1-network` by default. If KIO1 uses a different network, export `KIO_DUMMY_NETWORK` with the same value as KIO1's `KIO1_NETWORK` before running deployment or diagnostic commands. Set it again in new SSH sessions. If UI is part of the deployment, its `KIO_NETWORK` must also match.
- Use [agents.dummy.json](../agents.dummy.json) to configure KIO1's deployed agent registry. The KIO2-KIO13 entries use Docker DNS names such as `http://kio7:8000/tasks`, not `localhost` or the host's address. Keep any unrelated registry entries intact.
- If an older dummy stack is already serving these names on the shared network, stop that stack before starting this one. Do not stop KIO1 or remove the shared network.

## 3. Start and verify

```bash
make server-build && make server-run
make status
```

`server-run` creates the shared network if it is missing, starts the Compose project `kio-dummies` in the background, and waits for health checks. Confirm that all 12 services, `kio2` through `kio13`, are healthy. The containers remain running after SSH logout and have the `unless-stopped` restart policy.

To check Docker DNS and HTTP connectivity between containers on the shared network:

```bash
docker compose exec -T kio2 python -c "import urllib.request; print(urllib.request.urlopen('http://kio7:8000/health', timeout=3).read().decode())"
```

Expect a JSON response with `status: "ok"`, `agent_id: "KIO7"`, and `dummy: true`. This confirms receiver connectivity from `kio2`, not KIO1 registry configuration or real task execution. If KIO1 still cannot reach the receivers, check that KIO1 is attached to the same network and is using the deployed dummy registry.

## Update and troubleshoot

- **Update:** Bring the checkout to the approved revision (`git pull --ff-only` if it tracks the deployment branch), then rerun `make server-build && make server-run` and check `make status`.
- **Logs:** `make logs` follows all receivers. To follow only new entries for one receiver, run `docker compose logs -f --tail 0 --no-log-prefix --no-color kio7`. Startup, health checks, and HTTP access produce no routine output, so idle logs are normal.
- **Import `PermissionError` after an upgrade:** Rebuild with `make server-build`, then run `docker compose up -d --wait --force-recreate`.
- **Stop or remove:** `make stop` stops the receivers; `make down` removes the dummy stack's containers but leaves the external network and KIO1 data alone. Do not prune unrelated Docker resources.

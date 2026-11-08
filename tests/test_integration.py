"""Optional cross-project checks; run with KIO1 on PYTHONPATH."""

import threading

import pytest

from dummy_kios.server import AGENT_IDS, DummyKIOServer

pytestmark = pytest.mark.integration


def test_registry_is_accepted_by_kio1() -> None:
    """Keep the published dummy registry compatible with KIO1's validation."""
    from pathlib import Path

    planner = pytest.importorskip("workflow_planner")
    registry = planner.load_agent_registry(
        Path(__file__).parent.parent / "agents.dummy.json"
    )
    assert set(registry) == AGENT_IDS


@pytest.mark.parametrize("mode", ["sequential", "parallel"])
def test_kio1_can_dispatch_to_all_twelve_agents(mode: str) -> None:
    """Complete real KIO1 HTTP dispatch for every catalog agent."""
    prompt_loader = pytest.importorskip("prompt_loader")
    planner = pytest.importorskip("workflow_planner")
    catalog = prompt_loader.load_capabilities()
    servers = []
    workers = []
    registry = {}
    try:
        for agent_id in sorted(AGENT_IDS):
            server = DummyKIOServer(("127.0.0.1", 0), agent_id)
            servers.append(server)
            worker = threading.Thread(
                target=server.serve_forever, kwargs={"poll_interval": 0.01}, daemon=True
            )
            workers.append(worker)
            worker.start()
            registry[agent_id] = {
                "endpoint": f"http://127.0.0.1:{server.server_port}/tasks"
            }
        plan = {
            "workflow_id": "wf-twelve-agents",
            "execution_mode": mode,
            "steps": [
                {
                    "step_id": f"s{index}",
                    "agent_id": agent_id,
                    "capability": catalog[agent_id]["capabilities"][0],
                    "task": "Receive test only",
                }
                for index, agent_id in enumerate(sorted(AGENT_IDS), 1)
            ],
        }
        result = planner.dispatch_workflow(plan, registry)
        assert result["status"] == "succeeded"
        assert len(result["steps"]) == 12
        assert {step["result"]["agent_id"] for step in result["steps"]} == AGENT_IDS
    finally:
        for server in servers:
            server.shutdown()
        for worker in workers:
            worker.join(timeout=2)
        for server in servers:
            server.server_close()

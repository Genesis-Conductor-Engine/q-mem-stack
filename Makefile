SHELL := /bin/bash

.PHONY: help orchestrate simulate sdk

help:
	@echo "Available targets:"
	@echo "  orchestrate  Run GitHub orchestration (use ORCH_ARGS=\"...\")"
	@echo "  simulate     Run Diamond Vault local simulation"
	@echo "  sdk          Install the Python SDK in editable mode"

orchestrate:
	./scripts/orchestrate_swarm.sh $(ORCH_ARGS)

simulate:
	./scripts/run_diamond_vault_sim.sh

sdk:
	pip install -e ./sdk

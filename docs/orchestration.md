# Power Tower Orchestration (Repo-Ready)

This repository includes a hardened orchestration flow designed for GitHub CLI automation.

## Script
Use the orchestration script to create labels and issues idempotently:

```bash
scripts/orchestrate_swarm.sh --repo q-mem-stack --visibility public
```

## Makefile / Taskfile
- `make orchestrate` or `task orchestrate` runs the orchestration script.
- `make simulate` or `task simulate` runs the Diamond Vault local simulation.
- `make sdk` or `task sdk` installs the SDK in editable mode.

## Why this is better
1. **Valid Bash**: strict mode and argument parsing prevent accidental misuse.
2. **Safer execution**: idempotent repo/label/issue creation avoids half-deploys.
3. **CLI robust**: uses `gh` checks, explicit `--repo`, and avoids brittle heredocs.
4. **Maintainable**: labels and issues are encapsulated in functions.
5. **Repo-aligned**: integrates Makefile/Taskfile plus local simulation scaffolding.

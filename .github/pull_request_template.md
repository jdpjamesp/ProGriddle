## What and why
<!-- What does this change, and why? -->

## How I checked it
- [ ] `tools/run-tests.ps1 -All` passes (I ran it locally: the checks on GitHub cannot run OpenEdge)
- [ ] `tools/check-layering.ps1`, `tools/compile.ps1` and `tools/audit-conventions.ps1` are clean
- [ ] For a window change, I ran the game's smoke test
- [ ] For a new game, I started from `tools/new-game.ps1`, and `tools/check-template.ps1` still passes if I touched the framework

## Docs
- [ ] Docs changed in the same commit as the code (a new game has its docs/games page, linked from the README)
- [ ] No em dashes anywhere

## Framework changes
- [ ] None, or the change is in Core or Engine with its own tests, not a special case for one game

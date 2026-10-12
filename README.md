# ProLific

An OpenEdge ABL OO framework for grid based games. First target is Conway's Game of Life, then Minesweeper, Battleships and Tetris to prove the framework.

Status: Phase 0 (environment spike). Nothing is playable yet.

## Requirements

- OpenEdge 12.8 on Windows (r-code is tied to the OpenEdge version, so build from source).
- `prowin` for the GUI, `_progres -b` for batch tests.
- PowerShell for the helper scripts. If scripts are blocked, run them as `powershell -NoProfile -ExecutionPolicy Bypass -File <script>`.

## How to build and test

There is no separate build step. ABL source is compiled on the fly by the test runner.

```
powershell -NoProfile -ExecutionPolicy Bypass -File tools/run-tests.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File tools/run-tests.ps1 -Filter "Grid*"
powershell -NoProfile -ExecutionPolicy Bypass -File tools/check-layering.ps1
```

- `run-tests.ps1` finds every `tests/**/*Tests.cls`, runs them through ABLUnit in batch mode and writes `build/test-results/results.xml`. It exits non-zero on any failure or error.
- The install location comes from `$env:DLC`, defaulting to `C:\Progress\OpenEdge`.
- `check-layering.ps1` enforces the layering rules (see `CLAUDE.md`). It needs no OpenEdge install and runs in GitHub Actions.

Things worth knowing about this environment:

- `_progres` ignores the PROPATH environment variable, so `tools/run-tests.p` sets `PROPATH` in code.
- ABLUnit returns exit code 0 even when tests fail, so the script judges success from the results XML.
- The ABLUnit output folder must exist before the run. The script creates it.

## Project setup

`openedge-project.json` defines the PROPATH for the VS Code OpenEdge extension: `src`, `tests` and `run`. The extension also reads the OpenEdge install path from `.vscode/settings.json`, which is not committed because it is machine specific. Create it with:

```json
{
  "abl.configuration.runtimes": [
    { "name": "12.8", "path": "C:\\Progress\\OpenEdge", "default": true }
  ]
}
```

## Manual GUI checklist

To be written once the GUI spike is done.

## Benchmarks

To be recorded from the Phase 0 storage benchmark.

## Licence

MIT, see `LICENSE`.

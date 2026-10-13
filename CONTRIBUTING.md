# Contributing to ProGriddle

ProGriddle is an OpenEdge ABL object oriented framework for grid based games, and a handful of games built on it. Contributions are welcome: a new game, a better rule or engine, a fix, a clearer page. This page is how to get started and what a good change looks like.

If you want to add a game, read [Adding a game](docs/adding-a-game.md) first. It starts from a command that creates a working game, so you begin with something that compiles, passes its tests and has a button in the Cookoff.

## Getting running

You need OpenEdge 12.8 or higher on Windows, and PowerShell. There is no build step. From the repository root:

```
powershell -NoProfile -ExecutionPolicy Bypass -File tools/run-tests.ps1 -All
cookoff.bat
```

The first runs every test, plain and WinForms. The second opens the Cookoff, one window with a button for every game. [The README](README.md#requirements-and-quick-start) has the details, including the OpenEdge install location (`DLC`) and the VS Code setup.

## How a change goes

1. **Write the test first** where you can. Every public method has a test, and a bug fix comes with a test that fails without it.
2. **Make it work**, running the tests for what you touch: `tools/run-tests.ps1 -Filter "Tetris*"`.
3. **Run the whole of it** before you ask anyone to look:

   | Command | What it checks |
   |---|---|
   | `tools/run-tests.ps1 -All` | Every test, plain (`_progres -b`) and WinForms (`prowin -b`) |
   | `tools/check-layering.ps1` | That each layer only uses the layers below it (below) |
   | `tools/compile.ps1` | That everything compiles, listing every error at once |
   | `tools/audit-conventions.ps1` | The rules of the codebase that a script can check: a header comment and `BLOCK-LEVEL` on every class, wildcard `USING`, no dashes, `MEMPTR` freed, every public member in some test |
   | `tools/check-template.ps1` | After a change to the framework interfaces or to `templates/game`: that a game made from the template still compiles and passes its tests |
   | `tools/gui-smoke-<game>.ps1` | The real window, for a game you changed (see the warning below) |

4. **Commit in small steps**, one per sub step, each with a message that says what changed and why. Do not mix a refactor with a behaviour change.

The smoke tests drive the real window with real keystrokes and mouse clicks, so they take over the keyboard and mouse for a minute or a couple of minutes. Start one, then leave the machine alone until it says it passed.

### What the checks on GitHub cover

Every push to `main` and every pull request runs `tools/check-layering.ps1` and `tools/audit-conventions.ps1` on a hosted Windows machine (`.github/workflows/checks.yml`). They need no OpenEdge, so a change that breaks the layering or a convention shows a red cross on the pull request.

They do **not** compile the code, run the tests or run the smoke tests: OpenEdge is not installed there, and the smoke tests need a real desktop. A green tick means the structure and style are fine, not that the code works. That is why the pull request template asks you to confirm you ran `tools/run-tests.ps1 -All` yourself.

## The rules of the codebase

The full list, with the reasons, is in [CLAUDE.md](CLAUDE.md). The ones you meet first:

- **OpenEdge ABL object oriented code only.** One class per file, and the namespace matches the folder path.
- **`USING` statements, always in the wildcard form**, one line per namespace (`USING ProGriddle.Core.*.`). Never a fully qualified name inline.
- **`BLOCK-LEVEL ON ERROR UNDO, THROW.`** in every class, between the `USING` statements and `CLASS`. Without it a thrown error prints and carries on.
- **Program against interfaces.** Concrete classes are created only in the composition roots (the `run/run-*.p` files) and in tests.
- **Throw `GridException`** (or a subclass) for a broken contract. Never return a magic value.
- **No object allocation inside a loop over cells.** Boards have tens of thousands of cells and ABL objects are not free.
- **Free what you allocate.** Every `MEMPTR` is set back to size 0 as soon as you finish with it (in `FINALLY` when it is local, in `Dispose` when an object owns it). Dispose .NET objects and unsubscribe from .NET events when the window closes.
- **All randomness goes through `IRandom`**, so a seed makes a test repeatable.
- **No em dashes** anywhere: not in code comments, docs, commit messages or console output. Use commas, colons or hyphens.
- **Keep it readable.** Match the code around you in naming, comment density and style. A class has a header comment saying what it is for.

### Layering

`tools/check-layering.ps1` enforces this, and a change that breaks it does not merge:

```
Core                depends on nothing
Engine              depends on Core
UI.Text             depends on Core and Engine
UI.WinForms         depends on Core, Engine and UI.Text, and is the only layer that may use .NET
Games.<Game>        depend on Core and Engine only: never on another game, never on UI.WinForms
```

So a game compiles and is tested with no window at all, and the window knows nothing about any game. If a game needs something the framework does not give it, change the framework and its tests. Do not special case the game inside `Core` or `Engine`.

### ABL gotchas that have already cost an afternoon

[OpenEdge environment notes](docs/framework/environment.md) has the full list. The short one:

- Some harmless looking words are ABL keywords and cannot be variable names: `text`, `entry`, `by`, `old`, `line`, `first`, `group`, `off`, `now`, `status`, `current`, `last`, `key`, `font`, `row`, `col`, `header`, `find`, `clear`, `pause`, `undo`, `run`. The compiler says "The keyword x may not be used as a name".
- Text comparison ignores case, so `"X"` equals `"x"`. Never use two letters that differ only by case as different symbols.
- In a string `~` is the escape character, and never write `*/` inside a comment, even in an example.
- A `CHARACTER` under `prowin` is ISO 8859-1. Anything outside Latin 1 (a flag, a bomb) must be a code point passed as UTF-8.
- ABLUnit's `@Setup` and `@TearDown` run around every test (the reverse of JUnit), `@Before` and `@After` run once per class, and ABLUnit exits 0 even when tests fail, so use `tools/run-tests.ps1`, which reads the results and sets the exit code.

## Documentation

- `README.md` documents the framework and how to create a game. Game specific material (controls, settings, timings, design notes) does not belong in it.
- **Every game has its own page**, `docs/games/<game>.md`, written as part of the game's work and linked from the README's Games list. A game is not finished until the page exists.
- `docs/framework/` holds the measurements and the OpenEdge notes.
- When you change what a document describes, change the document in the same commit.

## What a good pull request looks like

- It does one thing, and its description says what and why.
- Tests for new behaviour, and `tools/run-tests.ps1 -All` is green.
- `tools/check-layering.ps1` and `tools/compile.ps1` are clean.
- Docs updated, and a smoke test run for any window you changed.
- No debugging leftovers, no commented out code, no files from `build/`.

## Questions and ideas

Open an issue on the repository. A game idea is welcome as an issue before any code: say what kind of game it is (steppable, turn based or real time) and what it would need that the framework does not have yet. That is the useful part, because the best games to add are the ones that stretch the framework.

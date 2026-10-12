# ProLific conventions

OpenEdge ABL OO framework for grid based games. Target: OpenEdge 12.8, Windows, prowin GUI via WinForms and the ABL .NET bridge. Namespace and source root: `Prolif` (`src/Prolif/...`). The build brief is `PROLIFIC_PLAN.md` (local only, not in git).

## Rules
- OpenEdge ABL OO only. One class per file. Namespace matches folder path.
- Always use `USING` statements, never fully qualified names inline.
- Program against interfaces. Concrete classes are created only in composition roots (the `run-*.p` files and tests).
- Prefer `FINAL` on classes not designed for inheritance. Mark abstract methods explicitly.
- No object allocation inside per cell loops.
- Every class file has `BLOCK-LEVEL ON ERROR UNDO, THROW.` between the USING statements and the CLASS statement. Without it, `UNDO, THROW` prints the message and execution carries on instead of unwinding. A class also needs a `USING` for its own name before it can use its own type.
- Every MEMPTR must be reset to size 0 (`SET-SIZE(m) = 0`) as soon as it is finished with, so memory never leaks. A MEMPTR allocated inside a method is freed in that method's `FINALLY` block. A MEMPTR owned by an object is freed in a `Dispose` method, with a destructor as a safety net, and the object's owner calls `Dispose`.
- Never name a method `Clone`, `Equals` (unless overriding), `ToString` (unless overriding) or any other inherited `Progress.Lang.Object` member by accident. The cell store copy method is `Duplicate`.
- ABLUnit fixture annotations are the reverse of JUnit: `@Setup` and `@TearDown` run around every test, while `@Before` and `@After` run once per class. ABLUnit also does not run `@Test` methods inherited from a base class.
- Throw `Prolif.Core.GridException` (or a subclass) for contract violations, never return magic values silently.
- All randomness goes through an injectable seeded random source so tests are deterministic.
- Every public method has a test. Write the test first where practical.
- No em dashes anywhere in code comments, docs, commit messages or console output. Use commas, colons or hyphens instead.
- Keep commits small, one per sub step, with a clear message.
- .NET types (`System.Windows.Forms`, `System.Drawing`) are referenced only inside `Prolif.UI.WinForms`. Core, Engine and Games must compile and test without a GUI.
- Dispose .NET objects (brushes, pens, bitmaps, timers) deterministically. Unsubscribe from .NET events when the form closes.
- Never run long computation on the UI thread without yielding. Large Life boards must stay responsive.
- If the framework needs changing to support a game, change the framework and update its tests. Do not special case a game inside Core.
- Use the progress-abl skill when writing or reviewing ABL.

## Layering (checked by tools/check-layering.ps1)
Core depends on nothing. Engine depends on Core. UI.Text depends on Core and Engine. UI.WinForms depends on Core, Engine and UI.Text and is the only layer that may use .NET. Games depend on Core and Engine only and never on another game or on UI.WinForms.

## Commands
- Tests: `powershell -NoProfile -ExecutionPolicy Bypass -File tools/run-tests.ps1 [-Filter "Grid*"]`
- Layering: `powershell -NoProfile -ExecutionPolicy Bypass -File tools/check-layering.ps1`

## Environment notes (found in Phase 0)
- The PROPATH environment variable is ignored by `_progres`. `tools/run-tests.p` sets PROPATH in code.
- ABLUnit exits 0 even when tests fail. `tools/run-tests.ps1` reads `build/test-results/results.xml` and sets the exit code itself.
- The ABLUnit output folder must exist before the run (the script creates it).

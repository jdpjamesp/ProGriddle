# OpenEdge environment notes

Things found the hard way while building ProGriddle on OpenEdge 12.8.0.1207, Windows 11. Most are also summarised as rules in `CLAUDE.md`.

## Running things

- `_progres -b` runs batch programs and ABLUnit. `prowin -b` can do the same and, unlike `_progres`, can also load and draw WinForms classes, so the WinForms tests run under it (`tools/run-tests.ps1 -Gui`).
- Under `prowin -b` there is **no .NET message loop**. Timers never tick and `Application:Run` fails ("You can only use the .NET event loop in a GUI application"). `PROCESS EVENTS` does not dispatch .NET messages either, and `Application:DoEvents` is forbidden in ABL. Anything that needs real ticks or real input is checked in a windowed run (`tools/gui-smoke-life.ps1`).
- The `PROPATH` environment variable is ignored by `_progres`. Set `PROPATH` in code. `tools/run-tests.p` and `tools/launch.p` do this, and they set it before the program they run is compiled, which is why programs are started through them (a `USING` is resolved at compile time).
- The ABL .NET bridge targets .NET Framework 4.x (CLR v4.0.30319), not modern .NET. `USING System.Windows.Forms.* FROM ASSEMBLY.` and `System.Drawing` work in the standard way.
- A program started with `WAIT-FOR Application:Run(form)` should be followed by `QUIT`, or `prowin` stays running after the window closes.
- ABL cannot override the .NET `Dispose` method, so a control that owns memory exposes `ReleaseResources` and its owner calls it.

## Testing with ABLUnit

- ABLUnit returns exit code 0 even when tests fail. `tools/run-tests.ps1` reads the results XML and sets the exit code itself.
- The ABLUnit output folder must exist before the run, and a custom results file name is ignored, so each suite uses its own folder (`build/test-results/` and `build/test-results/gui/`).
- ABLUnit does not run `@Test` methods inherited from a base class. Shared contract tests loop over the implementations inside each test instead (see `CellStoreContractTests`).
- Fixture annotations are the reverse of JUnit: `@Setup` and `@TearDown` run around **every test**, while `@Before` and `@After` run **once per class**.
- `@Test (expected="ProGriddle.Core.GridException")` works for tests that should throw.

## Language gotchas

- Every class needs `BLOCK-LEVEL ON ERROR UNDO, THROW.` between the `USING` statements and the `CLASS` statement. Without it, `UNDO, THROW` prints the message and execution carries on.
- A class needs a `USING` that covers its own namespace before it can name its own type.
- ABL keywords that cannot be used as variable names, and some that cannot be called as a statement: `text`, `entry`, `by`, `old`, `line`, `clear`, `pause`, `undo`, `run`, `count`, `fill`, `index`, `value`, `release`, `row`, `is` (as an index name). Check any new name against the keyword list.
- Do not name a method `Clone`, `Equals` or `ToString` unless overriding the inherited one. The cell store copy method is `Duplicate` for this reason.
- Hyphens are legal in names, so `a-b-1` is one name. Put spaces round `-` in arithmetic.
- `MODULO` keeps the sign of its first operand, so a negative number needs a second step to wrap (`((x MODULO n) + n) MODULO n`).
- `TRUNCATE` returns a decimal. Wrap it in `INTEGER(...)` when returning an integer.
- A newly defined `CHARACTER` or `INTEGER` variable is empty or zero, not unknown. Assign `?` on purpose when you want the unknown value.
- `{` starts a preprocessor reference, even inside a string. Write `~{` for a literal brace.
- `JsonObject:Add` fails on a key that already exists and `Set` fails on a key that does not, so remove before adding or check with `Has`.
- ABL string comparison ignores case, so `"space" = "Space"`.
- Free every `MEMPTR` with `SET-SIZE(m) = 0`. A `MEMPTR` allocated in a method is freed in that method's `FINALLY` block. A `MEMPTR` an object owns is freed in `Dispose`, with a destructor as a safety net. A new `MEMPTR` is zero filled.
- `COPY-LOB FROM mem FOR n TO other OVERLAY AT 1` copies between two `MEMPTR`s in one step, and the target can be passed into a method as `INPUT` and still receive the bytes.
- A `System.Drawing.Bitmap` can be built over a `MEMPTR` with `NEW Bitmap(width, height, stride, PixelFormat:Format32bppRgb, NEW System.IntPtr(GET-POINTER-VALUE(m)))`. Dispose the bitmap before freeing the memory.
- Never write `*/` inside a comment, even in an example string such as `"*/."`: it ends the comment early and the compiler then complains about the next lines, far from the cause.
- A `CHARACTER` in a `prowin` session is ISO 8859-1, so any other character, such as a flag or a bomb, silently becomes `?` when assigned. To hand a real Unicode string to .NET, build its UTF-8 bytes in a `MEMPTR`, copy them into a `LONGCHAR` with `FIX-CODEPAGE(lc) = "UTF-8"` and `COPY-LOB ... CONVERT SOURCE CODEPAGE "UTF-8"`, and pass the `LONGCHAR` (see `GridView:SetGlyphs`).
- A dynamic `EXTENT` is limited (the reference says 28000), so a per cell array on a big board is better kept in a `MEMPTR`.

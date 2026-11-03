---
trigger: always_on
---

Activation Mode

Always On
This rule will always be applied
Content
# AI Instructions: Quarto + Typst + Julia Workflow

## 📝 Document Context
You are an expert structural engineer and writer, and Julia developer. This project uses **Quarto** (`.qmd`) as the orchestrator, **Typst** for high-fidelity PDF typesetting, and **Julia** for computations.

## 🔧 Tool Discovery (enggtoolsmcp)
- When an agent is prompted from the root of a Quarto (`.qmd`) project, it must **always first search `enggtoolsmcp` for available tools** before starting work.
- Treat `enggtoolsmcp` as the default source for engineering tools, and prefer its tools over ad-hoc alternatives when a suitable one exists.
- For `.qmd` projects, a separate **reviewer is not needed** when the output is produced by these tools — the tool results are authoritative and can be used directly without a review step.
- For `.qmd` projects, when the output comes from `enggtoolsmcp`, there is **no need to render the `.qmd`** — skip the Quarto/Typst render step and use the tool output directly.

## ⚙️ Execution Rules (Julia)
- Use executable blocks: ` ```{julia} ... ``` ` (with curly braces) for Julia code that must run.
- Use ` #| ` for block-level options (e.g., `#| label: fig-1`, `#| echo: false`).
- Default to  `Plots.jl` libraries for visualizations unless otherwise specified.
- Ensure all Julia packages are referenced in the local `Project.toml`.

## 🧹 Formatting (trailing comments)
- Align trailing `#` comments with the bundled script, never by hand and never by
  respacing code: `julia _align_comments.jl --write <file>` (add `--gap N` to
  change the minimum spaces before `#`; default 2). Drop `--write` for a
  stdout-only preview.
- It only rewrites lines that carry code **and** a trailing `#` comment, and only
  inside ```` ```{julia} ```` blocks of a `.qmd`, so prose, headings and Typst
  blocks are left untouched. It does not reformat anything else — run it after
  JuliaFormatter, not instead of it.
- VS Code tasks `Align comments (preview)` / `Align comments (write)` do the same
  for the open file (save first — the task reads from disk). They are defined in
  `.vscode/tasks.json`, which `quarto use template` does not copy (dotfiles are
  skipped); when the file is absent, use the terminal command above. The write
  task is the default *build* task, so `Ctrl+Shift+B` (`Cmd+Shift+B` on macOS)
  runs it with no keybinding setup — but it still needs `.vscode/tasks.json`
  present in that folder.
- An `Alt+A` shortcut has to be added to the **user** `keybindings.json`
  (not `Ctrl+Alt+A` — that is Antigravity's *Archive conversation*)
  (VS Code/VSCodium have no workspace keybindings): `"command":
  "workbench.action.tasks.runTask", "args": "Align comments (write)"`. Do not use
  the Better Align extension for this.
- If `Alt+A` does nothing, diagnose before changing anything: run *Developer:
  Toggle Keyboard Shortcuts Troubleshooting*, focus the `.qmd`, press `Alt+A`
  and read the resolver line — `No keybinding entries` means unbound (missing
  entry, wrong app/profile, or a `keybindings.json` syntax error), `no when
  clauses matched the context` means the `when` clause is false (focus must be in
  a writable editor), and `matched <other command>` means a keybinding owns the
  key — an extension or an app default; the log's `source:` field says which.
  `Ctrl+Shift+B` (*Tasks: Run Build Task*) is the fallback: no keybinding needed,
  but `.vscode/tasks.json` must be present.

## 📏 Units and Quantities (Unitful)
- **Keep units attached — do not strip them just because it is convenient.** Every physical quantity must stay a `Unitful` quantity (e.g. `12.5u"kN"`, `3.2u"m"`) from input through to printed output. Never store a bare number that silently loses its dimension. (The custom units `ksi`, `kipf`, … are registered by `MyUnits`, and the `u"..."` macro comes from `Unitful` — both loaded in the `template.qmd` preamble.)
- Assign into typed fields with the unit included (`σ = 250u"MPa"`), and give documented unit annotations/defaults rather than raw `Float64` values.
- **Do not strip units for plotting.** `Plots.jl` consumes `Unitful` data directly: when the vectors you hand it are declared up front with units (`x = [1.0, 2.0, 3.0]u"m"`, `M = [12.5, 18.0]kNm`), the plot works and the axes are labelled with the units. Keep the data unitful through the plot call. (Plots strips units internally for the axis labels and converts compatible units onto one axis; series whose dimensions differ cannot share an axis.)
- For a non-SI axis scale, stay unitful: set the axis unit on the **first** series (`plot(x, M; yunit = kNm)` — MyUnits' `kNm` labels the axis `kN⋅m`, whereas a loose product `u"kN*m"` prints as `m kN`) and never convert or strip the data — the axis unit is a label, not a data transform.
- The only cases that need special handling (never `ustrip`/`uconvert`):
  1. an API that requires a dimensionless `Float64` (recipe below), or
  2. the quantity is raised to a power that is not an exact short rational — an **irrational** exponent (`q^π`, `q^sqrt(2)`) or a Float64 approximation (`q^0.3`; `q^(1/3)` is `6004799503160661/2^54`, while `q^(1//3)` is exact and clean). Unitful folds the exponent into a monstrous rational (`m^5404319552844595/18014398509481984`) that can no longer be simplified or converted; compute the power on the number in its own unit instead: `(q / unit(q))^p`.
- **When a `Float64` is expected from an expression carrying quantities, normalise to SI base units, drop the unit, then convert the value type:**
  ```julia
  # illustrative: M and Z are quantity-valued inputs
  f = upreferred(M / Z)                     # dimensionless ratio → plain Float64
  ```
  `upreferred(x)` is a `Float64` only when `x` is dimensionless; a dimensioned quantity stays a `Quantity` (an integer-valued one carries `Int64` or `Rational{Int64}` backing values — `250u"MPa"` → `250000000`, `1u"cm"` → `1//100`), so keep it as a quantity or divide by its unit at a genuine number boundary.
  Do **not** call `ustrip(x)`: `ustrip(1u"cm")` yields `1`, not `0.01`, corrupting the result by an invisible unit factor. `Float64(x)` is not a substitute either: it only changes the backing value type and returns a `Quantity` with the *same* units (`Float64(1u"cm") == 1.0u"cm"`), so it never produces a bare number.
- When feeding a value back to a quantity-typed API, re-attach an explicit unit (`value * u"m"`, `value * u"Pa"`) rather than relying on implicit assumptions.
- **Formatting quantities in labels/text: don't decompose them.** Interpolate the rounded quantity and let `Unitful` print the unit, e.g. `M = 42.1534kNm` (MyUnits' `kNm`, printed as `kN⋅m`) → `"M* = $(M |> f2)"` → `"M* = 42.15 kN⋅m"`. Use `f0`–`f3`/`fround` from `MyUnits`; never `string(ustrip(...)) * " kN⋅m"`, and never re-attach units by hand (`* u"m"`, `* 1°`) just for display. Construct the value with the symbol you want to print (`42.1534kNm` prints `kN⋅m`; a loose product `u"kN*m"` prints `m kN`). `round(q; digits=n)` on a `Quantity` is **not** a substitute — it errors, or (for dimensionless units like `°`) rounds the SI-base value and drops the unit.

## 🎨 Typesetting Rules (Typst)
- When writing raw Typst blocks, use: ` ```{=typst} ... ``` `
- Remember that Typst uses `#` for functions (e.g., `#rect()`) which differs from Quarto's Markdown headers.
- If using a custom Typst template, reference it in the YAML header under `format: typst: template: my-template.typ`.
- For displaying Julia variables, use `{julia} ... ` (with curly braces)  for inline.

## 🚫 Critical Constraints
- **JULIA-ONLY CODE CHUNKS:** All code chunks are Julia only, nothing else. Do not use any other language in executable code chunks.
- **NO LATEX:** Do not use LaTeX commands; use native Typst syntax or Quarto cross-references (`@fig-label`).
- **Syntax Boundaries:** Never place Julia code inside a ````{=typst}` block. Julia must stay in ````{julia}` blocks.

## Unit rules (Unitful.jl)

These rules are mandatory in this package. Breaking them produces **silently
wrong numbers**, not exceptions.

### R1 — Never strip units; normalise with `upreferred`

`ustrip` and `uconvert` are **banned**. `ustrip` does not convert to SI — it
drops the unit and keeps the number in whatever unit the value happened to be
stored in, so units never cancel. The only permitted normalisation is
`upreferred`, which rewrites the quantity in SI base units and hands back a
plain `Float64` as soon as the result is dimensionless.

```julia
# WRONG — the result depends on how each value happened to be stored
r = ustrip(x) / ustrip(y)        # 0.5u"m" / 500u"mm" → 0.001   (should be 1.0)
r = ustrip(x) * ustrip(y)        # 2u"kN" * 300u"mm" → 600, not 0.6 N·m
r = ustrip(x / y)                # 500u"kN" / 1.0u"MN" → 500.0 (should be 0.5)

# RIGHT — upreferred normalises the ratio and already returns a plain Float64
r = upreferred(x / y)            # 500u"kN" / 1.0u"MN" → 0.5

# RIGHT — products keep their dimensions; keep the Quantity
t = x * y                        # 2u"kN" * 300u"mm" → 0.6 kg m^2 s^-2
```

Every dimensionless result — utilisation `M/(ϕM_s)`, slenderness
`(b/t)·√(f_y/250)`, strain, `a/d`, `I/A`, `k = I/A`, `M/EI` — must be built this
way, or simply left as a `Quantity` and compared/plotted as a quantity.

### R2 — `ustrip` and `uconvert` are banned

- `ustrip(u"mm", x)` and `ustrip(x)` are both forbidden: they keep whichever
  unit the value happened to carry and silently change the number.
- `uconvert` is forbidden too. There is no "convert for display" path — display
  a quantity by interpolating it (R3).
- To express a value in another unit, do the arithmetic inside the unit system
  (`x / 1.0mm`, `x / kNm`) or keep it as a `Quantity`; never convert it to a
  bare number.

### R3 — Display a quantity by interpolating it

Unitful already renders the unit, so stripping only risks the printed unit
disagreeing with the number:

```julia
# WRONG / redundant
"$(ustrip(u"mm", L))mm"    # suffix can drift out of sync with the conversion
"$(ustrip(θ))°"            # prints radians next to a degree sign

# RIGHT
"$L"                       # "500.0 mm"
"$(L |> f2)"               # "500.00 mm"   (rounded via MyUnits.f2, unit retained)
```

`f2`/`fround` from `MyUnits` round the value and re-attach the unit, so the
label carries both. Keep data in the unit you want to print (`x = [1.0, 2.0]m`)
instead of converting at print time.

### R4 — Foreign API boundaries

Only a foreign API that cannot accept a `Quantity` (a Python call, a numeric
solver) may see a bare number. Isolate it in one adapter function that names
the unit it expects, normalises with `upreferred` first, and re-attaches the
unit on return. Never strip inside calculation code.

### R5 — One unit system per foreign call

Python round-trips (sectionproperties / concreteproperties) are fed **mm, N, MPa,
N·mm** here. Never mix a value normalised in one system with a bare number
computed in another.

### Using Unitful — CRITICAL

- **DO NOT USE `uconvert` OR `ustrip` BY ANY MEANS.** Units can be stripped only by normalising with `upreferred`, except when dealing with angles — they have their own rules.
- When a code formula specifies a base unit (e.g. `sqrt(250/Fy)`, where `Fy` must be in `MPa`), then normalise by `upreferred(250/(Fy/MPa))^0.5`.
- **DO NOT STRIP UNITS, BY ALL MEANS** — keep `Unitful` quantities through all calculations.
- **Do not strip units for fractional powers.** `sqrt`, `x^0.5` and `x^(1//3)` all
  work on quantities — Unitful keeps fractional dimensions — so keep the quantity.
  If an irrational exponent (`x^π`) or a bare number is genuinely required,
  normalise with `upreferred` first and use the dimensionless result.
- **Use `MyUnits.jl` and always append units, for example length unit meter as `m` instead of `u"m"`.**
- **Use priority units in `MyUnits.jl`, then in `Unitful.DefaultSymbols`.**
  `MyUnits` must be loaded **after** `Unitful` so its shorthands (`m`, `kPa`, `kN_per_m`, `kNm`, `yr`, `m_per_s`, `f2`, `fround`, etc.) take priority
  (see the module's import list). Do not add `using Unitful` after `using MyUnits`.
  Examples: `γ = 18kN/m^3`, `D = 0.6m`, `Ht = 7.4m`, `p = 50kPa`, `q = 15kN_per_m`.
- All dimensions/forces/pressures are `Unitful` quantities. Never mix raw floats into quantities.
- Rounding helpers from `MyUnits`: `f2(x)` → 2 decimals (`x |> f2`), `fround(x,n)`, `f0/f1/f3`.
  They are **unit-preserving** (round the value, re-attach the unit), so **never decompose a
  quantity to format a label/string** — interpolate the rounded quantity and let
  `Unitful` print the unit:
  `label = " (ϕi=$(ϕi |> f1))"` → `" (ϕi=35.5°)"` when the quantity is stored in `°`
  (angles follow their own rules below). Never `string(ustrip(...))` and never re-attach
  units by hand (`* u"m"`, `* 1°`). Note `round(q; digits=n)` on a `Quantity` is **not** a
  substitute: it errors, or (for dimensionless units like `°`) rounds the SI-base value
  and drops the unit (`round(35.5°; digits=1) == 0.6`).
- **Angles** stored as `Unitful` angles (`θR = 29°`, `δ = 30°`). **DO NOT** output angle results as radians.
- **Julia trig functions are unit-aware — DO NOT convert angles to rad manually.**
  `sin`, `cos`, `tan`, `sind`, `cosd`, `tand` etc. accept `Unitful` angle Quantities and
  return the correct value whether the input is `°` or `rad` (`sin(30°) = 0.5`). Never
  write `sin(ustrip(u"rad", x))` / `_to_rad(x)`-style conversions — keep the Quantity.
  CAUTION with **inverse** trig: `asin`, `acos`, `atan` return a **bare rad Float64 with
  no units attached**, and `asind`/`acosd`/`atand` return bare degrees (also no units).
  Before mixing an inverse-trig result back into angle arithmetic, re-attach units
  (`uconvert(°, asin(x))`), because a bare Float64 added to a `°` Quantity is interpreted
  as **rad** and silently corrupts the result.
- Vectors that carry `Unitful` for Plots must be **typed** (e.g. `typeof(1.0m)[]`, `typeof(1.0kPa)[]`) to avoid `Vector{Any}` `DimensionError` in `Plots.jl` `UnitfulExt`.

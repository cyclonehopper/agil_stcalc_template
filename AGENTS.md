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
  skipped); when the file is absent, use the terminal command above.

## 📏 Units and Quantities (Unitful)
- **Keep units attached — do not strip them just because it is convenient.** Every physical quantity must stay a `Unitful` quantity (e.g. `12.5u"kN"`, `3.2u"m"`) from input through to printed output. Never store a bare number that silently loses its dimension. (The custom units `ksi`, `kipf`, … are registered by `MyUnits`, and the `u"..."` macro comes from `Unitful` — both loaded in the `template.qmd` preamble.)
- Assign into typed fields with the unit included (`σ = 250u"MPa"`), and give documented unit annotations/defaults rather than raw `Float64` values.
- **Do not strip units for plotting.** `Plots.jl` consumes `Unitful` data directly: when the vectors you hand it are declared up front with units (`x = [1.0, 2.0, 3.0]u"m"`, `M = [12.5, 18.0]kNm`), the plot works and the axes are labelled with the units. Keep the data unitful through the plot call. (Plots strips units internally for the axis labels and converts compatible units onto one axis; series whose dimensions differ cannot share an axis.)
- For a non-SI axis scale, stay unitful: set the axis unit on the **first** series (`plot(x, M; yunit = kNm)` — MyUnits' `kNm` labels the axis `kN⋅m`, whereas a loose product `u"kN*m"` prints as `m kN`) or convert the data elementwise — `uconvert` is scalar-only, so broadcast `uconvert.(u"kN*m", M)`. Never `ustrip` just to change the displayed scale.
- Strip units only where it is genuinely unavoidable:
  1. an API that requires a dimensionless `Float64` (recipe below), or
  2. the quantity is raised to a power that is not an exact short rational — an **irrational** exponent (`q^π`, `q^sqrt(2)`) or a Float64 approximation (`q^0.3`; `q^(1/3)` is `6004799503160661/2^54`, while `q^(1//3)` is exact and clean). Unitful folds the exponent into a monstrous rational (`m^5404319552844595/18014398509481984`) that can no longer be simplified or converted; compute the power on the dimensionless value instead: `ustrip(upreferred(q))^p`.
- **When a `Float64` is expected from an expression carrying quantities, normalise to SI base units, drop the unit, then convert the value type:**
  ```julia
  # illustrative: M and Z are quantity-valued inputs
  f = Float64(ustrip(upreferred(M / Z)))   # upreferred → SI base units; ustrip → drop unit; Float64 → Float64
  ```
  `ustrip(upreferred(x))` on its own is **not** always a `Float64`: integer-valued quantities yield `Int64` or `Rational{Int64}` (`250u"MPa"` → `250000000`, `1u"cm"` → `1//100`), which either `MethodError` at a `::Float64` boundary or silently overflow in later arithmetic.
  Do **not** call `ustrip(x)` directly on a quantity that is not already in SI base units — `ustrip(1u"cm")` yields `1`, not `0.01`, corrupting the result by an invisible unit factor. `Float64(x)` is not a substitute either: it only changes the backing value type and returns a `Quantity` with the *same* units (`Float64(1u"cm") == 1.0u"cm"`), so it never produces a bare number.
- When feeding a value back to a quantity-typed API, re-attach an explicit unit (`value * u"m"`, `value * u"Pa"`) rather than relying on implicit assumptions.
- **Formatting quantities in labels/text: don't decompose them.** Interpolate the rounded quantity and let `Unitful` print the unit, e.g. `M = 42.1534kNm` (MyUnits' `kNm`, printed as `kN⋅m`) → `"M* = $(M |> f2)"` → `"M* = 42.15 kN⋅m"`. Use `f0`–`f3`/`fround` from `MyUnits`; never `string(ustrip(...)) * " kN⋅m"`, and never re-attach units by hand (`* u"m"`, `* 1°`) just for display. `uconvert` to the display unit first when the stored unit may differ (a loose product `u"kN*m"` prints as `m kN`, not `kN⋅m`). `round(q; digits=n)` on a `Quantity` is **not** a substitute — it errors, or (for dimensionless units like `°`) rounds the SI-base value and drops the unit.

## 🎨 Typesetting Rules (Typst)
- When writing raw Typst blocks, use: ` ```{=typst} ... ``` `
- Remember that Typst uses `#` for functions (e.g., `#rect()`) which differs from Quarto's Markdown headers.
- If using a custom Typst template, reference it in the YAML header under `format: typst: template: my-template.typ`.
- For displaying Julia variables, use `{julia} ... ` (with curly braces)  for inline.

## 🚫 Critical Constraints
- **JULIA-ONLY CODE CHUNKS:** All code chunks are Julia only, nothing else. Do not use any other language in executable code chunks.
- **NO LATEX:** Do not use LaTeX commands; use native Typst syntax or Quarto cross-references (`@fig-label`).
- **Syntax Boundaries:** Never place Julia code inside a ````{=typst}` block. Julia must stay in ````{julia}` blocks.

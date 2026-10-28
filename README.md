# Agil_stcalc_template Format

A Quarto/Typst calculation-sheet format for Agilitus structural calculations.

## Installing

Replace `<github-organization>` with the repository that hosts this template:

```bash
quarto use template <github-organization>/agil_stcalc_template
```

This will install the format extension and create an example qmd file
that you can use as a starting place for your document.

## Using

Set the format in the document YAML and fill in the project metadata (the
project, client and latest-revision values drive the page header):

```yaml
format:
  agil_stcalc_template-typst: default
company: Agilitus
client: Glencore
proj_no: 26016
proj_title: Glencore Port C2A Conveyor Relocation Engineering
calc_no: 26016-ST-CAL-0002
calc_title: C2A Permanent Installation Structural Design
proj_phase: Detailed Design
logo_company: "images/logo-agilitus-black.png"
# logo_client: "images/<your-client-logo>.png"   # optional client logo
revisions:
- rev_no: A
  rev_date: today
  rev_desc: IFIR
  rev_prep: Josua A
  rev_check: F. Hakim
  rev_app:
```

### Page header styles

Two header layouts are available and are selected with the `calc_header`
option:

| `calc_header` | Header                                                                  |
| ------------- | ----------------------------------------------------------------------- |
| `default`     | Agilitus calculation pad: PROJECT / PROJECT NO. / CLIENT / PREPARED / CHECKED / DATE / SHEET NO. grid with the company logo on the right. |
| `perth`       | Perth office header from `xlsx/agil_perth_calc_header.xlsx`: a "Calculation Sheet" title bar (company logo left, client logo right) over Project Title, Project No., Client, Calculation No., Calculation Title, Revision, Prepared, Checked and Date. |

`default` applies when the option is omitted, so existing documents are
unaffected. To use the Perth header, add the option to the document YAML —
it may be placed either next to the other project metadata or inside the
format block:

```yaml
format:
  agil_stcalc_template-typst: default
calc_header: perth
```

```yaml
format:
  agil_stcalc_template-typst:
    calc_header: perth
```

Both spellings `calc_header` and `calc-header` are accepted, capitalisation is
ignored, and any unrecognised value falls back to `default`.

Notes:

* Both styles read the same metadata, so switching the option only changes the
  layout — no other YAML edits are required.
* Perth style shows the **latest** revision's `rev_no`, `rev_prep`,
  `rev_check` and `rev_date`, and shows `calc_title` as the Calculation Title.
  Fields wrap at spaces and hyphens; two lines per field fit (the header grows
  upwards and still clears a printer margin). Three lines, or a single long
  unbroken token such as a very long calculation number, will compress the
  header or run past the table edge — keep `proj_title` and `calc_no` short
  and hyphenated.
* Perth style has no SHEET NO. field (the xlsx has none), so page 1 carries no
  page number; the footer numbers pages from page 2 (e.g. `2 of 5`).
* Logos: `logo_company` and `logo_client` are placed at the left and right of
  the title bar; if either is unset that side is simply left blank (nothing is
  substituted, so a document never shows another client's logo). Logos are
  addressed relative to the document, so bare paths work for documents in the
  project root, e.g.

  ```yaml
  logo_company: "images/logo-agilitus-black.png"
  logo_client: "images/logo-pls.png"
  ```

  `images/logo-pls.png` is the PLS artwork taken from the Perth xlsx; replace
  it with the client's logo for other jobs. A document in a subdirectory
  should keep its artwork beside the document.
* The document-control table and disclaimer at the foot of the first page are
  identical for both styles.

## Aligning trailing comments

`_align_comments.jl` aligns the trailing `#` comments of contiguous runs of
code lines, so calculation sheets read as a clean column of notes. JuliaFormatter
has no option for this (`align_assignment` only moves `=`, `align_pair_arrow`
only `=>`), so this small script fills the gap **without reformatting anything
else**.

In `.qmd` files only fenced `` ```{julia} `` blocks are touched — prose,
headings (which start with `#`) and Typst blocks are never rewritten. `#`
inside strings, char literals, backtick commands, `"""…"""` and `#= … =#`
comments is ignored, and `A' # transpose` still aligns.

From the terminal:

```bash
julia _align_comments.jl FILE              # preview: aligned text on stdout
julia _align_comments.jl --write FILE...   # rewrite files in place
julia _align_comments.jl --gap 3 FILE      # min spaces before `#` (default 2)
```

From VS Code, with the file open (save first — the task reads from disk):

| Task                       | Effect                                                    |
| -------------------------- | --------------------------------------------------------- |
| `Align comments (preview)` | prints the aligned file to the terminal, writes nothing    |
| `Align comments (write)`   | aligns the current file in place                           |

Run them with `Terminal ▸ Run Task…` (`Ctrl+Shift+P` → `Tasks: Run Task`).
The tasks live in `.vscode/tasks.json`, which is versioned in this template
repository. Note that `quarto use template` does **not** copy dotfiles, so a
brand-new project needs that file copied in (the `quarto-init` skill does this
automatically); otherwise just run the script from the terminal as shown above.

### Binding a key (e.g. `Ctrl+Alt+A`)

VS Code and VSCodium have **no workspace-level keybindings** — shortcuts live in
your user `keybindings.json` on the machine running the window (with Remote‑SSH
that is your laptop, not the remote host). Add one entry, once:

```json
[
  {
    "key": "ctrl+alt+a",
    "command": "workbench.action.tasks.runTask",
    "args": "Align comments (write)",
    "when": "editorTextFocus && !editorReadonly"
  }
]
```

`keybindings.json` locations (open it with `Ctrl+Shift+P` → *Preferences: Open
Keyboard Shortcuts (JSON)*, which is the reliable way):

| Platform | Path |
| -------- | ---- |
| Windows  | `%APPDATA%\<Code\|VSCodium>\User\keybindings.json` |
| macOS    | `~/Library/Application Support/<Code\|VSCodium>/User/keybindings.json` |
| Linux    | `~/.config/<Code\|VSCodium>/User/keybindings.json` |

Notes:

* Save the file first — the task reads from disk, so unsaved edits are not aligned.
* `args` must match the task label exactly (`Align comments (write)`), otherwise
  the shortcut opens the task picker instead of running it.
* Because it targets the task *label*, the same shortcut works in every project
  that ships `.vscode/tasks.json`; in a window where the task does not exist you
  get the task picker.
* Do not confuse this with the **Better Align** extension (`chouzz.vscode-better-align`).
  Its shortcut is `Alt+A`, it is a *client-side* extension unless installed on the
  Remote‑SSH host, and it reformats more than comments (it also moves `=`, `:` and
  `=>`). This template deliberately does not use it.


// This is an example typst template (based on the default template that ships
// with Quarto). It defines a typst function named 'article' which provides
// various customization options. This function is called from the
// 'typst-show.typ' file (which maps Pandoc metadata function arguments)
//
// If you are creating or packaging a custom typst template you will likely
// want to replace this file and 'typst-show.typ' entirely. You can find
// documentation on creating typst templates and some examples here:
//   - https://typst.app/docs/tutorial/making-a-template/
//   - https://github.com/typst/templates

// copied from Skane88, thanks Seane

#let logo(logo_path: none, width: auto, height: auto) = {
  if logo_path != none {
    // Typst paths never contain backslashes on this platform, but Pandoc
    // escapes `_` and `.` when a YAML value is interpolated into a Typst
    // string (e.g. `\_extensions/...`), so drop any backslashes.
    let path = if type(logo_path) == str { logo_path.replace("\\", "") } else { logo_path }
    image(path, width: width, height: height)
  } else {
    []
  }
}

#let resolve_date(d) = {
  if d == [today] {
    datetime.today().display("[day]/[month]/[year repr:last_two]")
  } else {
    d
  }
}

// Revision rows for the document control table, oldest at the top and the
// latest revision at the bottom. The latest row is taller so a signature can
// be applied below the name; older revisions are collapsed to half height.
#let doc_control_rows(data, border: 0.5pt + black, row_height: 12mm, vpad: 6pt) = {
  let out = ()
  if data != none and data.len() > 0 {
    let n = data.len()
    for (i, rev) in data.enumerate() {
      let h = if i == n - 1 { row_height } else { row_height / 2 }
      out.push(table.hline(stroke: border))
      out.push(block(height: calc.max(h - vpad, 0pt))[#rev.rev_no])
      out.push(rev.rev_desc)
      out.push(resolve_date(rev.rev_date))
      out.push(rev.rev_prep)
      out.push(rev.rev_check)
      out.push(rev.rev_app)
    }
  }
  out
}

#let disclaimer(company: "COMPANY", client: "CLIENT", proj_title: "SOME PROJECT") = {
  text(
    [This calculation was prepared by ]
      + company
      + [ pursuant to the Engineering Services Contract between ]
      + company
      + [ and ]
      + client
      + [ in connection with the services for ]
      + proj_title
      + [.],
  )
}

// ---------------------------------------------------------------------------
// Page headers
// ---------------------------------------------------------------------------
// The header style is selected in the document metadata with `calc_header`:
//   calc_header: default  -> Agilitus 7-column calculation pad (historical)
//   calc_header: perth    -> Perth office "Calculation Sheet" header, as
//                            reproduced from xlsx/agil_perth_calc_header.xlsx
// Both styles are built from the same document metadata (project, client,
// calculation numbers and the latest revision), so only the layout differs.

// Default header: 7-column grid with project / prepared / checked / date
// blocks and the company logo on the right-hand side.
#let default_header(
  proj_title: none,
  proj_no: none,
  client: none,
  rev_prep: none,
  rev_check: none,
  rev_date: none,
  logo_company: none,
) = {
  set text(font: "Arial", size: 8.5pt, hyphenate: false)
  set par(justify: false)
  set table(stroke: (paint: black, thickness: 0.6pt))
  let outer = (paint: black, thickness: 1.3pt)
  table(
    // Matches the Agilitus calculation pad (xlsx): 36-unit grid
    // 5 | 9 | 4 | 3 | 4 | 4 | 7
    columns: (5fr, 9fr, 4fr, 3fr, 4fr, 4fr, 7fr),
    rows: (9mm, 9mm, 9mm),
    fill: none,
    inset: 3pt,
    align: left + horizon,
    table.hline(stroke: outer),
    [PROJECT], table.cell(colspan: 3)[#proj_title], [SHEET NO.], [#context counter(page).display("1/1", both: true)],
    table.cell(rowspan: 3, align: center + horizon, inset: 2pt)[
      #logo(logo_path: logo_company, height: 25mm)
    ],
    [PROJECT NO.], [#proj_no], [PREPARED], [#rev_prep], [DATE], [#rev_date],
    [CLIENT], [#client], [CHECKED], [#rev_check], [DATE], [],
    table.hline(stroke: outer),
    table.vline(x: 0, stroke: outer),
    table.vline(x: 7, stroke: outer),
  )
}

// Perth header: a "Calculation Sheet" title bar (company logo left, client
// logo right) over four rows of label/value pairs. The xlsx uses 12 equal
// columns merged as 2|6|2|2 for the upper rows and 2|2|2|2|2|2 for the
// prepared/checked/date row.
//
// `bar_title` is the caption in the title bar ("Calculation Sheet"); the
// calculation title itself arrives as `calc_title`.
#let perth_header(
  proj_title: none,
  proj_no: none,
  client: none,
  calc_no: none,
  calc_title: none,
  rev_no: none,
  rev_date: none,
  rev_prep: none,
  rev_check: none,
  logo_company: none,
  logo_client: none,
  bar_title: "Calculation Sheet",
) = {
  set text(font: "Arial", size: 8pt, hyphenate: false)
  set par(justify: false)
  set table(stroke: 0.5pt + black)
  let lab = text.with(weight: "bold")
  table(
    columns: (1fr,) * 12,
    // Rows grow when a title or number wraps (up to two lines per row before
    // the header runs out of margin).
    rows: (12mm, auto, auto, auto, auto),
    fill: none,
    inset: (x: 3pt, y: 3.5pt),
    align: left + horizon,
    table.cell(colspan: 12, inset: (x: 5pt, y: 3pt))[
      #grid(
        columns: (1fr, auto, 1fr),
        align: (left + horizon, center + horizon, right + horizon),
        logo(logo_path: logo_company, height: 9mm),
        text(size: 15pt, weight: "bold")[#bar_title],
        logo(logo_path: logo_client, height: 7mm),
      )
    ],
    table.cell(colspan: 2)[#lab[Project Title]], table.cell(colspan: 6)[#proj_title],
    table.cell(colspan: 2)[#lab[Project No.]], table.cell(colspan: 2)[#proj_no],
    table.cell(colspan: 2)[#lab[Client]], table.cell(colspan: 6)[#client],
    table.cell(colspan: 2)[#lab[Calculation No.]], table.cell(colspan: 2)[#calc_no],
    table.cell(colspan: 2)[#lab[Calculation Title]], table.cell(colspan: 6)[#calc_title],
    table.cell(colspan: 2)[#lab[Revision]], table.cell(colspan: 2)[#rev_no],
    table.cell(colspan: 2)[#lab[Prepared]], table.cell(colspan: 2)[#rev_prep],
    table.cell(colspan: 2)[#lab[Checked]], table.cell(colspan: 2)[#rev_check],
    table.cell(colspan: 2)[#lab[Date]], table.cell(colspan: 2)[#rev_date],
  )
}

#let article(
  title: none,
  authors: none,
  company: none,
  proj_no: none,
  calc_no: none,
  proj_title: none,
  client: none,
  proj_phase: none,
  logo_company: none,
  logo_client: none,
  rev_data: none,
  calc_header: "default",
  cols: 1,
  margin: (inside: 1.5cm, outside: 1.5cm, top: 5cm, bottom: 2.5cm),
  paper: "a4",
  lang: "en",
  region: "AU",
  mathfont: none,
  codefont: none,
  font: "Lato",
  fontsize: 11pt,
  sectionnumbering: "1.1", 
  fig-align: center,
  toc: false,
  toc_title: none,
  toc_depth: 2,
  toc_indent: 1.5em,
  doc,
) = {
  set text(lang: lang, region: region, font: font, size: fontsize)
  show heading: set text(
    font: font,
    fill: rgb("#002D72"),
    size: 1.0em,
    weight: "semibold",
  )

  if rev_data == none {
    let rev_data = (
      rev_no: none,
      rev_date: none,
      rev_desc: none,
      rev_prep: none,
      rev_check: none,
      rev_app: none,
    )
  }

  // Latest revision values used in the header.
  let last_rev = if rev_data != none and rev_data.len() > 0 { rev_data.last() } else { none }
  let rev_prep = if last_rev != none { last_rev.rev_prep } else { none }
  let rev_check = if last_rev != none { last_rev.rev_check } else { none }
  let rev_no = if last_rev != none { last_rev.rev_no } else { none }
  let rev_date = if last_rev != none { resolve_date(last_rev.rev_date) } else { none }

  // Header style: "default" (Agilitus pad) or "perth" (Perth office sheet).
  // Accept surrounding whitespace and any capitalisation; fall back to
  // "default" for unexpected values.
  let header_style = if type(calc_header) == str { lower(calc_header.trim()) } else { "default" }
  // The perth header is bottom-anchored above the text area, so the top margin
  // is also its growth limit: 12mm title bar + four two-line rows + ascent,
  // with ~5mm to spare so the top rule still clears a printer's margin.
  let top_margin = if header_style == "perth" { 5.4cm } else { 4.8cm }

  set page(
    paper: paper,
    margin: (inside: 1.5cm, outside: 1.5cm, top: top_margin, bottom: 2.5cm),
    numbering: "1/1",
    footer: context [
      #if counter(page).get().first() != 1 {
        [
          #box(width: 100%, stroke: (top: 1pt), outset: (top: 6pt))
          #set align(right)
          #set text(size: 0.9em)
          #counter(page).display("1 of 1", both: true)
        ]
      }
    ],
    footer-descent: 30%,
    header: if header_style == "perth" {
      perth_header(
        proj_title: proj_title,
        proj_no: proj_no,
        client: client,
        calc_no: calc_no,
        // `title` is populated from the document's `calc_title` by
        // typst-show.typ.
        calc_title: title,
        rev_no: rev_no,
        rev_date: rev_date,
        rev_prep: rev_prep,
        rev_check: rev_check,
        logo_company: logo_company,
        logo_client: logo_client,
      )
    } else {
      default_header(
        proj_title: proj_title,
        proj_no: proj_no,
        client: client,
        rev_prep: rev_prep,
        rev_check: rev_check,
        rev_date: rev_date,
        logo_company: logo_company,
      )
    },
    header-ascent: 9.5pt,
  )

  set par(justify: true)
  set heading(numbering: sectionnumbering)
  show heading: set block(below: 1em, above: 2em)

  // Configure figure numbering to be section-based (e.g., Figure 2.1)
  set figure(numbering: n => {
    let h1 = counter(heading).get().at(0, default: 0)
    if h1 > 0 {
      numbering("1.1", h1, n)
    } else {
      numbering("1", n)
    }
  })

   // Set the font size for figure captions
  show figure.caption: set text(size: 0.85em, weight: "semibold")



  // Reset figure counters at each level 1 heading
  // IMPORTANT: Quarto uses string-based kinds ("quarto-float-fig", "quarto-float-tbl"),
  // not the built-in `image` and `table` types. The quarto_super function reads
  // counter(figure.where(kind: kind)).get().first() + 1 to compute n-super,
  // so we must reset the correct counter to keep section-based numbering working.
  show heading.where(level: 1): it => {
    counter(figure.where(kind: "quarto-float-fig")).update(0)
    counter(figure.where(kind: "quarto-float-tbl")).update(0)
    it
  }


  place(
    bottom,
    float: true,
    [
      #set text(size: 8pt)
      #set par(justify: false)
      #let border = 0.5pt + black
      #table(
        // Matches the report's Document Control table: unshaded, outer border
        // and horizontal separators only, text top-aligned.
        columns: (1fr, 2.55fr, 1.52fr, 1.64fr, 1.64fr, 1.8fr),
        stroke: none,
        inset: (x: 5pt, y: 3pt),
        align: left + top,
        table.hline(stroke: border),
        table.cell(colspan: 6)[#text(weight: "bold")[Document Control]],
        table.hline(stroke: border),
        [Revision], [Issue Reason], [Date], [Prepared], [Reviewed], [Approved],
        ..doc_control_rows(rev_data, border: border),
        table.hline(stroke: border),
        table.vline(x: 0, stroke: border),
        table.vline(x: 6, stroke: border),
      )
      #disclaimer(company: company, client: client, proj_title: proj_title)
    ],
  )

  if toc {
    let title = if toc_title == none {
      auto
    } else {
      toc_title
    }
    block(above: 0em, below: 2em)[
      #outline(
        title: toc_title,
        depth: toc_depth,
        indent: toc_indent,
      );
    ]
  }

  if cols == 1 {
    doc
  } else {
    columns(cols, doc)
  }
}

#let like_header(it) = {
  v(0.5em)
  box(width: 100%, stroke: (bottom: 1pt), outset: (bottom: -2pt))[
    #set text(weight: "semibold", size: 1.3em)
    #v(0.1em)
    #smallcaps(it)
    #v(0.6em)
  ]
}


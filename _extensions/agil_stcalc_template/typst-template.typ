
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
    image(logo_path, width: width, height: height)
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

// Revision rows for the document control table (latest on top). The current
// (latest) revision gets a taller row so a signature can be applied below the
// name; older revisions are collapsed to half height.
#let doc_control_rows(data, border: 0.5pt + black, row_height: 12mm, vpad: 6pt) = {
  let out = ()
  if data != none and data.len() > 0 {
    let d = data.rev()
    for (i, rev) in d.enumerate() {
      let h = if i == 0 { row_height } else { row_height / 2 }
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

  set page(
    paper: paper,
    margin: (inside: 1.5cm, outside: 1.5cm, top: 4.8cm, bottom: 2.5cm),
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
    header: [
      #set text(font: "Arial", size: 8.5pt, hyphenate: false)
      #set par(justify: false)
      #set table(stroke: (paint: black, thickness: 0.6pt))
      #let outer = (paint: black, thickness: 1.3pt)
      #table(
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
    ],
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



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

#let logo(logo_path: none) = {
  if logo_path != none { [#image(logo_path)] } else { [] }
}

#let rev_table(max_items: 3, data) = {
  // Build a revision table for the footer.
  // If no. revisions > max_items only max_items-1 will be shown

  data = data.rev()
  // rev_data comes in last to first, but rev table in footer is
  // latest on top.

  if data.len() > max_items {
    data = data.slice(0, max_items)
  }

  for rev in data {
    (
      rev.rev_no,
      rev.rev_date,
      rev.rev_desc,
      rev.rev_prep,
      rev.rev_check,
      rev.rev_app,
    )
  }
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
  margin: (inside: 1.5cm, outside: 1.5cm, top: 5cm, bottom: 2cm),
  paper: "a4",
  lang: "en",
  region: "AU",
  font: "Lato",
  fontsize: 11pt,
  sectionnumbering: "1.1",
  toc: false,
  toc_title: none,
  toc_depth: 2,
  toc_indent: 1.5em,
  doc,
) = {
  set text(lang: lang, region: region, font: font, size: fontsize)
  show heading: set text(
    font: "Bitter",
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

  set page(
    paper: paper,
    margin: margin,
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
      #set text(size: 0.9em)
      #table(
        columns: (1.5fr, 3.5fr, 1.3fr, 1.6fr),
        rows: (1.5cm, 0.5cm, 0.5cm, 0.5cm),
        fill: none,
        table.cell(
          align: center,
          inset: 2pt,
          stroke: (right: (thickness: 0pt)),
        )[#logo(logo_path: logo_company)],
        table.cell(
          colspan: 2,
          align: center + horizon,
        )[#text(size: 2.0em, fill: black)[*CALCULATION SHEET*]],
        table.cell(
          align: center,
          inset: 2pt,
          stroke: (left: (thickness: 0pt)),
        )[#logo(logo_path: logo_client)],
        [*Project Title*], [#proj_title], [*Project No.*], table.cell(align: right)[#proj_no],
        [*Client*], [#client], [*Calculation No.*], table.cell(align: right)[#calc_no],
        [*Calculation Title*], [#title], [*Revision*], table.cell(align: right)[#rev_data.last().rev_no],
        [*Project Phase*], [#proj_phase], [*Date*], table.cell(align: right)[#rev_data.last().rev_date],
      )
    ],
    header-ascent: 10%,
  )

  set par(justify: true)
  set heading(numbering: sectionnumbering)
  show heading: set block(below: 1em, above: 2em)

  place(
    bottom,
    float: true,
    [
      #set text(size: 0.8em, weight: "semibold")
      #table(
        columns: (1fr, 2fr, 6fr, 3fr, 3fr, 3fr),
        table.header([Rev.], [Date], [Description], [Prepared], [Checked], [Approved]),
        [#hide[Ag]], [#hide[Ag]], [#hide[Ag]], [#hide[Ag]], [#hide[Ag]], [#hide[Ag]],
        ..rev_table(rev_data),
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


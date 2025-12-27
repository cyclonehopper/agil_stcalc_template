
// Typst custom formats typically consist of a 'typst-template.typ' (which is
// the source code for a typst template) and a 'typst-show.typ' which calls the
// template's function (forwarding Pandoc metadata values as required)
//
// This is an example 'typst-show.typ' file (based on the default template  
// that ships with Quarto). It calls the typst function named 'article' which 
// is defined in the 'typst-template.typ' file. 
//
// If you are creating or packaging a custom typst template you will likely
// want to replace this file and 'typst-template.typ' entirely. You can find
// documentation on creating typst templates here and some examples here:
//   - https://typst.app/docs/tutorial/making-a-template/
//   - https://github.com/typst/templates
#show: doc => article(
$if(title)$
  title: [$title$],
$endif$
$if(by-author)$
  authors: (
$for(by-author)$
$if(it.name.literal)$
    ( name: [$it.name.literal$],
      affiliation: [$for(it.affiliations)$$it.name$$sep$, $endfor$],
      email: [$it.email$] ),
$endif$
$endfor$
    ),
$endif$

$if(company)$
  company: [$company$],
$endif$

$if(proj_no)$
  proj_no: [$proj_no$],
$endif$

$if(calc_no)$
  calc_no: [$calc_no$],
$endif$

$if(proj_title)$
  proj_title: [$proj_title$],
$endif$

$if(client)$
  client: [$client$],
$endif$

$if(proj_phase)$
  proj_phase: [$proj_phase$],
$endif$

$if(logo_company)$
  logo_company: "$logo_company$",
  $endif$
$if(logo_client)$
  logo_client: "$logo_client$",
  $endif$

$if(revisions)$
  rev_data: (
  $for(revisions)$
  (
      rev_no: [$revisions.rev_no$],
      rev_date: [$revisions.rev_date$],
      rev_desc: [$revisions.rev_desc$],
      rev_prep: [$revisions.rev_prep$],
      rev_check: [$revisions.rev_check$],
      rev_app: [$revisions.rev_app$],
  ),
  $endfor$
  ),
$endif$

$if(lang)$
  lang: "$lang$",
$endif$
$if(region)$
  region: "$region$",
$endif$
$if(abstract)$
  abstract: [$abstract$],
$endif$
$if(margin)$
  margin: ($for(margin/pairs)$$margin.key$: $margin.value$,$endfor$),
$endif$
$if(papersize)$
  paper: "$papersize$",
$endif$
$if(mainfont)$
  font: ("$mainfont$",),
$endif$
$if(fontsize)$
  fontsize: $fontsize$,
$endif$
$if(section-numbering)$
  sectionnumbering: "$section-numbering$",
$endif$
$if(toc)$
  toc: $toc$,
$endif$
  cols: $if(columns)$$columns$$else$1$endif$,
  doc,
)

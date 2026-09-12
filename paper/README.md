# Manuscript source

Self-contained LaTeX project. No image files are needed: every figure is drawn with
pgfplots from the data in `figures/data/`.

## Build

```
pdflatex main && bibtex main && pdflatex main && pdflatex main
```

`latexmk -pdf main` also works where available. The compiled `main.pdf` is committed.

## Layout

- `main.tex` — preamble, macros, abstract, includes
- `sections/01..08-*.tex` — the eight body sections
- `appendices/A..C-*.tex` — family proofs, AGD-SDAJ verification record, artifact manifest
- `figures/fig*.tex` and `figures/data/*.dat` — pgfplots figures and their data
- `refs.bib` — 26 references, each checked against its Crossref record or eprint page

## Uploading to Overleaf

New Project, then Upload Project, selecting a zip of this directory. Set the compiler to
pdfLaTeX and the main document to `main.tex`.

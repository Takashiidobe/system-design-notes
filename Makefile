.PHONY: phony

BOOK_NAME="System Design Notes"
GRAPHVIZ_FILES = $(shell find ./graphviz -name '*.dot')
FIGURES = $(shell find ./figures -name '*.svg')
CHAPTERS = $(shell find ./chapters -name '*.md')

PANDOCFLAGS =                        \
  --table-of-contents                \
  --from=markdown                    \
  --number-sections                  \
	--top-level-division=chapter       \
	--filter=pandoc-include            \
  --indented-code-classes=rust

HTML_FLAGS =                         \
	--metadata title=$(BOOK_NAME)      \
	--template=./templates/book.html   \
	--embed-resources                  \
	--standalone

MD_FLAGS =                           \
	--metadata title=$(BOOK_NAME)      \
	--to=gfm                           \
	--embed-resources                  \
	--standalone

PDF_FLAGS =                          \
  --pdf-engine=xelatex               \
	--template=eisvogel                \
	-V toc-own-page=false              \
  -V mainfont="TeX Gyre Pagella"     \
  -V documentclass=krantz            \
  -V papersize=A4                    \
	-V book=true                       \
	-V titlepage=true                  \
	-V classoption=oneside             \

html: phony output/index.html output/book.html

md: phony output/book.md | output copy_readme

epub: phony output/book.epub

pdf: phony output/book.pdf

docx: phony output/book.docx

index: phony output/index.html

figures:
	./bin/figures

output/index.html: index.md
	pandoc $< -o $@ $(HTML_FLAGS)

output/%.pdf: %.md $(FIGURES) $(SOURCE_FILES) $(CHAPTERS) Makefile | output figures
	pandoc $< -o $@ $(PDF_FLAGS) $(PANDOCFLAGS)

output/%.epub: %.md $(FIGURES) $(SOURCE_FILES) $(CHAPTERS) Makefile | output figures
	pandoc $< -o $@ $(PANDOCFLAGS)

output/%.html: %.md $(FIGURES) $(SOURCE_FILES) $(CHAPTERS) Makefile templates/book.html | output figures
	pandoc $< -o $@ $(HTML_FLAGS) $(PANDOCFLAGS)

output/%.md: %.md $(FIGURES) $(SOURCE_FILES) $(CHAPTERS) Makefile templates/book.html | output figures
	pandoc $< -o $@ $(MD_FLAGS) $(PANDOCFLAGS)

output/%.docx: %.md $(FIGURES) $(SOURCE_FILES) $(CHAPTERS) Makefile | output figures
	pandoc $< -o $@ $(PANDOCFLAGS)

copy_readme: output/book.md
	cp output/book.md README.md

output:
	mkdir ./output

clean: phony
	rm -rf ./output

open: phony output/book.pdf
	open output/book.pdf

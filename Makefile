.PHONY: phony

BOOK_NAME="Book Template"
GRAPHVIZ_FILES = $(shell find ./graphviz -name '*.dot')
FIGURES = $(shell find ./figures -name '*.svg')
CHAPTERS = $(shell find ./chapters -name '*.md')
SOURCE_FILES = $(shell find ./src -name '*.rs')

PANDOCFLAGS =                        \
	--bibliography references.bib      \
  --table-of-contents                \
  --from=markdown                    \
  --number-sections                  \
	--top-level-division=chapter       \
	--filter=pandoc-include            \
	--filter=pandoc-include-code       \
	--citeproc 												 \
  --indented-code-classes=rust

HTML_FLAGS =                         \
	--metadata title=$(BOOK_NAME)      \
	--template=./templates/book.html   \
	--self-contained

PDF_FLAGS =                          \
  --pdf-engine=xelatex               \
	--template=eisvogel                \
	-V toc-own-page=false              \
  -V mainfont="Palatino"             \
  -V documentclass=krantz            \
  -V papersize=A4                    \
	-V book=true                       \
	-V titlepage=true                  \
	-V classoption=oneside

html: phony output/index.html output/book.html

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

output/%.docx: %.md $(FIGURES) $(SOURCE_FILES) $(CHAPTERS) Makefile | output figures
	pandoc $< -o $@ $(PANDOCFLAGS)

output:
	mkdir ./output

clean: phony
	rm -rf ./output

open: phony output/book.pdf
	open output/book.pdf

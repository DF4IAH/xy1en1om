#
# Copyright (c) 2016 DF4IAH
# All Rights Reserved.
#
# Makefile 2016-08-20 09:15:00Z espero7757@gmx.net $
#

.PHONY : all pdf clean

DOCUMENTSRC  := fpga_xy_addresses
LYX_SRC      := $(DOCUMENTSRC).lyx
LATEX_SRC    := $(DOCUMENTSRC).tex
PDF_FILENAME := RedPitaya_xy1en1om_FPGA-Register-Allocation_Manual.pdf

all: pdf

pdf $(PDF_FILENAME): clean $(LYX_SRC) $(LATEX_SRC)
	# LyX to LaTeX  (TODO)
	pdflatex $(DOCUMENTSRC)
	makeindex $(DOCUMENTSRC).idx
	pdflatex $(DOCUMENTSRC)
	latex_count=8 ; \
	while egrep -s 'Rerun (LaTeX to get cross-references right)' $(DOCUMENTSRC).log && [ $$latex_count -gt 0 ] ;\
	    do \
	      echo "Rerunning latex...." ;\
	      pdflatex $(DOCUMENTSRC) ;\
	      latex_count=`expr $$latex_count - 1` ;\
	    done
	makeindex $(DOCUMENTSRC).idx
	pdflatex $(DOCUMENTSRC)

clean:
	touch X.pdf X.ps X.dvi X.aux X.toc X.idx X.ind X.ilg X.log X.out X.brf X.blg X.bbl
	$(RM) *.pdf *.ps *.dvi *.aux *.toc *.idx *.ind *.ilg *.log *.out *.brf *.blg *.bbl

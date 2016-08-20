#
# Copyright (c) 2013 Instrumentation Technologies
# All Rights Reserved.
#
# $Id: Makefile 1200 2014-02-20 12:52:27Z ales.bardorfer $
#

PLANTUML_JAR ?= ./plantuml.jar
DOXYPDF_FILENAME := RedPitaya_xy1en1om_Development_Manual.pdf
FPGAPDF_FILENAME := RedPitaya_xy1en1om_FPGA-Register-Allocation_Manual.pdf


.PHONY : all doxypdf fpgapdf clean

#all: doxypdf fpgapdf
all: doxypdf


doxypdf $(DOXYPDF_FILENAME):
	java -jar '$(PLANTUML_JAR)' -forcecairo -o img *.dox
	java -jar '$(PLANTUML_JAR)' -forcecairo -o ./img ../src/*.c
	java -jar '$(PLANTUML_JAR)' -forcecairo -o ./img ../src/*.h
	doxygen
	touch latex/X.ps latex/X.dvi latex/X.aux latex/X.toc latex/X.idx latex/X.ind latex/X.ilg latex/X.log latex/X.out latex/X.brf latex/X.blg latex/X.bbl latex/refman.pdf
	-$(MAKE) -C latex pdf
	cp latex/refman.pdf $(DOXYPDF_FILENAME)

fpgapdf $(FPGAPDF_FILENAME):
	-$(MAKE) -C fpga_rb_addresses pdf
	cp fpga_rb_addresses/fpga_rb_addresses.pdf $(FPGAPDF_FILENAME)


clean:
	-$(MAKE) -C fpga_xy_addresses clean
	touch img html latex
	$(RM) -r img html latex
	$(RM) $(DOXYPDF_FILENAME) $(FPGAPDF_FILENAME)

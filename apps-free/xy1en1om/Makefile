#
# $Id: Makefile 2016-08-10 11:24:00Z Ulrich Habel (DF4IAH) $
#
# FPGA environment for testing algorithms.
#

APP=$(notdir $(CURDIR:%/=%))
SHARED_OBJS = 

FPGA=fpga.bit
FPGACFG=fpga.conf
PDF=doc/RedPitaya_xy1en1om_Development_Manual.pdf

# Versioning system
BUILD_NUMBER ?= 0
REVISION ?= devbuild
VER:=$(shell grep version info/info.json | sed -E 's/^[^:]*:[^"]*"([^-]*)-.*/\1/')

INSTALL_DIR ?= ../../build

CONTROLLERHF = controllerhf.so

CFLAGS += -DVERSION=\"$(VER)-$(BUILD_NUMBER)\" -DREVISION=\"$(REVISION)\"
export CFLAGS


all:  lib doc

lib:  $(CONTROLLERHF)

$(CONTROLLERHF):
	$(MAKE) -C src clean
	$(MAKE) -C src all OUT_NAME=$(CONTROLLERHF)

shared_ctrl: $(CONTROLLERHF)
	for obj in $(SHARED_OBJS); do \
		cp $(CONTROLLERHF) ../$$obj; \
	done

doc: $(PDF)

$(PDF):
	$(MAKE) -C doc all

zip: $(CONTROLLERHF)
	mkdir -p target/$(APP)/bin
	cp -r $(CONTROLLERHF) $(FPGA) $(FPGACFG) css fonts img info index.html js target/$(APP)
	sed -i target/$(APP)/info/info.json -e 's/REVISION/$(REVISION)/'
	sed -i target/$(APP)/info/info.json -e 's/BUILD_NUMBER/$(BUILD_NUMBER)/'
	cd target; mkdir -p $(INSTALL_DIR); zip -r $(INSTALL_DIR)/$(APP)-$(VER)-$(BUILD_NUMBER)-$(REVISION).zip *
	$(RM) -r target

clean:
	-$(MAKE) -C src clean
	-$(MAKE) -C doc clean
	-$(RM) -r target
	-$(RM) $(CONTROLLERHF)

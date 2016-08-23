#
# $Id: Makefile 2016-08-20 08:12:00Z Ulrich Habel (DF4IAH) $
#

CROSS_COMPILE ?= arm-linux-gnueabihf-
CC=$(CROSS_COMPILE)gcc

OBJECTS=main.o worker.o cb_http.o cb_ws.o fpga_sys_xadc.o fpga_hk.o fpga_xy.o fpga.o test_sha256_fifo.o test_sha256_dma.o
CFLAGS+= -Wall -Werror -g -fPIC $(INCLUDE)
LDFLAGS= -shared -lpthread

OUT_DIR = ..
OUT_NAME ?= controllerhf.so
CONTROLLER = $(OUT_DIR)/$(OUT_NAME)

all: $(CONTROLLER)

$(CONTROLLER): $(OBJECTS)
	$(CC) -o $(CONTROLLER) $(OBJECTS) $(CFLAGS) $(LDFLAGS)

clean:
	-$(RM) $(OBJECTS)
	-$(RM) -r img

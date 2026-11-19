BUILD_DIR ?= $(realpath $(CURDIR))/build
TOP_MODULE = tb_apb_spi
BENDER_TARGETS = \
	-t rtl \
	-t tb \

RTL_FILES = $(shell bender sources -f > rtl.flist)


.PHONY: all, bender

all: questa
	
questa:
	bender script vsim -t tb -t rtl > compile.do; \
	vsim -do run.do; \
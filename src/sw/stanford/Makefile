# Makefile by Takar, modified by Egor

SRCS=stanford.c
ELFFILE=stanford
CC=microblaze-xilinx-elf-gcc

MAKESIMMEM=../../../tools/make_simmem

#orig XILFLAGS=-mxl-soft-div -msoft-float -mxl-barrel-shift -mno-xl-soft-mul
XILFLAGS=-mxl-soft-div -msoft-float -O2
CXXFLAGS=-g -std=c99 -pedantic -Wall
LNKFLAGS=-Wl,-defsym -Wl,_STACK_SIZE=0x1000 -Wl,-defsym -Wl,_HEAP_SIZE=0x1000
LIBFLAGS=
INCFLAGS=

default: sim

cc:
	$(CC) $(XILFLAGS) $(CXXFLAGS) $(LNKFLAGS) $(LIBFLAGS) $(INCFLAGS) $(CCFLAGS) $(SRCS) -o $(ELFFILE).elf

listing: cc
	microblaze-xilinx-elf-objdump -DSCz $(ELFFILE).elf > $(ELFFILE).dump

bin: cc
	microblaze-xilinx-elf-objcopy -O binary $(ELFFILE).elf $(ELFFILE).bin

mcs: bin
	srec_cat $(ELFFILE).bin -binary -fill 0x00 0x0000 0x8000 $(ELFFILE).bin -binary -offset 0x8000 -o flashprom.mcs -intel
	
sim: bin
	$(MAKESIMMEM) $(ELFFILE).bin ../../../sim/meminit.txt 65536

all: cc listing bin mcs

clean:
	rm -f *~ *.bak $(ELFFILE).elf *.mem $(ELFFILE).dump $(ELFFILE).srec $(ELFFILE).vmem $(ELFFILE).mem $(ELFFILE).vhd $(ELFFILE).bin *.mcs

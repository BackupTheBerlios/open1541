CFLAGS = -Wall -O2 -g
CC = gcc

.PHONY: all
all: lpcflash

OBJS = lpcflash.o settings.o download.o uuencode.o ihex.o serial.o chipinfo.o boot_2xxx.o boot_23xx.o

lpcflash: $(OBJS)
	$(CC) -g -o $@ $(OBJS)

chipinfo.o: boot_2xxx.h boot_23xx.h

cksum_test: cksum_test.c uuencode.o cksum_test.o
	$(CC) $(CFLAGS) -o cksum_test cksum_test.o uuencode.o

boot_2xxx.c boot_2xxx.h: boot_2xxx.armasm mkbootc
	arm-elf-as -o boot_2xxx.armobj boot_2xxx.armasm
	arm-elf-objdump -d boot_2xxx.armobj | ./mkbootc boot_2xxx

boot_23xx.c boot_23xx.h: boot_23xx.armasm mkbootc
	arm-elf-as -o boot_23xx.armobj boot_23xx.armasm
	arm-elf-objdump -d boot_23xx.armobj | ./mkbootc boot_23xx

clean:
	rm -f lpcflash cksum_test *.o core core.* *.armobj

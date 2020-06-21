CC=gcc
ASMBIN=nasm

all : asm cc link
asm :
	$(ASMBIN) -o func.o -f elf -g -l turtle.lst turtle.asm
cc :
	$(CC) -m32 -c -g -O0 -fpack-struct -std=c99 main.c
link :
	$(CC) -m32 -g -fpack-struct -o turtle main.o func.o
gdb :
	gdb turtle

clean :
	rm *.o
	rm *.lst
debug : all gdb
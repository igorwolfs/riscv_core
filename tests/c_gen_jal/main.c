
int sub(int a, int b);

void main(void)
{
	int a = 10;
	int b = 20;
	int c = sub(a, b);
	return;
}

int sub(int a, int b)
{
	return a-b;
}
/***
 * TEST with startup.
 * 
 * 
riscv32-unknown-elf-gcc -march=rv32i -mabi=ilp32 \
    -O0 -nostartfiles -nostdlib \
    -T link.ld \
    main.c startup.S \
    -o main.elf

riscv32-unknown-elf-objcopy main.elf -O binary main.bin
hexdump -v -e '1/4 "%08x\n"' main.bin > my.hex
riscv32-unknown-elf-objdump -d main.elf > main.txt

  */
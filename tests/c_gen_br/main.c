
int main(void)
{
	int a = 0;
	int b = 2;
	int c = a + b;
	if (c > 3)
	{
		a = 1;
	}
	else if (c < 2)
	{
		a = 0;
	}
	else
	{
		a = 2;
	}
	// int *d = (int*)0x000020;
	// (*d) = 4;
	return a;
}

/**
 * COMPILING + LINKING
 * riscv32-unknown-elf-gcc -march=rv32i -mabi=ilp32 -O0 -nostartfiles -nostdlib \
    -T link.ld main.c -o main.elf
 * ELF to raw binary:
 * riscv32-unknown-elf-objcopy main.elf -O binary main.bin
 * Raw binary to one-32bit-word-per-line hex:
 * hexdump -v -e '1/4 "%08x\n"' main.bin > main.hex
 * 
riscv32-unknown-elf-gcc -march=rv32i -mabi=ilp32 -O0 -nostartfiles -nostdlib -T link.ld main.c -o main.elf
riscv32-unknown-elf-objcopy main.elf -O binary main.bin
hexdump -v -e '1/4 "%08x\n"' main.bin > main.hex
 */


/**
 * DISASEMBLING
riscv32-unknown-elf-objdump -d main.elf > main.txt
 */
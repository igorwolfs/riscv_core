void finish_sim(void);

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
	finish_sim();
	return a;
}

void finish_sim(void){
	__asm__ volatile (
        "lui t0, 0xF0000\n\t"  // Load upper immediate: t0 = 0x40000000
        "addi t0, t0, 4\n\t"   // Subtract 1: t0 = 0x3FFFFFFF
        "sw t0, 0(t0)\n\t"        // Set sp = t0
    );
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
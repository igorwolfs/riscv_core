
void main(void);
void finish_sim(void);

__attribute__((naked)) void init_stack(void) {
    __asm__ volatile (
        "lui t0, 0x40000\n\t"  // Load upper immediate: t0 = 0x40000000
        "addi t0, t0, -1\n\t"   // Subtract 1: t0 = 0x3FFFFFFF
        "mv sp, t0\n\t"        // Set sp = t0
    );
	main();
}

void main(void)
{
	// int a = 0;
	// int b = 0;
	// int c = a + b;
	// int *d = (int*)0x000020;
	// (*d) = 4;
	// return 0;

	finish_sim();
}

void finish_sim(void){
	__asm__ volatile (
        "lui t0, 0xF0000\n\t"  // Load upper immediate: t0 = 0x40000000
        "addi t0, t0, 4\n\t"   // Subtract 1: t0 = 0x3FFFFFFF
        "sw t0, 0(t0)\n\t"        // Set sp = t0
    );
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
hexdump -v -e '1/4 "%08x\n"' main.bin > my.hex
 */


/**
 * DISASEMBLING
riscv32-unknown-elf-objdump -d main.elf > main.txt
 */
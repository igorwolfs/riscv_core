#include <stdint.h>

void main(void);
void finish_sim(void);



/**
 * UART REGISTERS
 * h40000000 -> h4000000f
 */

#define UART_BASE   0x40000000

typedef struct uart_regs 
{
    struct {
        uint32_t _res1 : 24;
        uint32_t tx_data : 8;
    };
    struct {
        uint32_t _res2 : 31;
        uint32_t tx_busy : 1;
    };
    struct {
        uint32_t _res3 : 31;
        uint32_t rx_data : 1;
    };
    struct {
        uint32_t _res4 : 31;
        uint32_t rx_drdy : 1;
    };
} __attribute__((packed, aligned(1))) uart_regs_t;

#define UART         ((uart_regs_t*) UART_BASE)



// uint32_t ADDR_TX_DATA = 4'h0;
// uint32_t ADDR_TX_BUSY = 4'h4;
// uint32_t ADDR_RX_DATA = 4'h8;
// uint32_t ADDR_RX_DRDY = 4'hC;

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
    char buff[20] = "Hi, I'm Igor";
    int i=0;
    while (i < strlen(buff))
    {
        if (!UART->tx_busy)
        {
            UART->tx_data = buff[i];
            i++;
        }
    }
	finish_sim();
}

void finish_sim(void){
	__asm__ volatile (
        "lui t1, 0xF0000\n\t"     // Load upper immediate: t1
        "sw t1, 0(t1)\n\t"        // Set sp = t0
        "lui t0, 0xF0000\n\t"     // Load upper immediate: t0
        "addi t0, t0, 4\n\t"      // Subtract 1: t0 = 0x3FFFFFFF
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
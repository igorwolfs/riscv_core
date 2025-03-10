#include <stdint.h>

void main(void);
void finish_sim(void);
int my_strlen(const char *s);



/**
 * UART REGISTERS
 * h40000000 -> h4000000f
 */
#define UART_BASE   0x40000000

typedef struct uart_regs 
{
    struct {
        uint32_t tx_data : 8;
        uint32_t _res1 : 24;
    } __attribute__((packed, aligned(1))) ;
    struct {
        uint32_t tx_busy : 1;
        uint32_t _res2 : 31;
    } __attribute__((packed, aligned(1))) ;
    struct {
        uint32_t rx_data : 8;
        uint32_t _res3 : 24;
    } __attribute__((packed, aligned(1))) ;
    struct {
        uint32_t rx_drdy : 1;
        uint32_t rx_busy : 1;
        uint32_t _res4 : 31;
    } __attribute__((packed, aligned(1))) ;
} __attribute__((packed, aligned(1))) uart_regs_t;

#define UART         ((uart_regs_t*) UART_BASE)

// uint32_t ADDR_TX_DATA = 4'h0;
// uint32_t ADDR_TX_BUSY = 4'h4;
// uint32_t ADDR_RX_DATA = 4'h8;
// uint32_t ADDR_RX_DRDY = 4'hC;

__attribute__((naked)) void init_stack(void) {
    __asm__ volatile (
        "lui t0, 0x40000\n\t"  // Load upper immediate: t0 = 0x40000000
        "addi t0, t0, -16\n\t"   // Subtract 1: t0 = 0x3FFFFFFF -> CHANGED TO -16 instead of -1
        "mv sp, t0\n\t"        // Set sp = t0
    );
	main();
}

void main(void)
{
    char buff[] = "Hi, I'm Igor";
    uint32_t* ptr = (uint32_t*)0xf0000000; // FILE HANDLER POINTER
    int i=0;
    while (i < 12) //my_strlen(buff))
    {
        if (!UART->tx_busy)
        {
            // UART TX completed
            UART->tx_data = buff[i];
            i++;
            // Check UART RX and write word to my.sig
            if (UART->rx_drdy)
            {
                // UART RX completed
                (*ptr) = UART->rx_data;
                //my.sig = UART->rx_data;
            }
        }
    }
    while (UART->rx_busy | UART->tx_busy)
    {
        if (UART->rx_drdy)
            (*ptr) = UART->rx_data;
    }
	finish_sim();
}

void finish_sim(void){
	__asm__ volatile (
        "lui t0, 0xF0000\n\t"     // Load upper immediate: t0
        "addi t0, t0, 4\n\t"      // 0xf0000004 (end sim)
        "sw t0, 0(t0)\n\t"        // Store to t0
    );
}

// int my_strlen(const char *s) {
//     int len = 0;
//     while (1) {
//         if (s[len] == '\0') 
//             break; 
//         len++;
//     }
//     return len;
// }


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

 /**
  * TODO:
  * - Check wheter the UART replaces tx-data while in write.
  * - It does: make sure TX_BUSY prevents it works
  * - Connect TX and RX together in top-module and check if works correctly
  *     - For some reason it ignores the first 3 characters.
  *     - Probably a CPU issue, check whether SP is initialized correctly
  *     - Check where the buffer is stored.
  */


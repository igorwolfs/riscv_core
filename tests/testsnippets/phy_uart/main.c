#include <stdint.h>

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
    };
    struct {
        uint32_t tx_busy : 1;
        uint32_t _res2 : 31;
    };
    struct {
        uint32_t rx_data : 8;
        uint32_t _res3 : 24;
     };
    struct {
        uint32_t rx_drdy : 1;
        uint32_t rx_busy : 1;
        uint32_t _res4 : 31;
    };
} __attribute__((packed, aligned(1))) uart_regs_t;

#define UART         ((uart_regs_t*) UART_BASE)


char get_uart_char(void)
{
    while (UART->rx_drdy == 0)
    {
    }
    return (UART->rx_data - '0');
}

void send_waiting_for_data(void)
{
    char buff[] = "Waiting for data\r\n";
    int i = 0;
    while (i <= 19)
    {
        if (!UART->tx_busy)
        {
            // UART TX completed
            UART->tx_data = buff[i];
            i++;
        }
    }
}

void send_registered_data(char data)
{
    char buff[] = "rcv:[ ][ ] \r\n";
    buff[5] = (data + '0');
    buff[8] = (data);
    int i = 0;
    while (i <= 14)
    {
        if (!UART->tx_busy)
        {
            // UART TX completed
            UART->tx_data = buff[i];
            i++;
        }
    }
}
void send_added_data(char data)
{
    char buff[] = "Sum:[ ][ ] \r\n";
    buff[5] = (data + '0');
    buff[8] = (data);
    int i = 0;
    while (i <= 14)
    {
        if (!UART->tx_busy)
        {
            // UART TX completed
            UART->tx_data = buff[i];
            i++;
        }
    }
}


void main(void)
{
    int i;
    uint8_t c1, c2, c3;

    while (1)
    {
        send_waiting_for_data();
        // Wait for a firt character to be received
        c1 = get_uart_char();
        send_registered_data(c1);
        // Wait for a second character to be received
        c2 = get_uart_char();
        send_registered_data(c2);

        
        // Output the character
        c3 = c1 + c2;
        send_added_data(c3);
    }
}


/**
TODO:
- Define synthesisable fpga-code
    - Write all the FPGA code with generates, so you can eliminate slave muxes if they're not needed
    - Remove file-writes
    - Remove inits
    - Initialize default ram memory
- Write uart read/write code
- Write LED / GPIO peripheral
 */


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
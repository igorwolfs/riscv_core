# TODO
## Instruction adding
### RV32M
- Add RV32M instructions
- Add RV32A instructions


## BOOT-ROM + BOOTLOADER
- Add boot-ROM for initialization
- separate peripheral with instructions and data that keeps the boot-loader
- Entry code starts here, runs this first before running anything else.

# Linux
You CAN in fact run linux on a 32-bit RISC5-cpu, you DO however need an MMU: https://www.reddit.com/r/FPGA/comments/g7ucvd/requirements_for_a_riscv_core_to_be_able_to_run/.

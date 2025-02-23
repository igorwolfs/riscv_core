# Todo
## Step 0
- Put the correct yaml file in order for the simplest architecture.
- Try the yaml-check command:
### Write the Python plugin for initialization and compilation
- Make sure to pick the right toolchain (riscv32-unknown-elf-gcc)
- 

```bash
riscof validateyaml --config=config.ini
```

Error: config: <Section: spike_simple>
So a Section class needs to be added. 
- Something that is somehow done for the other modules but not for this one?
- Where does the "config" come from? Which file is it generated from?
## Step 1: compile a single raw test using the 32-bit riscv compiler and an assembly example


## Step 2: Load the test into memory (instruction memory and data memory)


## Step 3: Compare the output signatures to the reference output signature

It seems like in the neorv32 part of this happens by a macro defined in the model_test.h file:
```C
// this will dump the test results (signature) via the testbench dump module.
#define RVMODEL_HALT                                   \
    signature_dump:                                    \
      la   a0, begin_signature;                        \
      la   a1, end_signature;                          \
      li   a2, 0xF0000004;                             \
    signature_dump_loop:                               \
      bge  a0, a1, signature_dump_end;                 \
      lw   t0, 0(a0);                                  \
      sw   t0, 0(a2);                                  \
      addi a0, a0, 4;                                  \
      j    signature_dump_loop;                        \
    signature_dump_end:                                \
      li   a0, 0xF0000000;                             \
      li   a1, 0xCAFECAFE;                             \
    terminate_simulation:                              \
      sw   a1, 0(a0);                                  \
      j    terminate_simulation
```

It also seems like there's a difference in alignment (2 for the riscv-sail, 4 for the neorv32).

For now let's use the
- Linker script of the neorv32, since there is no mmu, memory is completely contiguous starting at 0x0

!NOTE: this doesn't mean overlap between memory regions, it means sequential placement.
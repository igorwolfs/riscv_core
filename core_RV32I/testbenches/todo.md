# Todo
## Correct yaml file, linker script and header file for assembly generation
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

## Test folder
Run command:

```bash
riscof testlist --config=config.ini --suite=riscv-arch-test/riscv-test-suite/ --env=riscv-arch-test/riscv-test-suite/env
```

Generates a list of folders for tests.

## Test compilation

- Enable command for compiling tests .elfs and dumping them into */test_name/dut/-folder

### Setting up the simulation environment / verilating the model

- The run.sh now sets up the simulation environment
- The elfs and signature file-paths can be passed to it during execution.

### Compiling the test-elfs

- Test-elfs were compiled.

### Loading test-elfs into memory
Now we can load the test-elfs into memory.
I would expect this to be as simple as
- call the binary with
  - path-to-memory
  - path-to-signature

Then the binary should output the signature to the relevant file

### Making the risc5 cpu able to read / write
- Inside the testbench
  - Load the file into memory.
  - It should be kind-of in "RAM", so it can be read from and written to as if it were in RAM.
  - Then there should be a second always-loop which checks for the write address / memory /don't know?
    - Depending on this address it should send something to the signature file.

- Take into account the special registers at addresses like 0xFF000000
- It seems that inside the assembly everything is written by byte.
- In my registers however everythin is a 32-bit word.
  - Address passed with instructions is 32-bit address.
  - It uses byte addressing
  - SO: if the instructions use byte-addressing 
    => We need to skip these first 2 bit-indices.

Seems like I have a prototype which does compile

### Compiling the simulation and running it with the relevant files / signature write-to file.
We need to create a bash-script that can
- Compile the project with verilator to a location (e.g.: sim/)
- Run the binary

Done

### Compiling the tests
- Works, for example: dut/my.elf
- Disasembled

## Signature generation

## Signature comparison with reference

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
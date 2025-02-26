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

### Overview of an example test (myadd-01.S)
- rvtest_entry_point (seems like it prepares the registers for tests)
  - ACTIONS: Loading data from memory, logical right shift with immediate, OR
  - LABELS:
    - rvtest_entry_point: entry label
    - RVMODEL_BOOT (hw init, does nothing now)
- rvtest_code_begin 
  - Program counter setup
  - Global pointer setup (accessing global variables - x3) to (signature_x3_0) 
  - RVTEST_CODE_BEGIN (inits test code label, .text section)
  - RVTEST_CASE
- inst_0 .. inst_587
  - Tests for add instruction
    - Load value
    - Add value
    - Store value
- cleanup_epilogs
  - jumps to 331c
- exit_cleanup
  - load "begin_signature" address into a0
  - load "_end" address into a1
  - Load "0xf0000004" into a2
- signature_dump_loop
  - if true: (a0 > a1): go to signature_dump_end
  - otherwise
    - Load from memory address [a0 (x10)] into [register t0]
    - Store from register t0 into memory address [a2 (x12)]
    - add 4 to register a0 (x10)
- signature_dump_end
  - Load 0xcafecafe into a1
- terminate_simulation
  - store a1 into memory address at a0 (IGNORE)
  - jump to terminate_simulation (infinite loop)
- rvtest_data_begin (data section)
- begin_regstate
- end_regstate
- begin_signature
- signature_x3_0
- signature_x3_0
- signature_x8_0
- signature_x1_0
- signature_x1_1
- sig_end_canary
  - 
- rvtest_sig_end

# ISSUE
- For some reason inside the ADD-file it
  - x10 (a0) keeps incrementing until 0x5a50 instead of 0x5a40
  - x11 (a1) is set at 0x5a50 for some reason, it should have been set to 0x5a40
    - I don't know exactly why this is set to 0x5a50 instead. It is in fact incremented with an immediate for some reason to 5a50.

 ## Signature comparison with reference
 
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

For some reason the RVMODEL_HALT loads some wrong end-signature into a1.

So: why does it take _end instead of _end_signature?
It should take 
- sig_end_canary
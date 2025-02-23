# Debugging basic add-instructions
### PC check
- Check whether reset PC corresponds to expected one.
	- PC resets to zero as expected

### Reducing binary size for testing
- See if you can take a single test, isolate it and use that one to perform a single basic check.

## Check c_gen in the tests-repo
- Created a smaller main.c file for tests
- Compiled and linked it
- Disassebled
- Reduced memory size for vivado to be faster. (MEMSIZE 64 bytes, should take 6 bits of addressing)

### BUG INSTRUCTION 0
0:	ff010113          	addi	sp,sp,-16
Supposed to show up as -16 - 0 but for some reason -16 shows up as 0xff0. It should however show up as 0xFFFFFFF0 (complement).

The code behaves as expected
TODO: Initialize the stack pointer so that its access is limited to the first 64-bytes of memory, and not 0 -> FFFFFF.
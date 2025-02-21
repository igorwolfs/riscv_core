# Checks
### If the top file can't be found
Go to the folder and run the following command:

```bash
verilator --cc top_file.sv --exe sim_main.cpp --top fifo_async_circular_parallel_tb -o sim
```


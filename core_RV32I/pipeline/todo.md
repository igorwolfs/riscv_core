# TODO
- Move the pc-increment to the ifetch stage
- Make sure to have separate stall logic for the IDEX (idex_en), EXMEM (exmem_en), MEMWB (memwb_en) registers
- Make sure you have finegrained control over e.g.:
	- pc_update


## Signal simplification
- Change all the DOLOAD, DOSTORE commands to ISLOAD and ISSTORE that are simply propagated through the pipeline.
- Remove the C_CMEM signal and replace it by IDEX_ISLOAD and IDEX_ISSTORE
	- Check whether strobe is actually used in the load situation
	- Yes it is, so keep the variable the way it is.
	
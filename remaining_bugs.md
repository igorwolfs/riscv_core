# Buggy instructions
## Load bugs
- LB-align
- LBU-align
- lh-align
- lhu-align

## Store bugs
- sb-align
- sh-align

It seems like the store bugs need to 
- Store ONLY in the part of memory indicated
- Leave the rest of the bits ALONE.

SO: we need to I guess 
- read from the write address
- copy those bits as a remainder for the store-instruction

Wow so apparently we write here to non-even multiples of 4 bytes?
- So we write to 5 + t5
- For some reason I'm not writing to this byte, I'm still writing erroneously.

# Sequence
- First check the shifting operators
- These are probably used in all the above, so if these don't work as they are supposed to the other tests definitely won't work either.
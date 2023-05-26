# zen-one
third try at fpga verilog vivado

* same toy 16 bit retro cpu as zen-x but re-written
* ad-hoc pipe-line where the next instruction is read while current is executed
* instead of ROM and RAM one dual-port RAM module
* one cycle per instruction for ALU, store
* two cycles per instruction for load immediate, call, jump and return


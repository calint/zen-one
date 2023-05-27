# zen-one
experimental retro 16 bit cpu written in verilog xilinx vivado intended for fpga Cmod S7 from Digilent

third try at fpga verilog vivado

* same toy 16 bit retro cpu as 'zen-x' but re-written
* ad-hoc pipeline where the next instruction is fetched while current is executed
* ad-hoc pipeline resolution for register being loaded and used in the same instruction
* dual-port RAM instead of ROM and RAM
* one cycle per instruction for ALU, load and store
* two cycles for load immediate
* two cycles for call and jump if branch taken
* two cycles for instructions that also return from current call
* all core components run on positive edge of the clock

```
                          
                          
                       z   n - r   c      vintage 16 bit cpu
                       e   e   e   a 
                       r   g   t   l      64K 16 bit ram
                       o   a   u   l      16  16 bit registers
                           t   r          64  calls stack
                           i   n          66  MHz
                           v              
                           e

                     | 0 | 1 | 2 | 3 |   4 - 7   | 8-11 | 12-15|        
                     |---|---|---|---|-----------|------|------|        
                     | z | n | r | c |   op      | rega | regb |        
                     |---|---|---|---|---|-------|------|------|--------
                     / . / . / . / 0 / 0 / 0 0 0 / .... / .... /  add  /
                    / . / . / . / 0 / 0 / 1 0 0 / .... / .... /  sub  / 
                   / . / . / . / 0 / 0 / 0 1 0 / .... / .... /  or   / 
                  / . / . / . / 0 / 0 / 1 1 0 / .... / .... /  xor  / 
                 / . / . / . / 0 / 0 / 0 0 1 / .... / .... /  and  / 
                / . / . / . / 0 / 0 / 1 0 1 / ...  / .... /  not  / 
               / . / . / . / 0 / 0 / 0 1 1 / .... / .... /  cp   / 
              / . / . / . / 0 / 0 / 1 1 1 / imm4 / .... /  shf  / 
             /---/---/---/---/---/-------/------/------/-------/ 
            / . / . / . / 0 / 1 / 0 0 0 / imm4 / .... /  addi / 
           / . / . / . / 0 / 1 / 1 0 0 / 0000 / .... /  ldi  / 
          / . / . / . / 0 / 1 / 0 1 0 / src  / dst  /  ld   / 
         / . / . / . / 0 / 1 / 1 1 0 / dst  / src  /  st   / 
        / . / . / . / 0 / 1 / 0 0 1 / .... / .... /       / 
       / . / . / . / 0 / 1 / 1 0 1 / .... / .... /       / 
      / . / . / . / 0 / 1 / 0 1 1 / .... / .... /       / 
     / . / . / . / 0 / 1 / 1 1 1 / .... / .... /       / 
    /---/---/---/---/---/-------/------/------/-------/ 
   / . / . / 0 / 1 /    immediate 12 << 4    /  call / 
  / . / . / 1 / 1 /   signed immediate 12   /  jmp  / 
 /---/---/---/---/---/-------/------/------/-------/ 
 \ . \ . \ . \ 0 \ 1 \ 1 0 0 \ 0100 \ .... \  wl   \
  \ . \ . \ . \ 0 \ 1 \ 1 0 0 \ 0101 \ .... \  wh   \
   \ . \ . \ . \ 0 \ 1 \ 1 0 0 \ 0110 \ .... \  rl   \
    \ . \ . \ . \ 0 \ 1 \ 1 0 0 \ 0111 \ .... \  rh   \
     \ . \ . \ . \ 0 \ 1 \ 1 0 0 \ 1100 \ .... \       \
      \ . \ . \ . \ 0 \ 1 \ 1 0 0 \ 1101 \ .... \       \
       \ . \ . \ . \ 0 \ 1 \ 1 0 0 \ 1110 \ .... \ led   \
        \ . \ . \ . \ 0 \ 1 \ 1 0 0 \ 1111 \ imm4 \ ledi  \
 

  op  :       : cyc |
 -----:-------:-----:--------------------------------------
 0000 : add   :  1  : reg[b] += reg[a]
 0010 : sub   :  1  : reg[b] -= reg[a] 
 0100 : or    :  1  : reg[b] |= reg[a] 
 0110 : xor   :  1  : reg[b] ^= reg[a] 
 1000 : and   :  1  : reg[b] &= reg[a] 
 1010 : not   :  1  : reg[b] = ~reg[a] 
 1100 : cp    :  1  : reg[b] = reg[a]
 1110 : shf   :  1  : reg[b] >>= (imm4>=0?++imm4:-imm4)
 -----:-------:-----:--------------------------------------
 0001 : addi  :  1  : reg[b] += (imm4>=0?++imm4:-imm4)
 0011 : ldi   :  2  : reg[b] = { next instruction }
 0101 : ld    :  1  : reg[b] = ram[a]
 0111 : st    :  1  : ram[a] = reg[b]
 1001 :       :     : 
 1011 :       :     :
 1101 :       :     :
 1111 :       :     : 
 -----:-------:-----:--------------------------------------

  rc  :       : cyc :
 -----+-------+-----+--------------------------------------
  01  : call  :  2  : pc = imm12 << 4
  11  : jmp   :  2  : pc += signed imm12
 -----+-------+-----+--------------------------------------

i/o
 |z|n|r|c| op |rega|regb| mnemo | description
 |-+-+-+-+----+----+----+-------+--------------------------------------
 |.|.|.|0|1100|0100|....|  wl   | uart blocking write lower regs[b]
 |.|.|.|0|1100|0101|....|  wh   | uart blocking write higher regs[b]
 |.|.|.|0|1100|0110|....|  rl   | uart blocking read lower regs[b]
 |.|.|.|0|1100|0111|....|  rh   | uart blocking read higher regs[b]
 |.|.|.|0|1100|1100|....|       | 
 |.|.|.|0|1100|1101|....|       | 
 |.|.|.|0|1100|1110|....|  led  | sets leds to lower 4 bits of regs[b]
 |.|.|.|0|1100|1111|imm4|  ledi | sets leds to imm4

zn flags in instructions are compared with current flags
instruction executes according to:
 * zn=11 : always
 * zn=00 : positive number
 * zn=10 : zero
 * zn=01 : negative number

instructions with rc=10 return from call

how-to with Vivado v2023.1:
 * to program device edit path to RAM file in "zen-one.srcs/sources_1/new/SoC.v"
 * connect fpga board Cmod S7 from digilent.com
 * run synthesis, run implementation, program device
 * find out which tty is on the usb connected to the card (i.e. /dev/ttyUSB1)
 * connect with terminal at 9600 baud, 8 bits, 1 stop bit, no parity 
 * button 0 is reset, click it to restart and display the prompt
 * "HELLO" is the prompt
 * after the prompt the program enters a read / write loop (echo)
 
programming zen-x
 * use 'zasm' to compile assembler code
 * see 'notes/zasm-samples/' for examples.


```
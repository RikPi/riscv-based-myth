# RISC-V_MYTH_Workshop

## Introduction
Welcome to the section where I illustrate the parts of TL-Verilog code developed during the labs. It was my absolute first time coding at such low level, before this I have never done any C, Assembly or hardware description language. 

It was a very tough course, but it was rewarding and well explained! I had a lot of fun and I feel like that I learned a lot.

## Calculator
All the versions of the calculator had been saved in different Makerchip Sandboxes, making it possible to simulate it step by step. Unfortunately, due to a bug in Makerchip, the Sandboxes are no longer available.

The purpose of this exercise was playing with TL-Verilog, in order to get exposed to certain topics such as:
* Muxes
* Ternary operator
* Subdivision in cycles and cycle-delayed variables
* Value formatting
### First calculator exercise
The two input values were defined as random:
```
$val1[31:0] = $rand1[3:0];
$val2[31:0] = $rand2[3:0];
```
This is not a necessary step in this development environment since uninitialized variables always default to random.

The operations were defined as follows:
```
$sum[31:0] = $val1[31:0] + $val2[31:0];
$diff[31:0] = $val1[31:0] - $val2[31:0];
$prod[31:0] = $val1[31:0] * $val2[31:0];
$quot[31:0] = $val1[31:0] / $val2[31:0];
```
It can be noticed that all variables are 32-bit, even though we are working with a 4-bit random input.

Finally, the mux choosing the value to return was coded as follows:
```
//Define mux selector
$op[2:0] = $rand[2:0];
         
//Define muxed output
$out[31:0] = 
    $op == 0 ? $sum[31:0] :
    $op == 1 ? $diff[31:0] :
    $op == 2 ? $prod[31:0] :
    $quot[31:0];
//In this calculator, the default operation is the division
```
The operations are always performed and the result returned to $out is chosen by the $op variable. The default return is the division operation.

### Second calculator exercise
In this exercise, the concept of cycle and using a value from previous cycle is introduced. The objective of this lab is to use the result from the previous cycle as the first operand of the current cycle, pretty much like the Ans key in a calculator.

The code is very similar to the previous one, with the addition of a cycle-delayed variable:
```
$sum[31:0] = >>1$out[31:0] + $val2[31:0];
$diff[31:0] = >>1$out[31:0] - $val2[31:0];
$prod[31:0] = >>1$out[31:0] * $val2[31:0];
$quot[31:0] = >>1$out[31:0] / $val2[31:0];
```
The only difference lies in this snippet. The >>1 operator is the one that delays the value by one cycle, or that calls the value of the previous cycle through a flip-flop.

### Third calculator exercise
This lab's objective is introducing the concept of validity. The calculator will only return a value if the input is valid, otherwise it will return 0. In this case, validity is defined using:
```
$valid[0:0] = $reset ? 0 : (>>1$valid[0:0] +1);
```
This waveform is low when reset is high, otherwise it is increased by 1. Since $valid is defined as a binary value, this means it will be oscillating between 1 and 0 every cycle when reset is low.

Since we are now using operating a two-cycle calculator, we need validity to avoid using a value from every other cycle. This is done by using the following code:
```
$out[31:0] = 
    $reset || !$valid ? 32'b0 :
    $op == 0 ? $sum[31:0] :
    $op == 1 ? $diff[31:0] :
    $op == 2 ? $prod[31:0] :
    $quot[31:0];
```
### Fourth calculator exercise
To refine the $out mux, instead of zeroing every other cycle, we can use the $valid operator to avoid wasting resources and execute the code each 2 cycles. To achieve this, the following operator is defined and used to wrap the code:
```
$valid_or_reset = $valid || $reset;
```
To wrap it around the code, the correct syntax is the following:
```
?$valid_or_reset
    //INDENTED CODE
```
This way, each time the value is valid, the code will be executed, otherwise it will be skipped.

### Fifth calculator exercise
This last lab on the calculator lets us create a memory function for it. This is achieved by adding two new operations: store and recall. The store operation will store the value of the previous cycle in $mem, while the recall operation will return the value memorized to $out. Store is added using a mux for $mem:
```
$mem[31:0] =
    $reset ? 32'b0 :
    $op == 4 ? >>2$out[31:0] :
    >>2$mem[31:0];
```
In this way, if $op == 4, the >>2$out value will get stored in the $mem variable. As it can be noted, the memory will by default keep storing the last value stored.

The recall operation is added to the $out mux:
```
$out[31:0] = 
    $op == 0 ? $quot[31:0] :
    $op == 1 ? $diff[31:0] :
    $op == 2 ? $prod[31:0] :
    $op == 3 ? $mem[31:0] :
    $sum[31:0];
```
In this way, if $op == 3, the $mem value will get recalled, put in $out and used as the first operand for the next cycle.

[FULL CODE FOR CALCULATOR HERE](https://github.com/RISCV-MYTH-WORKSHOP/riscv-myth-workshop-sep23-RikPi/blob/master/Day3_5/calculator_solutions.tlv)

## RISC-V CPU
This section illustrates step by step the design of the RISC-V CPU, lab by lab. The text will follow the commit history to better showcase the development process. Each lab has its own subsection.

### Next PC
As a first building block for the CPU, we need to think about how to increment the pointer each cycle to get to the next instruction. To achieve this, since the instructions are 32-bit, we need to add 4 to the current pointer. This is done by using the following code:
```
//PC implementation such as it increments 32'd4 each cycle and
//resets to 0 the cycle after the reset signal is issued
$pc[31:0] =
    >>1$reset ? 32'd0 :
    >>1$pc[31:0] + 32'd4;
```
The >>1 operator is used to increment the previous cycle's value of $pc. When reset pulls high, $pc gets reset to 0.

### Fetch
During this lab, the $pc is used as the address of the instruction memory to fetch. To achieve this, the instruction memory read is enabled by setting $imem_rd_en to 1 when no reset signal is present and the addesss is set as follows:
```
$imem_rd_en = !$reset;
$imem_rd_addr[M4_IMEM_INDEX_CNT-1:0] = $pc[M4_IMEM_INDEX_CNT+1:2];
```
The constant M4_IMEM_INDEX_CNT represents the size of the instruction memory.

After this, the memory is read to get the $instr value, which is the instruction to be executed. This happens in the next cycle, as shown below:
```
@1
    $instr[31:0] = $imem_rd_data[31:0];
```

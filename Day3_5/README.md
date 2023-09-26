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
    $op == 3'b000 ? $sum[31:0] :
    $op == 3'b001 ? $diff[31:0] :
    $op == 3'b010 ? $prod[31:0] :
    $quot[31:0];
//In this calculator, the default operation is the division
```
The operations are always performed and the result returned to $out is chosen by the $op variable. The default return is the division operation.

### Second calculator exercise

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
![Next PC diagram](/Day3_5/images/NextPCDiagram.png)

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
![Fetch diagram](/Day3_5/images/FetchDiagram.png)

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
The instruction memory block is a macro that has 2 inputs and 1 output. The inputs are the address ($imem_rd_addr) and the read enable ($imem_rd_en), while the output is the data read from the memory ($imem_rd_data).

### Decode
All instruction have types and each type has a different format. The first step to decode the instruction is to determine its type. This can be done by looking at [The RISC-V Instruction Set Manual](https://riscv.org/wp-content/uploads/2017/05/riscv-spec-v2.2.pdf). The following image shows the different instruction types and the way of recognizing them:
![Instruction types](/Day3_5/images/InstructionTypesTable.png)

As we can observe, the instruction types can be recognized by comparing $instr[6:2] with the values on the table. Additionally, to avoid coding in every possibility, we can use the "don't care" bit "x" with the operator ==?, meaning that that particular bit can be 0 or 1, but it doesn't matter. The implementation is as follows:
```
 //Check instruction type I, R, S, B, J, U
$is_i_instr = 
    $instr[6:2] ==? 5'b0000x ||
    $instr[6:2] ==? 5'b001x0 ||
    $instr[6:2] ==? 5'b11001;

$is_r_instr = 
    $instr[6:2] ==? 5'b01011 ||
    $instr[6:2] ==? 5'b011x0 ||
    $instr[6:2] ==? 5'b10100;

$is_s_instr = 
    $instr[6:2] ==? 5'b0100x;

$is_b_instr = 
    $instr[6:2] ==? 5'b11000;

$is_j_instr = 
    $instr[6:2] ==? 5'b11011;

$is_u_instr = 
    $instr[6:2] ==? 5'b0x101;
```
For each type of instruction, we have a binary signal that is high when the instruction is of that type. It can be noticed that the usage of the don't care bit shortens the code, allowing us to halve the number of comparisons each time a x is present.

We now have a working instruction type decoder, but we still need to decode the instruction itself.

### Instruction Immediate Decoding
The immediate is an important field of the instructions, carrying with it the value to be used in the operation. The immediate can be of different sizes, depending on the instruction type. The following table shows the different encodings:
![Immediate encodings](/Day3_5/images/InstructionImmediateTable.png)

As it can be noticed, the R-instruction is missing: this is because the immediate is not present in this type of instruction and it is defaulted to 32'b0 a 32-bit zero. To decode the immediate, we use the ternary operator, effectively creating a mux, the code is as follows:
```
//Immediate decoding using types
$imm[31:0] = 
    $is_i_instr ? { {21{$instr[31]}}, $instr[30:20] } :
    $is_s_instr ? { {21{$instr[31]}}, $instr[30:25], $instr[11:7] } :
    $is_b_instr ? { {20{$instr[31]}}, $instr[7], $instr[30:25], $instr[11:8], 1'b0 } :
    $is_u_instr ? { $instr[31:12], 12'b0 } :
    $is_j_instr ? { {12{$instr[31]}}, $instr[19:12], $instr[20], $instr[30:21], 1'b0 } :
    32'b0; //R instruction
```
This code also shows us some rather interesting and useful syntax of TL-Verilog regarding bit chaining:
* Bits can be chained using curly brackets and comma separation, for example {a,b,c} concatenates a, b and c.
* Bits can be repeated using curly brackets and the number of repetitions, for example {5{a}} concatenates a 5 times.

Now that the immediate is decoded, we are missing the other functions of the instruction, such as the registers to be used.

### Instruction Decode
In this lab, we will decode the other fields of the instruction as seen in the following image:
![Instruction decode table](/Day3_5/images/InstructionDecodeTable.png)

The RISC-V ISA is built in such a way that the fields are always in the same position, regardless of the instruction type. This means that we can easily decode them using the following code:
```
//Decode opcode
$opcode[6:0] = $instr[6:0];

//Decode rd
$rd[4:0] = $instr[11:7];

//Decode rs2
$rs2[4:0] = $instr[24:20];

//Decode rs1
$rs1[4:0] = $instr[19:15];

//Decode funct3
$funct3[2:0] = $instr[14:12];

//Decode funct7
$funct7[6:0] = $instr[31:25];
```
The $opcode field, $funct3 and $funct7[5] are used to determine the operation to be performed, while $rd, $rs1 and $rs2 are used to determine the registers to be used.

### RISC-V Instruction Field Decoding
As we can notice from the previous sections' table, not all the fields are used in every instruction. This means that computing all of them for every instruction is a waste of resources. To avoid this, we can introduce validity conditions for each field decode operation, in this way the field gets decoded only if it makes sense. This is done by using the following code:
```
//Decode rd based on instr type
$rd_valid = $is_r_instr || $is_i_instr || $is_u_instr || $is_j_instr;
?$rd_valid
    $rd[4:0] = $instr[11:7];

//Decode rs2 based on instr type
$rs2_valid = $is_r_instr || $is_s_instr || $is_b_instr;
?$rs2_valid
    $rs2[4:0] = $instr[24:20];

//Decode rs1 based on instr type
$rs1_valid = $is_r_instr || $is_i_instr || $is_s_instr || $is_b_instr;
?$rs1_valid
    $rs1[4:0] = $instr[19:15];

//Decode funct3 based on instr type
$funct3_valid =  $is_r_instr || $is_i_instr || $is_s_instr || $is_b_instr;
?$funct3_valid
    $funct3[2:0] = $instr[14:12];

//Decode funct7 based on instr type
$funct7_valid = $is_r_instr;
?$funct7_valid
    $funct7[6:0] = $instr[31:25];
```
Now that we are decoding all the fields of the instruction, we can start thinking about the actual operations to be performed.

### Instruction Decode
We can now decode the whole instruction and match it to an assembly operation. Since the program we are trying to run is a program that sums numbers from 1 to 9, we will start with only the operations needed for that. The program's code is as follows:
```
// External to function:
m4_asm(ADD, r10, r0, r0)             // Initialize r10 (a0) to 0.
// Function:
m4_asm(ADD, r14, r10, r0)            // Initialize sum register a4 with 0x0
m4_asm(ADDI, r12, r10, 1010)         // Store count of 10 in register a2.
m4_asm(ADD, r13, r10, r0)            // Initialize intermediate sum register a3 with 0
// Loop:
m4_asm(ADD, r14, r13, r14)           // Incremental addition
m4_asm(ADDI, r13, r13, 1)            // Increment intermediate register by 1
m4_asm(BLT, r13, r12, 1111111111000) // If a3 is less than a2, branch to label named <loop>
m4_asm(ADD, r10, r14, r0)            // Store final result to register a0 so that it can be read by main program
```
Thus, we need the operations:
* **ADD**, that adds the values in registers rs1 and rs2 and stores the result in rd.
* **ADDI**, that adds the value in register rs1 with the immediate and stores the result in rd.
* **BLT**, that branches to the $pc+$imm instruction if the value in rs1 is less than the value in rs2.

On top of this, we will also add decoding for:
* **BEQ**, that branches to the $pc+$imm instruction if the value in rs1 is equal to the value in rs2.
* **BNE**, that branches to the $pc+$imm instruction if the value in rs1 is not equal to the value in rs2.
* **BGE**, that branches to the $pc+$imm instruction if the value in rs1 is greater than or equal to the value in rs2.
* **BLTU**, that branches to the $pc+$imm instruction if the value in rs1 is less than the value in rs2, unsigned.
* **BGEU**, that branches to the $pc+$imm instruction if the value in rs1 is greater than or equal to the value in rs2, unsigned.

This decoding can be achieved by chaining the bits using for recognizing the operations and checking them using this table:
![Operation decode table](/Day3_5/images/OperationDecodeTable.png)

The code is as follows:
```
//Decode assembly instructions
$dec_bits[10:0] = {$funct7[5], $funct3, $opcode}; //Bits for decoding

$is_beq = $dec_bits ==? 11'bx_000_1100011; //BEQ
$is_bne = $dec_bits ==? 11'bx_001_1100011; //BNE
$is_blt = $dec_bits ==? 11'bx_100_1100011; //BLT
$is_bge = $dec_bits ==? 11'bx_101_1100011; //BGE
$is_bltu = $dec_bits ==? 11'bx_110_1100011; //BLTU
$is_bgeu = $dec_bits ==? 11'bx_111_1100011; //BGEU
$is_addi = $dec_bits ==? 11'bx_000_0010011; //ADDI
$is_add = $dec_bits ==? 11'b0_000_0110011; //ADD
```
The $dec_bits variable is used to decode the operation, it is a concatenation of the $funct7[5], $funct3 and $opcode bits. Once they are chained together, we can compare them to the values in the table using the ==? operator because of the presence of don't care bits. In fact, we are using the $funct7[5] bit even if it is not valid for most of the operations, but in this way we can just have a single $dec_bits variable for all the operations.

### Register File Read (part 1)

The register file is a memory block that stores the values of the registers. It has 2 read ports and 1 write port. The read ports are used to read the values of the registers, while the write port is used to write the values in the registers. The register file is a macro that has 7 inputs and 2 outputs. The inputs are:
* Read addresses $rf_rd_index1 and $rf_rd_index2, that are used to select the registers to be read.
* Write address $rf_wr_index, that is used to select the register to be written to.
* The read/write enable signals $rf_ed_en1, $rf_rd_en2 and $rf_wr_en, that are used to enable the read and write operations.
* The write data $rf_wr_data, that is used to write the value in the $rf_wr_index register.

The outputs are the read data signals($rf_rd_data1 and $rf_rd_data2), that are used to read the values of the registers indexed by $rf_rd_index1 and $rd_rd_index2.
![Register file diagram](/Day3_5/images/RegisterFileDefinition.png)

We are now interested in setting up the read operations by firstly enabling read and passing the indexes to the register file. This is done by using the following code:
```
//Read data from register file
//Enable rd 1 with rs 1
$rf_rd_en1 = $rs1_valid;
//Give index to rd 1
$rf_rd_index1[4:0] = $rs1;

//Enable rd 2 with rs 2
$rf_rd_en2 = $rs2_valid;
//Give index to rd 2
$rf_rd_index2[4:0] = $rs2;
```
Since rs1 and rs2 are the addresses of the registers to be read, we can use their validity condition to enable the read operation. The indexes are then passed to the register file.

### Register File Read (part 2)
![Register file read diagram](/Day3_5/images/RegisterRead2Diagram.png)

After we have passed the indices and enabled read, we can go and return the values read from the register file as shown in the above diagram. This is done by using the following code:
```
//Output to ALU
$src1_value[31:0] = $rf_rd_data1;
$src2_value[31:0] = $rf_rd_data2;
```
In this way, we have saved the two output 32-bit values from the register memory to variables we will input to the ALU.

### ALU
![ALU diagram](/Day3_5/images/ALUDiagram.png)

The ALU (Arithmetic Logic Unit) is the core of the CPU, it is the block that performs the actual operations. It is essentially a mux that chooses the output based on the assembly instruction. Since we have added decoding support for ADD and ADDI, these two will be the operations implemented in the ALU for now:
```
//ALU
$result[31:0] = 
    $is_addi ? $src1_value + $imm :
    $is_add ? $src1_value + $src2_value :
    32'bx;
```
As written previousli, ADD sums together the values corresponding to addresses rs1 and rs2, while ADDI sums together the value corresponding to address rs1 and the immediate. The result is then stored in the $result variable, the output of the ALU. The ALU also has a default value of 32'bx, meaning that if the instruction is not ADD or ADDI, the output will be undefined.

### Register File Write
![Register file write diagram](/Day3_5/images/RegisterWriteDiagram.png)

After performing the calculations in the ALU, the result needs to be written back to the register file. This is done by using the following code:
```
//Write to register file
//Enable if $rd_valid and $rd != 0
$rf_wr_en = $rd_valid && $rd != 5'b0;
//Give index
$rf_wr_index[4:0] = $rd;
//Write result of ALU
$rf_wr_data[31:0] = $result;
```
As we can note, the write operation is enabled only if the instruction contains a $rd value and if it is not zero. This second condition is needed because the register file's zero register is hardwired to 0 and cannot be written to. After this, the index and the data are passed to the register file.

### Branches (part 1)
![Branches diagram](/Day3_5/images/Branches1Diagram.png)

The branch instructions are used to change the flow of the program. They are used to jump to a different instruction based on a condition. The condition is determined by the values of the registers rs1 and rs2. The first step is to determine if a branch has been taken, based on the current instruction and the values of the values read from the memory. This is done by using the following code:
```
//Branching implementation
$taken_br = 
    $is_beq ? ($src1_value == $src2_value) :
    $is_bne ? ($src1_value != $src2_value) :
    $is_blt ? (($src1_value < $src2_value) ^ ($src1_value[31] != $src2_value[31])) :
    $is_bge ? (($src1_value >= $src2_value) ^ ($src1_value[31] != $src2_value[31])) :
    $is_bltu ? ($src1_value < $src2_value) :
    $is_bgeu ? ($src1_value >= $src2_value) :
    1'b0;
```
In this way, we have a binary signal that is high when the branch is taken by computing the condition related to the specific branch instruction. For example, in the case of a BEQ, the program evaluates if the two values are equal and sets the $taken_br signal high if they are. Thus, we know if a branching instruction is called and if the branch is taken. The default value of $taken_br is 1'b0, meaning that if the instruction is not a branch, the branch is not taken.

### Branches (part 2)
![Branches diagram](/Day3_5/images/Branches2Diagram.png)

After having determined if the branch is taken, we need to compute the address of the next instruction. This is done by adding the immediate to $pc:
```
$br_tgt_pc[31:0] = $pc + $imm;
```
The $br_tgt_pc variable is the address of the next instruction if the branch is taken. To make this effective, we need to update the $pc variable with the new address if the branch is taken. This is done by using the following code:
```
$pc[31:0] =
    >>1$reset ? 32'd0 :
    >>1$taken_br ? >>1$br_tgt_pc :
    >>1$pc[31:0] + 32'd4;
```

### Testbench
To conclude the first part of the RISC-V CPU development, a pass condition is added to the program to check if the result is correct:
```
*passed = |cpu/xreg[10]>>5$value == (1+2+3+4+5+6+7+8+9);
```
This line checks if the value in register 10 is equal to the sum of the numbers from 1 to 9. If it is, the simulation is passed, otherwise it runs until the maximum cycles of the simulation allowed by Makerchip.

## RISC-V CPU with Pipelining
After having designed this first CPU, we will get on to pipeline the architecture. This means that we will be able to execute multiple instructions at the same time, increasing the performance of the CPU. The pipeline will be 5 stages long, as shown in the following image:
![Pipeline diagram](/Day3_5/images/PipelineDiagram.png)

This comes with a few challenges, such as hazards. Hazards are situations in which the pipeline cannot continue executing instructions because it is waiting for a previous instruction to finish. There are 3 types of hazards:
* **Structural hazards**, that happen when two instructions need to use the same resource at the same time. They can be caused by the use of the same register or memory block.
* **Data hazards**, that happen when an instruction needs to use a value that is not ready yet. This can happen when the instruction is using a value that is being calculated by a previous instruction. For example, in the image we can see that the register file read is in stage @2, whereas the write is in stage @4. This means that the value read from the register file will risk being read before being written.
* **Control hazards**, that happen when the instruction to be executed next is not known yet. This can happen when branching or jumping is performed, since the next instruction to be executed is not the one after the current one and needs to be computed.

By looking at the waterfall diagram of the instructions we can see the hazards more clearly:
![Waterfall diagram](/Day3_5/images/WaterfallDiagramBefore.png)

As we can see, the red arrow indicates a read after write hazard and the blue one indicates a control flow hazard. In short, the red arrow shows that we are trying to read a value from the memory, using the >>1 operator, but the value is actually written two cycles later. The blue arrow shows that we are trying to branch to a different instruction, but we don't know which one yet because we are trying to read the value of the branch two cycles before it is actually computed.

To solve this in the easy way we can operate the CPU every third cycle, to avoid the hazards. This can be seen in the following picture:
![Waterfall diagram](/Day3_5/images/WaterfallDiagramAfter.png)

Now, there is no hazard in place and this can be further noted in the following waterfall logic diagram:
![Waterfall logic diagram](/Day3_5/images/WaterfallLogicDiagram.png)

We can observe that all the values are now consumed in the correct cycle, avoiding any hazard. This is a very simple way of avoiding hazards, but it is not very efficient since we are only using the CPU every third cycle.

### 3-cycle $valid
The first step to pipeline the CPU is to add a 3-cycle validity signal. This means that the CPU will be used every 3 cycles, as seen in the previous section. This is done by using the following code:
```
//Start pulse right after reset was 1 in previous cycle
$start = (!$reset && >>1$reset);
//Valid pulse every 3 cycles
$valid = ($start ==? 1 || >>3$valid ==? 1 && !$reset);
```
The $start signal is pulled high the cycle in which the $reset signal is first pulled low. The $valid signal is pulled high every 3 cycles starting from the cycle the $start signal is first pulled high. This is done by using the >>3 operator, that delays the value by 3 cycles. This is all until the $reset signal is pulled high, in which case the $valid signal is pulled low. The signal waveforms can be seen below:
![Valid waveform](/Day3_5/images/3CycleValid.png)

### 3-Cycle RISC-V (part 1)
![3-Cycle RISC-V diagram](/Day3_5/images/3CycleRISCV1.png)

Now, we need to avoid writing to the memory when the $valid signal is low. This is done by modifying the $rf_wr_en code:
```
$rf_wr_en = $rd_valid && $valid && $rd != 5'b0;
```
In a similar way, we have to avoid branching in invalid cycles. This is done by introducing $valid_taken_br:
```
$valid_taken_br = $valid && $taken_br;
```
Finally, we need to take care of the $pc by correctly aligning the $pc increment and branch instruction. This is done by using the following code:
```
$pc[31:0] =
    >>1$reset ? 32'd0 :
    >>3$valid_taken_br ? >>3$br_tgt_pc :
    >>3$inc_pc;
```
The $inc_pc variable is introduced here and is the $pc incremented by 32'd4, while the $br_tgt_pc is the $pc incremented by the immediate. The >>3 operator is used to delay the value by 3 cycles, in order to align the $pc change with the branch instruction.

### 3-Cycle RISC-V (part 2)
![3-Cycle RISC-V diagram](/Day3_5/images/3CycleRISCV2.png)

The next step is partitioning the logic in the stages shown above. This means that we need to refactor the code as shown in [this commit](https://github.com/RISCV-MYTH-WORKSHOP/riscv-myth-workshop-sep23-RikPi/commit/e75c2098cbb4a6ea2e61b1a2f654cf9062325021). After doing this, we proceed to change the stage values for the m4+rf macro to reflect which stages read and write are now in. This means that now:
```
m4+rf(@2, @3)  // Args: (read stage, write stage) - if equal, no register bypass is required
```


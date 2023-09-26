\m4_TLV_version 1d: tl-x.org
\SV
  // =================================================
   // For this project, "Load/Store in Program"
   // See: https://makerchip.com/sandbox/0zpfRhXRB/0AnhyJ
   // =================================================




   // This code can be found in: https://github.com/stevehoover/RISC-V_MYTH_Workshop
   
   m4_include_lib(['https://raw.githubusercontent.com/BalaDhinesh/RISC-V_MYTH_Workshop/master/tlv_lib/risc-v_shell_lib.tlv'])

\SV
   m4_makerchip_module   // (Expanded in Nav-TLV pane.)
\TLV

   // /====================\
   // | Sum 1 to 9 Program |
   // \====================/
   //
   // Program for MYTH Workshop to test RV32I
   // Add 1,2,3,...,9 (in that order).
   //
   // Regs:
   //  r10 (a0): In: 0, Out: final sum
   //  r12 (a2): 10
   //  r13 (a3): 1..10
   //  r14 (a4): Sum
   // 
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
   //DMEM istructions to try LW and SW
   m4_asm(SW, r0, r10, 100)
   m4_asm(LW, r15, r0, 100)
   
   // Optional:
   // m4_asm(JAL, r7, 00000000000000000000) // Done. Jump to itself (infinite loop). (Up to 20-bit signed immediate plus implicit 0 bit (unlike JALR) provides byte address; last immediate bit should also be 0)
   m4_define_hier(['M4_IMEM'], M4_NUM_INSTRS)

   |cpu
      @0
         $reset = *reset;
         
         //PC implementation such as it increments 32'd4 each cycle and
         //resets to 0 the cycle after the reset signal is issued
         $pc[31:0] =
            >>1$reset ? 32'd0 :
            >>3$valid_taken_br ? >>3$br_tgt_pc :
            >>3$valid_load ? >>3$inc_pc :
            >>1$inc_pc;
         
         //Enable memory reading and receiving the PC address
         $imem_rd_en = !$reset;
         $imem_rd_addr[3-1:0] = $pc[3+1:2];
         
      @1
         //Read instruction from memory
         $instr[31:0] = $imem_rd_data[31:0];
         
         //Increment PC
         $inc_pc[31:0] = $pc + 32'd4;
         
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
         
         //Immediate decoding using types
         $imm[31:0] = 
            $is_i_instr ? { {21{$instr[31]}}, $instr[30:20] } :
            $is_s_instr ? { {21{$instr[31]}}, $instr[30:25], $instr[11:7] } :
            $is_b_instr ? { {20{$instr[31]}}, $instr[7], $instr[30:25], $instr[11:8], 1'b0 } :
            $is_u_instr ? { $instr[31:12], 12'b0 } :
            $is_j_instr ? { {12{$instr[31]}}, $instr[19:12], $instr[20], $instr[30:21], 1'b0 } :
            32'b0; //R instruction
         
         //Decode opcode
         $opcode[6:0] = $instr[6:0];
         
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
         $is_lui = $dec_bits ==? 11'bx_xxx_0110111; //LUI
         $is_auipc  = $dec_bits ==? 11'bx_xxx_0010111; //AUIPC
         $is_jal = $dec_bits ==? 11'bx_xxx_1101111; //JAL
         $is_jalr = $dec_bits ==? 11'bx_000_1100111; //JALR
         $is_lb = $dec_bits ==? 11'bx_000_0000011; //LB
         $is_lh = $dec_bits ==? 11'bx_001_0000011; //LH
         $is_lw = $dec_bits ==? 11'bx_010_0000011; //LW
         $is_lbu = $dec_bits ==? 11'bx_100_0000011; //LBU
         $is_lhu = $dec_bits ==? 11'bx_101_0000011; //LHU
         $is_sb = $dec_bits ==? 11'bx_000_0100011; //SB
         $is_sh = $dec_bits ==? 11'bx_001_0100011; //SH
         $is_sw = $dec_bits ==? 11'bx_010_0100011; //SW
         $is_slti = $dec_bits ==? 11'bx_010_0010011; //SLTI
         $is_sltiu = $dec_bits ==? 11'bx_011_0010011; //SLTIU
         $is_xori = $dec_bits ==? 11'bx_100_0010011; //XORI
         $is_ori = $dec_bits ==? 11'bx_110_0010011; //ORI
         $is_andi = $dec_bits ==? 11'bx_111_0010011; //ANDI
         $is_slli = $dec_bits ==? 11'b0_001_0010011; //SLLI
         $is_srli = $dec_bits ==? 11'b0_101_0010011; //SRLI
         $is_srai = $dec_bits ==? 11'b1_101_0010011; //SRAI
         $is_sub = $dec_bits ==? 11'b1_000_0110011; //SUB
         $is_sll = $dec_bits ==? 11'b0_001_0110011; //SLL
         $is_slt = $dec_bits ==? 11'b0_010_0110011; //SLT
         $is_sltu = $dec_bits ==? 11'b0_011_0110011; //SLTU
         $is_xor = $dec_bits ==? 11'b0_100_0110011; //XOR
         $is_srl = $dec_bits ==? 11'b0_101_0110011; //SRL
         $is_sra = $dec_bits ==? 11'b1_101_0110011; //SRA
         $is_or = $dec_bits ==? 11'b0_110_0110011; //OR
         $is_and = $dec_bits ==? 11'b0_111_0110011; //AND
         $is_load = $opcode == 7'b0000011; //LB, LH, LW, LBU, LHU
         
         *passed = |cpu/xreg[15]>>5$value == (1+2+3+4+5+6+7+8+9);
         
      @2
         //Read data from register file
         //Enable rd 1 with rs 1
         $rf_rd_en1 = $rs1_valid;
         //Give index to rd 1
         $rf_rd_index1[4:0] = $rs1;
         //Output to ALU
         $src1_value[31:0] = 
            (>>1$rf_wr_en && (>>1$rf_wr_index == $rf_rd_index1)) ? >>1$result :
            $rf_rd_data1;
         
         //Enable rd 2 with rs 2
         $rf_rd_en2 = $rs2_valid;
         //Give index to rd 2
         $rf_rd_index2[4:0] = $rs2;
         //Output to ALU
         $src2_value[31:0] = 
            (>>1$rf_wr_en && (>>1$rf_wr_index == $rf_rd_index2)) ? >>1$result :
            $rf_rd_data2;
         
         //Compute PC targeted by branching
         $br_tgt_pc[31:0] = $pc + $imm;
         
      @3
         //Branching implementation
         $taken_br = 
            $is_beq ? ($src1_value == $src2_value) :
            $is_bne ? ($src1_value != $src2_value) :
            $is_blt ? (($src1_value < $src2_value) ^ ($src1_value[31] != $src2_value[31])) :
            $is_bge ? (($src1_value >= $src2_value) ^ ($src1_value[31] != $src2_value[31])) :
            $is_bltu ? ($src1_value < $src2_value) :
            $is_bgeu ? ($src1_value >= $src2_value) :
            1'b0;
         
         //Validity based on branching
         $valid = !(>>1$valid_taken_br || >>2$valid_taken_br || >>1$valid_load || >>2$valid_load);
         
         //Validity of branching
         $valid_taken_br = $valid && $taken_br;
         
         //Calculating intermediates for SLT and SLTI
         //Using verification to avoid wasting resources each cycle
         ?$is_slt
            $sltu_rslt[31:0] = $src1_value < $src2_value;
         ?$is_slti
            $sltiu_rslt[31:0] = $src1_value < $imm;
         
         //ALU
         $result[31:0] = 
            ($is_addi || $is_load || $is_s_instr) ? $src1_value + $imm :
            $is_add ? $src1_value + $src2_value :
            $is_andi ? $src1_value & $imm :
            $is_ori ? $src1_value | $imm :
            $is_xori ? $src1_value ^ $imm :
            $is_slli ? $src1_value << $imm[5:0] :
            $is_srli ? $src1_value >> $imm[5:0] :
            $is_and ? $src1_value & $src2_value :
            $is_or ? $src1_value | $src2_value :
            $is_xor ? $src1_value ^ $src2_value :
            $is_sub ? $src1_value - $src2_value :
            $is_sll ? $src1_value << $src2_value[4:0] :
            $is_srl ? $src1_value >> $src2_value[4:0] :
            $is_sltu ? $src1_value < $src2_value :
            $is_sltiu ? $src1_value < $imm :
            $is_lui ? {$imm[31:12], 12'b0} :
            $is_auipc ? $pc + $imm :
            $is_jal ? $pc + 4 :
            $is_jalr ? $pc + 4 :
            $is_srai ? { {32{$src1_value[31]}}, $src1_value} >> $imm[4:0] :
            $is_slt ? ($src1_value[31] == $src2_value[31]) ? $sltu_rslt : {31'b0,$src1_value[31]} :
            $is_slti ? ($src1_value[31] == $imm[31]) ? $sltiu_rslt : {31'b0,$src1_value[31]} :
            $is_sra ? { {32{$src1_value[31]}}, $src1_value} >> $src2_value[4:0] :
            32'bx;
         
         //LOAD instruction handling
         $valid_load = $valid && $is_load;
         
         
         
         //Write to register file
         //Enable if $rd_valid and $rd != 0
         $rf_wr_en = ($rd_valid && $valid && $rd != 5'b0) ||>>2$valid_load;
         //Give index
         $rf_wr_index[4:0] = 
            >>2$valid_load ? >>2$rd :
            $rd;
         //Write result of ALU
         $rf_wr_data[31:0] = 
            >>2$valid_load ? >>2$ld_data :
            $result;
         
      @4
         //Implement DMEM
         $dmem_rd_en = $is_load;
         $dmem_wr_en = $valid && $is_s_instr;
         $dmem_addr[3:0] = $result[5:2];
         $dmem_wr_data[31:0] = $src2_value;
         
      @5
         $ld_data = $dmem_rd_data;


      // Note: Because of the magic we are using for visualisation, if visualisation is enabled below,
      //       be sure to avoid having unassigned signals (which you might be using for random inputs)
      //       other than those specifically expected in the labs. You'll get strange errors for these.

   
   // Assert these to end simulation (before Makerchip cycle limit).
   *passed = *cyc_cnt > 40;
   *failed = 1'b0;
   
   // Macro instantiations for:
   //  o instruction memory
   //  o register file
   //  o data memory
   //  o CPU visualization
   |cpu
      m4+imem(@1)    // Args: (read stage)
      m4+rf(@2, @3)  // Args: (read stage, write stage) - if equal, no register bypass is required
      m4+dmem(@4)    // Args: (read/write stage)
      //m4+myth_fpga(@0)  // Uncomment to run on fpga

   m4+cpu_viz(@4)    // For visualisation, argument should be at least equal to the last stage of CPU logic. @4 would work for all labs.
\SV
   endmodule

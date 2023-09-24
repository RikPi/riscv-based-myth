\m5_TLV_version 1d: tl-x.org
\m5
   
   // =================================================
   // First calculator exercise (MUX with 4 operations)
   // See: https://makerchip.com/sandbox/0yPfNhMDo/0r0hzR
   //
   // Second calculator exercise (Using output of previous cycle)
   // See: https://makerchip.com/sandbox/0yPfNhMDo/0r0hqv
   //
   // Third calculator exercise (Two-cycle calculator)
   // See: https://makerchip.com/sandbox/0yPfNhMDo/0pghkk
   //
   // Fourth calculator exercise (Two-cycle with validity)
   // See: https://makerchip.com/sandbox/0yPfNhMDo/0KOhGM
   //
   // Fifth calculator exercise (Two-cyle with validity and single-value memory)
   // See: https://makerchip.com/sandbox/0yPfNhMDo/0g5h7Q
   // =================================================
\SV
   // Macro providing required top-level module definition, random
   // stimulus support, and Verilator config.
   m5_makerchip_module   // (Expanded in Nav-TLV pane.)
\TLV
   |calc
      @0
         $reset = *reset;
      
      @1
         
         //Counter for validity condition (every other cycle)
         $valid[0:0] = $reset ? 0 : (>>1$valid[0:0] +1);
         $valid_or_reset = $valid || $reset;
      
      ?$valid_or_reset
         @1
            //Assigning variables

            $val2[31:0] = $rand2[3:0];
            $val1[31:0] = >>2$out[31:0];
            $op[2:0] = $randop[2:0];

            //Define operations
            $sum[31:0] = $val1[31:0] + $val2[31:0];
            $diff[31:0] = $val1[31:0] - $val2[31:0];
            $prod[31:0] = $val1[31:0] * $val2[31:0];
            $quot[31:0] = $val1[31:0] / $val2[31:0];


         @2
            
            //Define muxed output with reset condition
            $out[31:0] = 
               $op == 0 ? $quot[31:0] :
               $op == 1 ? $diff[31:0] :
               $op == 2 ? $prod[31:0] :
               $op == 3 ? $mem[31:0] :
               $sum[31:0];
            //In this calculator, the default operation is the sum
            //This was changed from $quot because the frequent zeros it gave
            //making it difficult to debug and verify
            
            //Define memory mux
            $mem[31:0] =
               $reset ? 32'b0 :
               $op == 4 ? >>2$out[31:0] :
               >>2$mem[31:0];
            //By default, the memory remembers the value until the calculator
            //puts a new one in memory
         
         
   
   // Assert these to end simulation (before Makerchip cycle limit).
   *passed = *cyc_cnt > 40;
   *failed = 1'b0;
\SV
   endmodule

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
         
         //Counter for validity condition
         $valid[0:0] = $reset ? 0 : (>>1$valid[0:0] +1);
         $valid_or_reset = $valid || $reset;
      
      ?$valid_or_reset
         @1
            //Assigning variables

            $val2[31:0] = $rand2[3:0];
            $val1[31:0] = >>2$out[31:0];

            //Define operations
            $sum[31:0] = $val1[31:0] + $val2[31:0];
            $diff[31:0] = $val1[31:0] - $val2[31:0];
            $prod[31:0] = $val1[31:0] * $val2[31:0];
            $quot[31:0] = $val1[31:0] / $val2[31:0];


         @2

            //Define muxed output with reset condition
            $out[31:0] = 
               $op[0] ? $sum[31:0] :
               $op[1] ? $diff[31:0] :
               $op[2] ? $prod[31:0] :
               $quot[31:0];
            //In this calculator, the default operation is the division

         
         
   
   // Assert these to end simulation (before Makerchip cycle limit).
   *passed = *cyc_cnt > 40;
   *failed = 1'b0;
\SV
   endmodule

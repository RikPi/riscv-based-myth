\m5_TLV_version 1d: tl-x.org
\m5
   
   // =================================================
   // First calculator exercise (MUX with 4 operations)
   // See: https://makerchip.com/sandbox/0yPfNhMDo/0r0hzR
   // =================================================
\SV
   // Macro providing required top-level module definition, random
   // stimulus support, and Verilator config.
   m5_makerchip_module   // (Expanded in Nav-TLV pane.)
\TLV
   |calc
      @0
         $reset = *reset;

         //Assign the two 32-bit inputs to random 4-bit values
         $val1[31:0] = $rand1[3:0];
         $val2[31:0] = $rand2[3:0];
   
         //Define operations
         $sum[31:0] = $val1[31:0] + $val2[31:0];
         $diff[31:0] = $val1[31:0] - $val2[31:0];
         $prod[31:0] = $val1[31:0] * $val2[31:0];
         $quot[31:0] = $val1[31:0] / $val2[31:0];

         //Define mux selector
         $op[2:0] = $rand[2:0];
         
         //Define muxed output
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

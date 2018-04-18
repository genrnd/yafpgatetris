
// Top module of yosys-tetris project

// It is actually a wrapper. Serves to differentiate RTL logic that can be
// synthesized by Yosys and platform primitives like PLL, that got synthesized
// in Quartus.

module top(

  input              CLOCK_50,
  input       [9:0]  SW,

  ///////// PS2 /////////
  inout              PS2_CLK,
  inout              PS2_DAT,

  ///////// VGA /////////
  output             VGA_CLK,     // 108 Mhz derived clock
  output      [7:0]  VGA_B,
  output             VGA_BLANK_N,
  output      [7:0]  VGA_G,
  output             VGA_HS,
  output      [7:0]  VGA_R,
  output             VGA_SYNC_N, // not used (?)
  output             VGA_VS

);

logic VGA_CLK;

pll pll(
  .refclk( CLOCK_50 ,
  .rst( 1'b0 ),
  .outclk_0(  ),
  .outclk_1( VGA_CLK )
);

rtl_top rtl_top1(
    .CLOCK_50( CLOCK_50 ),
    .SW( SW[9:0] ),

    .PS2_CLK( PS2_CLK ),
    .PS2_DAT( PS2_DAT ),

    .VGA_CLK( VGA_CLK ),
    .VGA_B( VGA_B[7:0] ),
    .VGA_BLANK_N( VGA_BLANK_N ),
    .VGA_G( VGA_G[7:0] ),
    .VGA_HS( VGA_HS ),
    .VGA_R( VGA_R[7:0] ),
    .VGA_SYNC_N( VGA_SYNC_N ),
    .VGA_VS( VGA_VS )
);

endmodule

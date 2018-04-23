
// Top module of yosys-tetris project

// It is actually a wrapper. Serves to differentiate RTL logic that can be
// synthesized by Yosys and platform primitives like PLL, that got synthesized
// in Quartus

module top(
    input CLOCK_25,
    input [9:0] SW,

    // ps2 interface
    inout PS2_CLK,
    inout PS2_DAT,

    // vga interface
    output [7:0]  VGA_R,
    output [7:0]  VGA_G,
    output [7:0]  VGA_B,
    output VGA_HS,
    output VGA_VS

);

logic CLOCK_50;
logic VGA_CLK;

pll pll(
    .refclk( CLOCK_25 ),
    .rst( 1'b0 ),
    .outclk_0( CLOCK_50 ),
    .outclk_0( VGA_CLK )
);

rtl_top rtl_top1(
    .CLOCK_50( CLOCK_50 ),
    .SW( SW[9:0] ),

    .PS2_CLK( PS2_CLK ),
    .PS2_DAT( PS2_DAT ),

    .VGA_CLK( VGA_CLK ),
    .VGA_R( VGA_R[7:0] ),
    .VGA_G( VGA_G[7:0] ),
    .VGA_B( VGA_B[7:0] ),
    .VGA_HS( VGA_HS ),
    .VGA_VS( VGA_VS )
);

endmodule

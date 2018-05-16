`include "../rtl/defs.vh"

module draw_tetris(

    input clk_vga,

    // game data
    input [`FIELD_ROW_CNT*`FIELD_COL_CNT*`TETRIS_COLORS_WIDTH-1:0] gd_field,
    input [6*4-1:0] gd_score,
    input [6*4-1:0] gd_lines,
    input [6*4-1:0] gd_level,
    input [4*4*4-1:0] gd_next_block_data,
    input [`TETRIS_COLORS_WIDTH-1:0] gd_next_block_color,
    input [1:0] gd_next_block_rotation,
    input signed [`FIELD_COL_CNT_WIDTH:0] gd_next_block_x,
    input signed [`FIELD_ROW_CNT_WIDTH:0] gd_next_block_y,
    input gd_next_block_draw_en,
    input gd_game_over_state,

    // VGA interface
    output logic vga_hs_o,
    output logic vga_vs_o,
    output logic vga_de_o,
    output logic [7:0] vga_r_o,
    output logic [7:0] vga_g_o,
    output logic [7:0] vga_b_o

);

localparam PIX_WIDTH = 12;

logic [23:0] strings_vga_data_w;
logic strings_vga_data_en_w;

logic [23:0] field_vga_data_w;
logic field_vga_data_en_w;

logic pix_hs;
logic pix_vs;
logic pix_de;
logic [PIX_WIDTH-1:0] pix_x;
logic [PIX_WIDTH-1:0] pix_y;

logic [23:0] vga_data;

/*draw_strings #(
   .PIX_WIDTH( PIX_WIDTH )
) draw_strings1 (

    .clk( clk_vga ),
    .pix_x_i( pix_x ),
    .pix_y_i( pix_y ),

    // game data (passing only apropriate fields of game data)
    .gd_score( gd_score ),
    .gd_lines( gd_lines ),
    .gd_level( gd_level ),
    .gd_game_over_state( gd_game_over_state ),

    .vga_data_o ( strings_vga_data_w ),
    .vga_data_en_o ( strings_vga_data_en_w )
);*/

draw_field #(
    .PIX_WIDTH( PIX_WIDTH )
) draw_field1 (

    .clk( clk_vga ),
    .pix_x_i( pix_x ),
    .pix_y_i( pix_y ),

    // game data (passing only apropriate fields of game data)
    .gd_field( gd_field ),
    .gd_next_block_data( gd_next_block_data ),
    .gd_next_block_color( gd_next_block_color ),
    .gd_next_block_rotation( gd_next_block_rotation ),
    .gd_next_block_draw_en( gd_next_block_draw_en ),

    .vga_data_o ( strings_vga_data_w ),
    .vga_data_en_o ( strings_vga_data_en_w )

);

always_comb begin
    vga_data = `COLOR_BACKGROUND;
    // strings got priority to draw "game over" over field
    if( strings_vga_data_en_w )
      vga_data = strings_vga_data_w;
    else
      if( field_vga_data_en_w )
        vga_data = field_vga_data_w;
end

// for 640x480
/*
localparam H_DISP	  = 640;
localparam H_FPORCH   = 16;
localparam H_SYNC	  = 96;
localparam H_BPORCH   = 48;
localparam V_DISP	  = 480;
localparam V_FPORCH   = 10;
localparam V_SYNC	  = 2;
localparam V_BPORCH   = 33;
*/

// for 1280x1024
localparam H_DISP	  = 1280;
localparam H_FPORCH   = 48;
localparam H_SYNC	  = 112;
localparam H_BPORCH   = 248;
localparam V_DISP	  = 1024;
localparam V_FPORCH   = 1;
localparam V_SYNC	  = 3;
localparam V_BPORCH   = 38;

vga_time_generator vga_time_gen1(
    .clk( clk_vga ),
    .reset_n( 1'b1 ), //FIXME(?)

    .h_disp( H_DISP ),
    .h_fporch( H_FPORCH ),
    .h_sync( H_SYNC ),
    .h_bporch( H_BPORCH ),

    .v_disp( V_DISP ),
    .v_fporch( V_FPORCH ),
    .v_sync( V_SYNC ),
    .v_bporch( V_BPORCH ),
    .hs_polarity( 1'b0 ),
    .vs_polarity( 1'b0 ),
    .frame_interlaced( 1'b0 ),

    .vga_hs( pix_hs ),
    .vga_vs( pix_vs ),
    .vga_de( pix_de ),
    .pixel_x( pix_x ),
    .pixel_y( pix_y ),
    .pixel_i_odd_frame( )
);

logic pix_hs_d1;
logic pix_vs_d1;
logic pix_de_d1;

always_ff @( posedge clk_vga ) begin
    { vga_r_o, vga_g_o, vga_b_o } <= vga_data;

    // delay because draw_strings/field got latency
    pix_hs_d1 <= pix_hs;
    pix_vs_d1 <= pix_vs;
    pix_de_d1 <= pix_de;

    vga_hs_o <= pix_hs_d1;
    vga_vs_o <= pix_vs_d1;
    vga_de_o <= pix_de_d1;
end

endmodule

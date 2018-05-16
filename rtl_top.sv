`include "./tetris/rtl/defs.vh"

module rtl_top(

    input CLOCK_50,
    input NRST,

    // PS2
    inout PS2_CLK,
    inout PS2_DAT,

    // VGA
    input VGA_CLK,         // 108 Mhz derived clock
    output [7:0] VGA_R,
    output [7:0] VGA_G,
    output [7:0] VGA_B,
    output VGA_HS,
    output VGA_VS
);

logic [7:0] ps2_received_data;
logic ps2_received_data_en;

PS2_Controller ps2(
    .CLOCK_50 ( CLOCK_50 ),
    .reset ( ~NRST ),
    .PS2_CLK ( PS2_CLK ),
    .PS2_DAT ( PS2_DAT ),
    .received_data ( ps2_received_data ),
    .received_data_en ( ps2_received_data_en )
);

logic user_event_rd_req;
logic [2:0] user_event;
logic user_event_ready;

user_input user_input1(
    .rst ( ~NRST ),
    .ps2_clk ( CLOCK_50 ),
    .ps2_key_data_i ( ps2_received_data ),
    .ps2_key_data_en_i ( ps2_received_data_en ),
    .main_logic_clk_i ( VGA_CLK ),
    .user_event_rd_req_i ( user_event_rd_req ),
    .user_event_o ( user_event[2:0] ),
    .user_event_ready_o ( user_event_ready )
);

// game data
logic [`FIELD_ROW_CNT*`FIELD_COL_CNT*`TETRIS_COLORS_WIDTH-1:0] gd_field;
logic [6*4-1:0] gd_score;     // 6 digits by 4 bits
logic [6*4-1:0] gd_lines;     // 6 digits by 4 bits
logic [6*4-1:0] gd_level;     // 6 digits by 4 bits
logic [4*4*4-1:0] gd_next_block_data;   // 4 rotation variants for 4*4 block
logic [`TETRIS_COLORS_WIDTH-1:0] gd_next_block_color;
logic [1:0] gd_next_block_rotation;
logic signed [`FIELD_COL_CNT_WIDTH:0] gd_next_block_x;
logic signed [`FIELD_ROW_CNT_WIDTH:0] gd_next_block_y;
logic gd_next_block_draw_en;
logic gd_game_over_state;


main_game_logic main_logic1(
    .clk ( VGA_CLK ),
    .rst ( ~NRST ),
    .user_event_i ( user_event[2:0] ),
    .user_event_ready_i ( user_event_ready ),
    .user_event_rd_req_o ( user_event_rd_req ),

    // game data input
    .gd_field( gd_field ),
    .gd_score( gd_score ),
    .gd_lines( gd_lines ),
    .gd_level( gd_level ),
    .gd_next_block_data( gd_next_block_data ),
    .gd_next_block_color( gd_next_block_color ),
    .gd_next_block_rotation( gd_next_block_rotation ),
    .gd_next_block_x( gd_next_block_x ),
    .gd_next_block_y( gd_next_block_y ),
    .gd_next_block_draw_en( gd_next_block_draw_en ),
    .gd_game_over_state( gd_game_over_state )
);


draw_tetris draw_tetris1(
    .clk_vga( VGA_CLK ),

    // game data output
    .gd_field( gd_field ),
    .gd_score( gd_score ),
    .gd_lines( gd_lines ),
    .gd_level( gd_level ),
    .gd_next_block_data( gd_next_block_data ),
    .gd_next_block_color( gd_next_block_color ),
    .gd_next_block_rotation( gd_next_block_rotation ),
    .gd_next_block_x( gd_next_block_x ),
    .gd_next_block_y( gd_next_block_y ),
    .gd_next_block_draw_en( gd_next_block_draw_en ),
    .gd_game_over_state( gd_game_over_state ),

      // VGA interface
    .vga_hs_o( VGA_HS ),
    .vga_vs_o( VGA_VS ),
    .vga_de_o(  ),
    .vga_r_o( VGA_R ),
    .vga_g_o( VGA_G ),
    .vga_b_o( VGA_B )
);

endmodule

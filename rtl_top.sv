`include "./tetris/rtl/defs.vh"

module rtl_top(

    input CLOCK_50,
    input [9:0] SW,

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

logic main_reset;
logic sw_0_d1;
logic sw_0_d2;
logic sw_0_d3;

always_ff @( posedge CLOCK_50 )
  begin
    sw_0_d1 <= SW[0];
    sw_0_d2 <= sw_0_d1;
    sw_0_d3 <= sw_0_d2;
  end

assign main_reset = sw_0_d3;

logic [7:0] ps2_received_data_w;
logic       ps2_received_data_en_w;

PS2_Controller ps2(
    .CLOCK_50 ( CLOCK_50 ),
    .reset ( main_reset),
    // Bidirectionals
    .PS2_CLK ( PS2_CLK ),
    .PS2_DAT ( PS2_DAT ),
    .received_data ( ps2_received_data_w ),
    .received_data_en ( ps2_received_data_en_w )
);

logic        user_event_rd_req_w;
logic [2:0]  user_event_w;
logic        user_event_ready_w;

user_input user_input(
    .rst_i ( main_reset ),
    .ps2_clk_i ( CLOCK_50 ),
    .ps2_key_data_i ( ps2_received_data_w ),
    .ps2_key_data_en_i ( ps2_received_data_en_w ),
    .main_logic_clk_i ( VGA_CLK ),
    .user_event_rd_req_i ( user_event_rd_req_w ),
    .user_event_o ( user_event_w[2:0] ),
    .user_event_ready_o ( user_event_ready_w )
);

// game data
logic gd_field [`FIELD_ROW_CNT-1:0][`FIELD_COL_CNT-1:0][`TETRIS_COLORS_WIDTH-1:0];
logic gd_score [5:0][3:0];
logic gd_lines [5:0][3:0];
logic gd_level [5:0][3:0];
logic gd_next_block_data [3:0][0:3][0:3];
logic [`TETRIS_COLORS_WIDTH-1:0] gd_next_block_color;
logic [1:0] gd_next_block_rotation;
logic signed [`FIELD_COL_CNT_WIDTH:0] gd_next_block_x;
logic signed [`FIELD_ROW_CNT_WIDTH:0] gd_next_block_y;
logic gd_next_block_draw_en;
logic gd_game_over_state;


main_game_logic main_logic(
    .clk_i ( VGA_CLK ),
    .rst_i ( main_reset ),
    .user_event_i ( user_event_w[2:0] ),
    .user_event_ready_i ( user_event_ready_w ),
    .user_event_rd_req_o ( user_event_rd_req_w ),

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


draw_tetris draw_tetris(
    .clk_vga_i( VGA_CLK ),

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

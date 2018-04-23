`include "../rtl/defs.vh"

module draw_strings #(
    parameter PIX_WIDTH = 12
)(
    input clk_i,
    input [PIX_WIDTH-1:0] pix_x_i,
    input [PIX_WIDTH-1:0] pix_y_i,

    // game data (passing only apropriate fields of game data)
    //input gd_field [`FIELD_ROW_CNT-1:0][`FIELD_COL_CNT-1:0][`TETRIS_COLORS_WIDTH-1:0],
    input gd_score [5:0][3:0],
    input gd_lines [5:0][3:0],
    input gd_level [5:0][3:0],
    //input gd_next_block_data [3:0][0:3][0:3],
    //input [`TETRIS_COLORS_WIDTH-1:0] gd_next_block_color,
    //input [1:0] gd_next_block_rotation,
    //input signed [`FIELD_COL_CNT_WIDTH:0] gd_next_block_x,
    //input signed [`FIELD_ROW_CNT_WIDTH:0] gd_next_block_y,
    //input gd_next_block_draw_en,
    input gd_game_over_state,

    output [23:0] vga_data_o,
    output vga_data_en_o
);

localparam NUMBER_LEN    = 6;

localparam FONT_SYMBOL_X = 16;        // pixel size for one symbol
localparam FONT_SYMBOL_Y = 32;

localparam SYMBOL_WIDTH      = 7;     // bits per symbol
localparam STRING_LEN        = 16;
localparam STRING_CNT        = 4;
localparam NUMBER_STRING_CNT = 3;

localparam [PIX_WIDTH-1:0] START_STATUS_X = 670;
localparam [PIX_WIDTH-1:0] START_STATUS_Y = 430;
localparam [PIX_WIDTH-1:0] END_STATUS_X = START_STATUS_X + FONT_SYMBOL_X * STRING_LEN - 1;
localparam [PIX_WIDTH-1:0] END_STATUS_Y = START_STATUS_Y + FONT_SYMBOL_Y * STRING_CNT - 1;


logic strings[STRING_CNT-1:0][STRING_LEN-1:0][SYMBOL_WIDTH-1:0];
logic string_score [0:5][SYMBOL_WIDTH-1:0];
logic string_lines [0:5][SYMBOL_WIDTH-1:0];
logic string_level [0:5][SYMBOL_WIDTH-1:0];
logic string_new_game [0:11][SYMBOL_WIDTH-1:0];

logic number_strings [NUMBER_STRING_CNT-1:0][NUMBER_LEN-1:0][SYMBOL_WIDTH-1:0];

//"Score:"
assign string_score = { 7'h53, 7'h63, 7'h6f, 7'h72, 7'h65, 7'h3a };

//"Lines:"
assign string_lines = { 7'h4c, 7'h69, 7'h6e, 7'h65, 7'h73, 7'h3a };

//"Level:"
assign string_level = { 7'h4c, 7'h65, 7'h76, 7'h65, 7'h6c, 7'h3a };

//"New Game (N)"
assign string_new_game = { 7'h4e, 7'h65, 7'h77, 7'h20,
                           7'h47, 7'h61, 7'h6d, 7'h65, 7'h20,
                           7'h28, 7'h4e, 7'h29 };

always_comb
  begin
    for( int s = 0; s < STRING_CNT; s++ )
      begin
        for( int i = 0; i < STRING_LEN; i++ )
          begin
            strings[s][i] = 7'h20; // "stuffing" by spaces
          end
      end

    for( int i = 0; i < 6; i++ )
      begin
        strings[0][i] = string_score[i];
        strings[1][i] = string_lines[i];
        strings[2][i] = string_level[i];
      end

    for( int s = 0; s < NUMBER_STRING_CNT; s++ )
      begin
        for( int i = 0; i < NUMBER_LEN; i++ )
          begin
            strings[s][ 6 + i ] = number_strings[s][NUMBER_LEN-1-i];
          end
      end

    for( int i = 0; i < ( $bits( string_new_game ) / SYMBOL_WIDTH ); i++ )
      begin
        strings[3][i] = string_new_game[i];
      end
  end

// TODO: 00005 -> 5
always_comb
  begin
    for( int i = 0; i < NUMBER_LEN; i++ )
      begin // adding '0' to get ascii code
        number_strings[0][i] = gd_score[i] + 7'h30;
        number_strings[1][i] = gd_lines[i] + 7'h30;
        number_strings[2][i] = gd_level[i] + 7'h30;
      end
  end

logic [$clog2(STRING_LEN)-1:0] cur_symbol_pos_x;
logic [$clog2(STRING_CNT)-1:0] cur_symbol_pos_y;

logic [SYMBOL_WIDTH-1:0] cur_symbol;

assign cur_symbol = strings[ cur_symbol_pos_y ][ cur_symbol_pos_x ];

// current pixel value calculated as a shift relative to output origin
logic [PIX_WIDTH-1:0] in_string_x;
logic [PIX_WIDTH-1:0] in_string_y;

assign in_string_x = pix_x_i - START_STATUS_X;
assign in_string_y = pix_y_i - START_STATUS_Y;

// calculating what string(y) and what symbol(x) to show
// all values are orders of 2, so we simply shift FONT_SYMBOL_*
assign cur_symbol_pos_x = in_string_x >> $clog2(FONT_SYMBOL_X);
assign cur_symbol_pos_y = in_string_y >> $clog2(FONT_SYMBOL_Y);

logic in_status_strings;

always_ff @( posedge clk_i )
  in_status_strings <= ( pix_x_i >= START_STATUS_X ) && ( pix_x_i <= END_STATUS_X ) &&
                       ( pix_y_i >= START_STATUS_Y ) && ( pix_y_i <= END_STATUS_Y );

//TODO:
localparam FONT_ROM_ADDR_WIDTH = 8 + $clog2(FONT_SYMBOL_Y);
localparam FONT_ROM_DATA_WIDTH = FONT_SYMBOL_X;

logic [FONT_ROM_ADDR_WIDTH-1:0] rom_rd_addr;
logic [FONT_ROM_DATA_WIDTH-1:0] rom_rd_data;
logic [FONT_ROM_DATA_WIDTH-1:0] rom_rd_data_rev;

logic [$clog2(FONT_SYMBOL_X)-1:0] in_symbol_x;

always_ff @( posedge clk_i )
  in_symbol_x <= in_string_x[ $clog2(FONT_SYMBOL_X)-1:0 ];

assign rom_rd_addr = { cur_symbol, in_string_y[$clog2(FONT_SYMBOL_Y)-1:0] };

string_rom #(
     .A_WIDTH( FONT_ROM_ADDR_WIDTH ),
     .D_WIDTH( FONT_ROM_DATA_WIDTH ),
     .INIT_FILE( "font.mif" )
) font_rom(

    .clock( clk_i ),
    .address( rom_rd_addr ),
    .q( rom_rd_data )
);

// mirroring data because drawing order is left-to-right, but opposite in memory
always_comb
  begin
    for( int i = 0; i < FONT_ROM_DATA_WIDTH; i++ )
      begin
        rom_rd_data_rev[i] = rom_rd_data[FONT_ROM_DATA_WIDTH-1-i];
      end
  end


logic head_draw_pix;
logic head_draw_pix_en;

logic game_over_draw_pix;
logic game_over_draw_pix_en;

draw_big_string #(
    .PIX_WIDTH( PIX_WIDTH ),

    .START_X( 250 ),
    .START_Y( 90 ),

    .MSG_X( 651 ),
    .MSG_Y( 90 ),

    .INIT_FILE( "head.mif" )
) draw_head(

    .clk_i( clk_i ),

    .pix_x_i( pix_x_i ),
    .pix_y_i( pix_y_i ),

    .draw_pix_o( head_draw_pix ),
    .draw_pix_en_o( head_draw_pix_en )

);

localparam GAME_OVER_BLINK_TICKS = 'd30_000_000;

logic [31:0] game_over_cnt = 'd0;
logic game_over_blink_en = 1'b0;

always_ff @( posedge clk_i )
  if( game_over_cnt == GAME_OVER_BLINK_TICKS )
    begin
      game_over_cnt <= 'd0;
      game_over_blink_en <= ~game_over_blink_en;
    end
  else
    begin
      game_over_cnt <= game_over_cnt + 1'd1;
    end

draw_big_string #(
    .PIX_WIDTH( PIX_WIDTH ),

    .START_X( 330 ),
    .START_Y( 475 ),

    .MSG_X( 259 ),
    .MSG_Y( 39 ),

    .INIT_FILE( "game_over.mif" )
) draw_game_over(
    .clk_i( clk_i ),

    .pix_x_i( pix_x_i ),
    .pix_y_i( pix_y_i ),

    .draw_pix_o( game_over_draw_pix ),
    .draw_pix_en_o( game_over_draw_pix_en )
);

localparam DRAW_STATUS    = 0;
localparam DRAW_HEAD      = 1;
localparam DRAW_GAME_OVER = 2;
localparam DRAW_TYPES_CNT = 3;

logic [DRAW_TYPES_CNT-1:0] draw_en;

assign draw_en[ DRAW_STATUS    ] = in_status_strings && rom_rd_data_rev[ in_symbol_x ];
assign draw_en[ DRAW_HEAD      ] = head_draw_pix && head_draw_pix_en;
assign draw_en[ DRAW_GAME_OVER ] = game_over_draw_pix && game_over_draw_pix_en &&
                                   game_over_blink_en && gd_game_over_state;

always_comb
  begin
    vga_data_o = `COLOR_BACKGROUND;

    if( draw_en[ DRAW_STATUS ] )
      vga_data_o = `COLOR_TEXT;

    if( draw_en[ DRAW_HEAD ] )
      vga_data_o = `COLOR_HEAD;

    if( draw_en[ DRAW_GAME_OVER ] )
      vga_data_o = `COLOR_GAME_OVER;
  end

assign vga_data_en_o = |draw_en;

endmodule

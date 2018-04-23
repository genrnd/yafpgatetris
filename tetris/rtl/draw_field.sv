`include "../rtl/defs.vh"

module draw_field #(
    parameter PIX_WIDTH = 12
)(
    input clk_i,
    input [PIX_WIDTH-1:0] pix_x_i,
    input [PIX_WIDTH-1:0] pix_y_i,

    // game data (passing only apropriate fields of game data)
    input gd_field [`FIELD_ROW_CNT-1:0][`FIELD_COL_CNT-1:0][`TETRIS_COLORS_WIDTH-1:0],
    //input gd_score [5:0][3:0],
    //input gd_lines [5:0][3:0],
    //input gd_level [5:0][3:0],
    input gd_next_block_data [3:0][0:3][0:3],
    input [`TETRIS_COLORS_WIDTH-1:0] gd_next_block_color,
    input [1:0] gd_next_block_rotation,
    //input signed [`FIELD_COL_CNT_WIDTH:0] gd_next_block_x,
    //input signed [`FIELD_ROW_CNT_WIDTH:0] gd_next_block_y,
    input gd_next_block_draw_en,
    //input gd_game_over_state,

    output [23:0] vga_data_o,
    output        vga_data_en_o
);

// brick size in real onscreen pixels
localparam BRICK_X = 30;
localparam BRICK_Y = 30;

// borders size in real onscreen pixels
localparam BORDER_X = 2;
localparam BORDER_Y = 2;

// main field start in real onscreen pixels
localparam START_MAIN_FIELD_X = 300;
localparam START_MAIN_FIELD_Y = 200;

logic [$clog2(`FIELD_COL_CNT)-1:0] main_field_col_num;
logic [$clog2(`FIELD_ROW_CNT)-1:0] main_field_row_num;
logic main_field_in_field;
logic main_field_in_brick;
logic [PIX_WIDTH-1:0] main_field_end_x;
logic [PIX_WIDTH-1:0] main_field_end_y;


draw_field_helper #(
  .PIX_WIDTH( PIX_WIDTH ),

  .BRICK_X( BRICK_X ),
  .BRICK_Y( BRICK_Y ),

  .BRICK_X_CNT( `FIELD_COL_CNT),
  .BRICK_Y_CNT( `FIELD_ROW_CNT),

  .BORDER_X( BORDER_X ),
  .BORDER_Y( BORDER_Y )
) main_field (
  .clk_i( clk_i ),

  .start_x_i( START_MAIN_FIELD_X ),
  .start_y_i( START_MAIN_FIELD_Y ),

  .end_x_o( main_field_end_x  ),
  .end_y_o( main_field_end_y  ),

  // current pix value
  .pix_x_i( pix_x_i ),
  .pix_y_i( pix_y_i ),

  .in_field_o( main_field_in_field ),
  .in_brick_o( main_field_in_brick ),

  .brick_col_num_o( main_field_col_num ),
  .brick_row_num_o( main_field_row_num )

);

// ******* Next Block Preview (nbp) *******
localparam NBP_BRICK_CNT = 6;

logic [PIX_WIDTH-1:0] nbp_field_start_x;
logic [PIX_WIDTH-1:0] nbp_field_start_y;

assign nbp_field_start_x = 'd670;
assign nbp_field_start_y = START_MAIN_FIELD_Y;

logic [$clog2(NBP_BRICK_CNT)-1:0] nbp_field_col_num;
logic [$clog2(NBP_BRICK_CNT)-1:0] nbp_field_row_num;
logic nbp_field_in_field;
logic nbp_field_in_brick;

draw_field_helper
#(
    .PIX_WIDTH( PIX_WIDTH ),

    .BRICK_X( BRICK_X ),
    .BRICK_Y( BRICK_Y ),

    .BRICK_X_CNT( NBP_BRICK_CNT ),
    .BRICK_Y_CNT( NBP_BRICK_CNT ),

    .BORDER_X( BORDER_X ),
    .BORDER_Y( BORDER_Y )
) draw_nbp_field (
    .clk_i( clk_i ),

    .start_x_i( nbp_field_start_x ),
    .start_y_i( nbp_field_start_y ),

    .end_x_o( ),
    .end_y_o( ),

    // current pix value
    .pix_x_i( pix_x_i ),
    .pix_y_i( pix_y_i ),

    .in_field_o( nbp_field_in_field ),
    .in_brick_o( nbp_field_in_brick ),

    .brick_col_num_o( nbp_field_col_num ),
    .brick_row_num_o( nbp_field_row_num )

);

logic nbp_field [NBP_BRICK_CNT-1:0][NBP_BRICK_CNT-1:0][`TETRIS_COLORS_CNT-1:0];
logic nbp_block_data [0:3][0:3];

assign nbp_block_data = gd_next_block_data[ gd_next_block_rotation ];

always_comb
  begin
    for( int i = 0; i < NBP_BRICK_CNT; i++ )
      begin
        for( int j = 0; j < NBP_BRICK_CNT; j++ )
          begin
            if( ( i == 0 ) || ( j == 0 ) ||
                ( i == ( NBP_BRICK_CNT - 1 ) ) || ( j == ( NBP_BRICK_CNT - 1 ) ) )
              begin
                nbp_field[i][j] = 'd0;
              end
            else
              begin
                if( nbp_block_data[i-1][j-1] && gd_next_block_draw_en )
                  nbp_field[i][j] = gd_next_block_color;
                else
                  nbp_field[i][j] = 'd0;
              end
          end
      end
  end

logic [23:0] vga_data;

logic vga_colors_pos [`TETRIS_COLORS_CNT-1:0][23:0];

assign vga_colors_pos[0] = `COLOR_BRICKS_0;
assign vga_colors_pos[1] = `COLOR_BRICKS_1;
assign vga_colors_pos[2] = `COLOR_BRICKS_2;
assign vga_colors_pos[3] = `COLOR_BRICKS_3;
assign vga_colors_pos[4] = `COLOR_BRICKS_4;
assign vga_colors_pos[5] = `COLOR_BRICKS_5;
assign vga_colors_pos[6] = `COLOR_BRICKS_6;
assign vga_colors_pos[7] = `COLOR_BRICKS_7;

always_comb
  begin
    vga_data = `COLOR_BORDERS;

    if( main_field_in_field )
      begin
        if( main_field_in_brick )
          begin
            vga_data = vga_colors_pos[ gd_field[ main_field_row_num ][ main_field_col_num ] ];
          end
      end
    else
      if( nbp_field_in_field )
        begin
          if( nbp_field_in_brick )
            begin
              vga_data = vga_colors_pos[ nbp_field[ nbp_field_row_num ][ nbp_field_col_num ] ];
            end
        end
  end

assign vga_data_o = vga_data;
assign vga_data_en_o = main_field_in_field || nbp_field_in_field;

endmodule

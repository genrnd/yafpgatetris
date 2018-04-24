`include "../rtl/defs.vh"

module check_move(
    input clk,
    input run,
    input [2:0] req_move,

    // block info
    input [4*4*4-1:0] b_data,
    input [`TETRIS_COLORS_WIDTH-1:0] b_color,
    input [1:0] b_rotation,
    input signed [`FIELD_COL_CNT_WIDTH:0] b_x,
    input signed [`FIELD_ROW_CNT_WIDTH:0] b_y,

    input [`FIELD_EXT_ROW_CNT*`FIELD_EXT_COL_CNT-1:0] field,

    output done_o,
    output can_move_o,
    output signed [1:0] move_x_o,
    output signed [1:0] move_y_o
);

logic signed [2:0] cur_block_i;
logic signed [2:0] cur_block_j;
logic check_en;

logic last_brick;

assign last_brick = ( cur_block_i == 'd3 ) && ( cur_block_j == 'd3 );

always_ff @( posedge clk )
  if( run )
    check_en <= 1'b1;
  else
    if( last_brick )
      check_en <= 1'b0;

always_ff @( posedge clk )
  if( run )
    begin
      cur_block_i <= 0;
      cur_block_j <= 0;
    end
  else
    if( check_en )
      begin
        if( cur_block_j == 'd3 )
          begin
            cur_block_i <= cur_block_i + 1'd1;
            cur_block_j <= 'd0;
          end
        else
          begin
            cur_block_j <= cur_block_j + 1'd1;
          end
      end

always_ff @( posedge clk )
  if( run )
    begin
      done_o <= 1'b0;
    end
  else
    if( done_o )
      done_o <= 1'b0;
    else
      begin
        if( check_en )
          begin
            if( last_brick )
              done_o <= 1'b1;
          end
      end

logic signed [`FIELD_COL_CNT_WIDTH:0] check_field_col;
logic signed [`FIELD_ROW_CNT_WIDTH:0] check_field_row;

logic signed [1:0] x_move;
logic signed [1:0] y_move;

assign check_field_col = b_x + cur_block_j + x_move;
assign check_field_row = b_y + cur_block_i + y_move;

assign move_x_o = x_move;
assign move_y_o = y_move;

always_ff @( posedge clk )
  if( run )
    begin
      case( req_move[2:0] )
        `MOVE_LEFT:
          begin
            x_move <= -1;
            y_move <= 0;
          end
        `MOVE_RIGHT:
          begin
            x_move <= 1;
            y_move <= 0;
          end
        `MOVE_DOWN:
          begin
            x_move <= 0;
            y_move <= 1;
          end
        `MOVE_ROTATE:
          begin
            x_move <= 0;
            y_move <= 0;
          end
        `MOVE_APPEAR:
          begin
            x_move <= 0;
            y_move <= 0;
          end
        default:
          begin
            x_move <= 0;
            y_move <= 0;
          end
      endcase
    end

logic [4*4-1:0] check_data;
always_ff @( posedge clk )
  begin
    if( run )
      check_data <= ( req_move == MOVE_ROTATE ) ?
            b_data[ (4*4*(b_rotation+1)+4*4-1):(4*4*(b_rotation+1)+0) ]:
            b_data[ (4*4*(b_rotation)+4*4-1):(4*4*(b_rotation)+0) ];
  end

always_ff @( posedge clk )
  if( run )
      can_move_o <= 1'b1;
  else
    if( check_en ) begin
      if( check_data[ 4*(cur_block_i)+cur_block_j ] ) begin
          if ( ( check_field_row < 0 ) ||
               ( check_field_col < 0 ) ||
               ( field[`FIELD_EXT_COL_CNT*check_field_row+check_field_col] ) )
                  can_move_o <= 1'b0;
      end
    end

endmodule

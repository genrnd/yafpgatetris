
module draw_field_helper
#(
  parameter PIX_WIDTH = 12,
  parameter BRICK_X   = 20,
  parameter BRICK_Y   = 25,
  parameter BRICK_X_CNT = 10,
  parameter BRICK_Y_CNT = 20,
  parameter BORDER_X    = 2,
  parameter BORDER_Y    = 2
)(
  input clk,
  input [PIX_WIDTH-1:0] start_x_i,
  input [PIX_WIDTH-1:0] start_y_i,
  output [PIX_WIDTH-1:0] end_x_o,
  output [PIX_WIDTH-1:0] end_y_o,
  // current pix value
  input [PIX_WIDTH-1:0] pix_x_i,
  input [PIX_WIDTH-1:0] pix_y_i,
  output in_field_o,
  output in_brick_o,
  output [$clog2(BRICK_X_CNT)-1:0] brick_col_num_o,
  output [$clog2(BRICK_Y_CNT)-1:0] brick_row_num_o

);

assign end_x_o = start_x_i + BORDER_X * ( BRICK_X_CNT + 1 ) + BRICK_X * BRICK_X_CNT - 1;
assign end_y_o = start_y_i + BORDER_Y * ( BRICK_Y_CNT + 1 ) + BRICK_Y * BRICK_Y_CNT - 1;

logic [PIX_WIDTH-1:0] col_pix_start [BRICK_X_CNT-1:0];
logic [PIX_WIDTH-1:0] col_pix_end [BRICK_X_CNT-1:0];
logic [PIX_WIDTH-1:0] row_pix_start [BRICK_Y_CNT-1:0];
logic [PIX_WIDTH-1:0] row_pix_end [BRICK_Y_CNT-1:0];

integer i;

always_comb begin
  for( i = 0; i < BRICK_X_CNT; i = i + 1 ) begin
    col_pix_start[i] = ( i + 1 ) * BORDER_X + i * BRICK_X;
    col_pix_end[i] = col_pix_start[i] + BRICK_X - 1'd1;
  end
end

always_comb begin
  for( i = 0 ; i < BRICK_Y_CNT; i = i + 1 ) begin
    row_pix_start[i] = ( i + 1 ) * BORDER_Y + i * BRICK_Y;
    row_pix_end[i] = row_pix_start[i] + BRICK_Y - 1'd1;
  end
end

// current values
logic [$clog2( BRICK_X_CNT )-1:0] brick_col_num;
logic [$clog2( BRICK_Y_CNT )-1:0] brick_row_num;

logic in_brick_col;
logic in_brick_row;

// shifted values
logic [PIX_WIDTH-1:0] in_field_pix_x;
logic [PIX_WIDTH-1:0] in_field_pix_y;
assign in_field_pix_x = pix_x_i - start_x_i;
assign in_field_pix_y = pix_y_i - start_y_i;

// processing current block for presenting it
// not an optimal implementation though
always_comb begin
  brick_col_num = 0;
  in_brick_col  = 1'b0;
  for( i = 0; i < BRICK_X_CNT; i = i + 1 ) begin
    if( ( in_field_pix_x >= col_pix_start[i] ) &&
        ( in_field_pix_x <= col_pix_end[i] ) ) begin
            brick_col_num = i;
            in_brick_col  = 1'b1;
    end
  end
end

always_comb begin
  brick_row_num = 0;
  in_brick_row  = 1'b0;
  for( i = 0; i < BRICK_Y_CNT; i = i + 1 ) begin
    if( ( in_field_pix_y >= row_pix_start[i] ) &&
        ( in_field_pix_y <= row_pix_end[i] ) ) begin
            brick_row_num = i;
            in_brick_row  = 1'b1;
    end
  end
end

always_ff @( posedge clk ) begin
    in_field_o  <= ( pix_x_i >= start_x_i ) && ( pix_x_i <= end_x_o ) &&
                  ( pix_y_i >= start_y_i ) && ( pix_y_i <= end_y_o );
    in_brick_o  <=  in_brick_col && in_brick_row;
    brick_col_num_o <= brick_col_num;
    brick_row_num_o <= brick_row_num;
end

endmodule

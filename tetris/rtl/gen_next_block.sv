`include "../rtl/defs.vh"

module gen_next_block(
    input clk,
    input en,

    // block info
    output [4*4*4-1:0] b_data,
    output [`TETRIS_COLORS_WIDTH-1:0] b_color,
    output [1:0] b_rotation,
    output signed [`FIELD_COL_CNT_WIDTH:0] b_x,
    output signed [`FIELD_ROW_CNT_WIDTH:0] b_y
);

localparam BLOCKS_CNT = 7;
logic [BLOCKS_CNT*4*4*4-1:0] blocks_table =

{ {4'b0000,
   4'b1111,
   4'b0000,
   4'b0000,

   4'b0100,
   4'b0100,
   4'b0100,
   4'b0100,

   4'b0000,
   4'b1111,
   4'b0000,
   4'b0000,

   4'b0100,
   4'b0100,
   4'b0100,
   4'b0100 },

  {4'b0000,
   4'b1110,
   4'b0010,
   4'b0000,

   4'b0110,
   4'b0100,
   4'b0100,
   4'b0000,

   4'b1000,
   4'b1110,
   4'b0000,
   4'b0000,

   4'b0100,
   4'b0100,
   4'b1100,
   4'b0000 },

  {4'b0000,
   4'b1110,
   4'b1000,
   4'b0000,

   4'b0100,
   4'b0100,
   4'b0110,
   4'b0000,

   4'b0010,
   4'b1110,
   4'b0000,
   4'b0000,

   4'b1100,
   4'b0100,
   4'b0100,
   4'b0000 },

  {4'b0000,
   4'b0110,
   4'b0110,
   4'b0000,

   4'b0000,
   4'b0110,
   4'b0110,
   4'b0000,

   4'b0000,
   4'b0110,
   4'b0110,
   4'b0000,

   4'b0000,
   4'b0110,
   4'b0110,
   4'b0000 },

  {4'b0000,
   4'b0110,
   4'b1100,
   4'b0000,

   4'b0100,
   4'b0110,
   4'b0010,
   4'b0000,

   4'b0110,
   4'b1100,
   4'b0000,
   4'b0000,

   4'b1000,
   4'b1100,
   4'b0100,
   4'b0000 },

  {4'b0000,
   4'b1110,
   4'b0100,
   4'b0000,

   4'b0100,
   4'b0110,
   4'b0100,
   4'b0000,

   4'b0100,
   4'b1110,
   4'b0000,
   4'b0000,

   4'b0100,
   4'b1100,
   4'b0100,
   4'b0000 },

  {4'b0000,
   4'b1100,
   4'b0110,
   4'b0000,

   4'b0010,
   4'b0110,
   4'b0100,
   4'b0000,

   4'b1100,
   4'b0110,
   4'b0000,
   4'b0000,

   4'b0100,
   4'b1100,
   4'b1000,
   4'b0000 } };

logic [14:0] prbs_15 = 'd1;
logic [$clog2(BLOCKS_CNT)-1:0] random_block_num = 'd0;
logic [1:0] random_rotation  = 'd0;

always_ff @( posedge clk )
  if( en )
    prbs_15 <= { prbs_15[13:0], prbs_15[14] ^ prbs_15[13] };

always_ff @( posedge clk ) begin
  random_block_num <= prbs_15[7:0] % BLOCKS_CNT;
  random_rotation  <= prbs_15[9:8]; // why not(?)
end

always_ff @( posedge clk ) begin
  b_data <= blocks_table[ random_block_num ];

  // zero color for background, so adding one
  b_color <= random_block_num + 1'd1;
  b_rotation <= random_rotation;
  b_x <= 'd4;
  b_y <= 'd0;
end

endmodule

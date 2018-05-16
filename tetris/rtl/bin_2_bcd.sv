
module bin_2_bcd #(
  parameter BIN_WIDTH = 8,
  parameter BCD_WIDTH = 3
)(
  input [BIN_WIDTH-1:0] bin_i,
  output [BCD_WIDTH*4-1:0] bcd_o
);

integer b;
integer bcd;

always_comb begin
  bcd_o = 0;
  for( b = BIN_WIDTH - 1; b >= 0; b = b - 1 ) begin
      for( bcd = 0; bcd < BCD_WIDTH; bcd = bcd + 1 ) begin
          if( bcd_o[ (bcd*4+0) +: 4 ] >= 4'd5 )
              bcd_o[ (bcd*4+0) +: 4 ] = bcd_o[ (bcd*4+0) +: 4 ] + 4'd3;
      end
      for( bcd = BCD_WIDTH - 1; bcd >= 0; bcd = bcd - 1 ) begin
          bcd_o[ (bcd*4+0) +: 4 ] = bcd_o[ (bcd*4+0) +: 4 ] << 1;
          if( bcd == 0 )
            bcd_o[ (bcd*4+0) ] = bin_i[ b ];
          else
            bcd_o[ (bcd*4+0) ] = bcd_o[ (bcd-1)*4+3 ];
      end
  end
end

endmodule

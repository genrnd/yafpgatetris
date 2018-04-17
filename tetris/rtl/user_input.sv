`include "defs.vh"

module user_input(
  input               rst_i,

  input               ps2_clk_i,

  input         [7:0] ps2_key_data_i,
  input               ps2_key_data_en_i,

  input               main_logic_clk_i,

  input               user_event_rd_req_i,
  output        [2:0] user_event_o,
  output              user_event_ready_o

);

logic [1:0][7:0] ps2_key_data_sr;
logic            ps2_key_data_en_d1;

always_ff @( posedge ps2_clk_i or posedge rst_i )
  if( rst_i )
    begin
      ps2_key_data_sr <= '0;
    end
  else
    if( ps2_key_data_en_i )
      begin
        ps2_key_data_sr <= { ps2_key_data_sr[0], ps2_key_data_i };
      end

always_ff @( posedge ps2_clk_i or posedge rst_i )
  if( rst_i )
    ps2_key_data_en_d1 <= '0;
  else
    ps2_key_data_en_d1 <= ps2_key_data_en_i;

logic [2:0]  wr_event;
logic        wr_event_val;
logic        break_event;

assign break_event = ( ps2_key_data_sr[1] == 8'hF0 );

always_comb
  begin
    wr_event_val = 1'b1;

    casex( ps2_key_data_sr )
      { 8'hxx, `SCAN_CODE_N }:
        begin
          wr_event[2:0] = EV_NEW_GAME;
          wr_event_val = !break_event;
        end
      `SCAN_CODE_ARROW_UP:
        begin
          wr_event[2:0] = EV_ROTATE;
        end
      `SCAN_CODE_ARROW_LEFT:
        begin
          wr_event[2:0] = EV_LEFT;
        end
      `SCAN_CODE_ARROW_RIGHT:
        begin
          wr_event[2:0] = EV_RIGHT;
        end
      `SCAN_CODE_ARROW_DOWN:
        begin
          wr_event[2:0] = EV_DOWN;
        end
      default:
        begin
          // the logic is not required indeed
          wr_event[2:0] = EV_DOWN;
          wr_event_val = 1'b0;
        end
    endcase
  end

logic fifo_wr_req;
logic fifo_empty;
logic fifo_full;

assign fifo_wr_req = wr_event_val && ps2_key_data_en_d1 && ( !fifo_full );

user_input_fifo
#(
  .DWIDTH                                 ( 3 )                 ) // width of event vector
) user_input_fifo (
  .aclr                                   ( rst_i               ),

  .wrclk                                  ( ps2_clk_i           ),
  .wrreq                                  ( fifo_wr_req         ),
  .data                                   ( wr_event[2:0]       ),

  .rdclk                                  ( main_logic_clk_i    ),
  .rdreq                                  ( user_event_rd_req_i ),
  .q                                      ( user_event_o[2:0]   ),

  .rdempty                                ( fifo_empty          ),
  .wrfull                                 ( fifo_full           )
);

assign user_event_ready_o = !fifo_empty;

endmodule

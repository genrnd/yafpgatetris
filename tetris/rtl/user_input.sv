`include "defs.vh"

module user_input(
  input rst,
  input ps2_clk,
  input [7:0] ps2_key_data_i,
  input ps2_key_data_en_i,
  input main_logic_clk_i,
  input user_event_rd_req_i,
  output [2:0] user_event_o,
  output user_event_ready_o
);

logic [2*8-1:0] ps2_key_data_sr;
logic ps2_key_data_en_d1;

always_ff @( posedge ps2_clk or posedge rst ) begin
  if ( rst )
      ps2_key_data_sr <= 0;
  else
    if( ps2_key_data_en_i )
        ps2_key_data_sr[15:0] <= { ps2_key_data_sr[7:0], ps2_key_data_i };
end

always_ff @( posedge ps2_clk or posedge rst ) begin
  if( rst )
    ps2_key_data_en_d1 <= 0;
  else
    ps2_key_data_en_d1 <= ps2_key_data_en_i;
end

logic [2:0] wr_event;
logic wr_event_val;
logic break_event;

assign break_event = ( ps2_key_data_sr[15:8] == 8'hF0 );

always_comb
  begin
    wr_event_val = 1'b1;

    casex( ps2_key_data_sr[15:0] )
      { 8'hxx, `SCAN_CODE_N }:
        begin
          wr_event[2:0] = `EV_NEW_GAME;
          wr_event_val = !break_event;
        end
      `SCAN_CODE_ARROW_UP:
        begin
          wr_event[2:0] = `EV_ROTATE;
        end
      `SCAN_CODE_ARROW_LEFT:
        begin
          wr_event[2:0] = `EV_LEFT;
        end
      `SCAN_CODE_ARROW_RIGHT:
        begin
          wr_event[2:0] = `EV_RIGHT;
        end
      `SCAN_CODE_ARROW_DOWN:
        begin
          wr_event[2:0] = `EV_DOWN;
        end
      default:
        begin
          // the logic is not required indeed
          wr_event[2:0] = `EV_DOWN;
          wr_event_val = 1'b0;
        end
    endcase
  end


logic [2:0] event_buf = 0;
logic event_buf_empty = 1'b1;
logic [2:0] event_buf_main_logic_clk_d1 = 0;
logic event_buf_empty_main_logic_clk_d1 = 1'b1;
logic [2:0] event_buf_main_logic_clk_d2 = 0;
logic event_buf_empty_main_logic_clk_d2 = 1'b1;

logic event_done = 1'b1;
logic event_done_ps2_clk_d1 = 1'b1;
logic event_done_ps2_clk_d2 = 1'b1;

// synchronizing user events between clock domains
always_ff @(posedge ps2_clk) begin
  if( wr_event_val && ps2_key_data_en_d1 && event_buf_empty ) begin
    event_buf[2:0] <= wr_event[2:0];
    event_buf_empty <= 1'b0;
  end else begin
    if ( event_done_ps2_clk_d2 && !event_done_ps2_clk_d1 ) begin
      event_buf_empty <= 1'b1;
    end
  end
end

always_ff @(posedge main_logic_clk_i) begin
  event_buf_main_logic_clk_d1[2:0] <= event_buf[2:0];
  event_buf_empty_main_logic_clk_d1 <= event_buf_empty;
  event_buf_main_logic_clk_d2[2:0] <= event_buf_main_logic_clk_d1[2:0];
  event_buf_empty_main_logic_clk_d2 <= event_buf_empty_main_logic_clk_d1;
end

always_ff @(posedge main_logic_clk_i) begin
  if ( user_event_rd_req_i) begin
    if ( !event_buf_empty_main_logic_clk_d2 ) begin
      user_event_ready_o <= 1'b1;
      user_event_o[2:0] <= event_buf_main_logic_clk_d2[2:0];
      event_done <= 1'b1;
    end else begin
      user_event_ready_o <= 1'b0;
      event_done <= 1'b0;
    end
  end
end

always_ff @(posedge ps2_clk) begin
  event_done_ps2_clk_d1 <= event_done;
  event_done_ps2_clk_d2 <= event_done_ps2_clk_d1;
end


endmodule

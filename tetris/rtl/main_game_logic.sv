`include "../rtl/defs.vh"

module main_game_logic (
    input clk,
    input rst,
    input [2:0] user_event_i,
    input user_event_ready_i,
    output user_event_rd_req_o,

    // game data
    output [`FIELD_ROW_CNT*`FIELD_COL_CNT*`TETRIS_COLORS_WIDTH-1:0] gd_field,
    output [6*4-1:0] gd_score,
    output [6*4-1:0] gd_lines,
    output [6*4-1:0] gd_level,
    output [4*4*4-1:0] gd_next_block_data,
    output [`TETRIS_COLORS_WIDTH-1:0] gd_next_block_color,
    output [1:0] gd_next_block_rotation,
    output signed [`FIELD_COL_CNT_WIDTH:0] gd_next_block_x,
    output signed [`FIELD_ROW_CNT_WIDTH:0] gd_next_block_y,
    output gd_next_block_draw_en,
    output gd_game_over_state

);

// game field state
logic [`FIELD_EXT_ROW_CNT*`FIELD_EXT_COL_CNT-1:0] field;
logic [`FIELD_EXT_ROW_CNT*`FIELD_EXT_COL_CNT*`TETRIS_COLORS_WIDTH-1:0] field_with_color ;
logic [`FIELD_EXT_ROW_CNT*`FIELD_EXT_COL_CNT*`TETRIS_COLORS_WIDTH-1:0] field_clean;
logic [`FIELD_EXT_ROW_CNT*`FIELD_EXT_COL_CNT*`TETRIS_COLORS_WIDTH-1:0] field_shifted;
logic [`FIELD_EXT_ROW_CNT*`FIELD_EXT_COL_CNT*`TETRIS_COLORS_WIDTH-1:0] field_with_cur_block;

// next block info
logic [4*4*4-1:0] next_block_data;
logic [`TETRIS_COLORS_WIDTH-1:0] next_block_color;
logic [1:0] next_block_rotation;
logic signed [`FIELD_COL_CNT_WIDTH:0] next_block_x;
logic signed [`FIELD_ROW_CNT_WIDTH:0] next_block_y;

// current block info
logic [4*4*4-1:0] cur_block_data;
logic [`TETRIS_COLORS_WIDTH-1:0] cur_block_color;
logic [1:0] cur_block_rotation;
logic signed [`FIELD_COL_CNT_WIDTH:0] cur_block_x;
logic signed [`FIELD_ROW_CNT_WIDTH:0] cur_block_y;

logic cur_block_draw_en;

logic sys_event;

logic check_move_run;
logic check_move_done;
logic can_move;
logic signed [1:0] move_x;
logic signed [1:0] move_y;

logic [2:0] req_move;
logic [2:0] next_req_move;

logic [`FIELD_ROW_CNT-1:0] full_row;
logic [$clog2(`FIELD_ROW_CNT)-1:0] full_row_num;

logic check_lines_first_tick;

int unsigned state, next_state;

always_comb
  begin
    field_clean = '0;

    for( int row = 0; row < `FIELD_EXT_ROW_CNT; row++ )
      begin
        for( int col = 0; col < `FIELD_EXT_COL_CNT; col++ )
          begin
            if( ( col == 0 ) || ( col == ( `FIELD_EXT_COL_CNT - 1 ) ) ||
                                ( row == ( `FIELD_EXT_ROW_CNT - 1 ) ) )
              field_clean[row][col] = 'd1;
          end
      end
  end

always_ff @( posedge clk or posedge rst )
  if( rst )
    field_with_color <= '0;
  else
    begin
      case( state )
        `STATE_NEW_GAME:     field_with_color <= field_clean;
        `STATE_APPEND_BLOCK: field_with_color <= field_with_cur_block;
        `STATE_CHECK_LINES:  field_with_color <= field_shifted;
      endcase
    end

always_comb
  begin
    for( int row = 0; row < `FIELD_EXT_ROW_CNT; row++ )
      begin
        for( int col = 0; col < `FIELD_EXT_COL_CNT; col++ )
          begin
            field[ row ][ col ] = ( field_with_color[ row ][ col ] != 'd0 );
          end
      end
  end

always_comb
  begin
    for( int row = 0; row < `FIELD_ROW_CNT; row++ )
      begin
        full_row[ row ] = &field[ row + 1 ][`FIELD_COL_CNT:1];
      end
  end

always_comb
  begin
    full_row_num = '0;

    for( int row = 0; row < `FIELD_ROW_CNT; row++ )
      begin
        if( full_row[ row ] )
          full_row_num = row;
      end
  end

always_comb
  begin
    field_shifted = field_with_color;

    if( |full_row )
      begin
        for( int row = 0; row < `FIELD_ROW_CNT; row++ )
          begin
            if( row <= full_row_num )
              begin
                if( row == 0 )
                  begin
                    field_shifted[ 0   + 1 ][`FIELD_COL_CNT:1] = '0;
                  end
                else
                  begin
                    field_shifted[ row + 1 ][`FIELD_COL_CNT:1] = field_with_color[row][`FIELD_COL_CNT:1];
                  end
              end
          end
      end
  end


always_comb
  begin
    field_with_cur_block = field_with_color;

    if( cur_block_draw_en )
      begin
        for( int i = 0; i < 4; i++ )
          begin
            for( int j = 0; j < 4; j++ )
              begin
                if( cur_block_data[cur_block_rotation][i][j] )
                  field_with_cur_block[ cur_block_y + i ][ cur_block_x + j ] = cur_block_color;
              end
          end
      end
  end

assign user_event_rd_req_o = user_event_ready_i && ( ( state == `STATE_IDLE       ) ||
                                                     ( state == `STATE_WAIT_EVENT ) ||
                                                     ( state == `STATE_GAME_OVER  ) );
always_comb
  begin
    next_req_move[2:0] = `MOVE_DOWN;

    if( state == `STATE_WAIT_EVENT )
      begin
        if( user_event_ready_i )
          begin
            case( user_event_i[2:0] )
              `EV_LEFT:   next_req_move[2:0] = `MOVE_LEFT;
              `EV_RIGHT:  next_req_move[2:0] = `MOVE_RIGHT;
              `EV_DOWN:   next_req_move[2:0] = `MOVE_DOWN;
              `EV_ROTATE: next_req_move[2:0] = `MOVE_ROTATE;
              default:   next_req_move[2:0] = `MOVE_DOWN;
            endcase
          end
      end
    else
      if( state == `STATE_GEN_NEW_BLOCK )
        begin
          next_req_move[2:0] = `MOVE_APPEAR;
        end
  end

always_ff @( posedge clk or posedge rst )
  if( rst )
    req_move[2:0] <= `MOVE_DOWN;
  else
    if( ( next_state == `STATE_CHECK_MOVE ) && ( state != `STATE_CHECK_MOVE ) )
      req_move[2:0] <= next_req_move[2:0];

always_ff @( posedge clk or posedge rst )
  if( rst )
    state <= `STATE_IDLE;
  else
    state <= next_state;

always_comb
  begin
    next_state = state;

    case( state )
      `STATE_IDLE:
        begin
          if( user_event_ready_i )
            begin
              if( user_event_i[2:0] == `EV_NEW_GAME )
                next_state = `STATE_NEW_GAME;
            end
        end

      `STATE_NEW_GAME:
        begin
          next_state = `STATE_GEN_NEW_BLOCK;
        end

      `STATE_GEN_NEW_BLOCK:
        begin
          next_state = `STATE_CHECK_MOVE;
        end

      `STATE_WAIT_EVENT:
        begin
          if( user_event_ready_i )
            begin
              case( user_event_i[2:0] )
                `EV_LEFT, `EV_RIGHT, `EV_DOWN, `EV_ROTATE:
                  begin
                    next_state = `STATE_CHECK_MOVE;
                  end
                `EV_NEW_GAME:
                  begin
                    next_state = `STATE_NEW_GAME;
                  end
                default:
                  begin
                    next_state = `STATE_WAIT_EVENT;
                  end
              endcase
            end
          else
            if( sys_event )
              begin
                // shifting down after waiting
                next_state = `STATE_CHECK_MOVE;
              end
        end

      `STATE_CHECK_MOVE:
        begin
          if( check_move_done )
            next_state = `STATE_MAKE_MOVE;
        end

      `STATE_MAKE_MOVE:
        begin
          if( ( req_move[2:0] == `MOVE_APPEAR ) && ( !can_move ) )
            next_state = `STATE_GAME_OVER;
          else
            if( ( req_move[2:0] == `MOVE_DOWN ) && ( !can_move ) )
              begin
                if( |field[0][`FIELD_COL_CNT:1] )
                  next_state = `STATE_GAME_OVER;
                else
                  // bottom edge reached
                  next_state = `STATE_APPEND_BLOCK;
              end
            else
              begin
                next_state = `STATE_WAIT_EVENT;
              end
        end

      `STATE_APPEND_BLOCK:
        begin
          next_state = `STATE_CHECK_LINES;
        end

      `STATE_CHECK_LINES:
        begin
          // preserving state if at least one cell active
          if( !( |full_row ) )
            next_state = `STATE_GEN_NEW_BLOCK;
        end

      `STATE_GAME_OVER:
        begin
          if( user_event_ready_i )
            begin
              if( user_event_i[2:0] == `EV_NEW_GAME )
                next_state = `STATE_NEW_GAME;
            end
        end

      default:
        begin
          next_state = `STATE_IDLE;
        end
    endcase
  end

always_ff @( posedge clk or posedge rst )
  if( rst )
    begin
      cur_block_data <= '0;
      cur_block_color <= '0;
      cur_block_rotation <= '0;
      cur_block_x <= '0;
      cur_block_y <= '0;

      cur_block_draw_en <= 1'b0;
    end
  else
    begin
      if( state == `STATE_GEN_NEW_BLOCK )
        begin
          cur_block_data <= next_block_data;
          cur_block_color <= next_block_color;
          cur_block_rotation <= next_block_rotation;
          cur_block_x <= next_block_x;
          cur_block_y <= next_block_y;

          cur_block_draw_en <= 1'b0;
        end

      if( state == `STATE_MAKE_MOVE )
        begin
          if( can_move )
            begin
              cur_block_x <= cur_block_x + move_x;
              cur_block_y <= cur_block_y + move_y;

              if( req_move[2:0] == `MOVE_APPEAR )
                begin
                  cur_block_draw_en <= 1'b1;
                end

              if( req_move[2:0] == `MOVE_ROTATE )
                begin
                  cur_block_rotation <= cur_block_rotation + 1'd1;
                end
            end
        end
    end


always_comb
  begin
    for( int col = 0; col < `FIELD_COL_CNT; col++ )
      begin
        for( int row = 0; row < `FIELD_ROW_CNT; row++ )
          begin
            gd_field[row][col] = field_with_cur_block[ row + 1 ][ col + 1 ];
          end
      end
  end

always_comb
  begin
    gd_next_block_data = next_block_data;
    gd_next_block_color = next_block_color;
    gd_next_block_rotation = next_block_rotation;
    gd_next_block_x = next_block_x;
    gd_next_block_y = next_block_y;

    gd_next_block_draw_en = ( state != `STATE_IDLE      );
    gd_game_over_state    = ( state == `STATE_GAME_OVER );
  end

assign check_move_run = ( state != `STATE_CHECK_MOVE ) && ( next_state == `STATE_CHECK_MOVE );

check_move check_move(
    .clk( clk ),
    .run_i( check_move_run ),
    .req_move_i( next_req_move[2:0] ),

    // block info output
    .b_data( cur_block_data ),
    .b_color( cur_block_color ),
    .b_rotation( cur_block_rotation ),
    .b_x( cur_block_x ),
    .b_y( cur_block_y ),

    .field_i( field ),
    .done_o( check_move_done ),
    .can_move_o( can_move ),
    .move_x_o( move_x ),
    .move_y_o( move_y )
);


always_ff @( posedge clk or posedge rst )
  if( rst )
    check_lines_first_tick <= '0;
  else
    check_lines_first_tick <= ( state == `STATE_APPEND_BLOCK ) && ( next_state == `STATE_CHECK_LINES );


logic [2:0] disappear_lines_cnt;

always_comb
  begin
    disappear_lines_cnt = 0;

    for( int row = 0; row < `FIELD_ROW_CNT; row++ )
      begin
        if( full_row[row] )
          disappear_lines_cnt = disappear_lines_cnt + 1'd1;
      end
  end

logic stat_srst;

assign stat_srst = ( state == `STATE_NEW_GAME ) && ( next_state != `STATE_NEW_GAME );

logic level_changed;

tetris_stat stat(
    .clk( clk ),

    // sync reset - when starts new game
    .srst( stat_srst ),

    .disappear_lines_cnt_i( disappear_lines_cnt ),
    .update_stat_en_i( check_lines_first_tick ),

    .score_o( gd_score ),
    .lines_o( gd_lines ),
    .level_o( gd_level ),

    .level_changed_o( level_changed )
);


logic gen_next_block_en;

assign gen_next_block_en = ( state == `STATE_IDLE          ) ||
                           ( state == `STATE_GEN_NEW_BLOCK );

gen_next_block gen_next_block(
    .clk( clk ),
    .en_i( gen_next_block_en ),

    // block info input
    .b_data( next_block_data ),
    .b_color( next_block_color ),
    .b_rotation( next_block_rotation ),
    .b_x( next_block_x ),
    .b_y( next_block_y )
);

logic sys_event_srst;

assign sys_event_srst = ( state == `STATE_NEW_GAME ) && ( next_state != `STATE_NEW_GAME );

gen_sys_event gen_sys_event(
    .clk( clk ),
    .srst( sys_event_srst ),
    .level_changed_i( level_changed ),
    .sys_event_o( sys_event )
);

endmodule

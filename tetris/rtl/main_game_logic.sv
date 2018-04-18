`include "../rtl/defs.vh"

module main_game_logic
(
  input                                               clk_i,
  input                                               rst_i,

  input                                        [2:0]  user_event_i,
  input                                               user_event_ready_i,
  output                                              user_event_rd_req_o,

  output         game_data_t                          game_data_o

);

// game field state
logic [`FIELD_EXT_ROW_CNT-1:0][`FIELD_EXT_COL_CNT-1:0]                           field;
logic [`FIELD_EXT_ROW_CNT-1:0][`FIELD_EXT_COL_CNT-1:0][`TETRIS_COLORS_WIDTH-1:0] field_with_color;
logic [`FIELD_EXT_ROW_CNT-1:0][`FIELD_EXT_COL_CNT-1:0][`TETRIS_COLORS_WIDTH-1:0] field_clean;
logic [`FIELD_EXT_ROW_CNT-1:0][`FIELD_EXT_COL_CNT-1:0][`TETRIS_COLORS_WIDTH-1:0] field_shifted;

// current block
logic [`FIELD_EXT_ROW_CNT-1:0][`FIELD_EXT_COL_CNT-1:0][`TETRIS_COLORS_WIDTH-1:0] field_with_cur_block;

//logic [0:3][0:3]   cur_block_data;

// next block info
input logic        [63:0]                      next_block_data;
input logic        [`TETRIS_COLORS_WIDTH-1:0]  next_block_color;
input logic        [1:0]                       next_block_rotation;
input logic signed [`FIELD_COL_CNT_WIDTH:0]    next_block_x;
input logic signed [`FIELD_ROW_CNT_WIDTH:0]    next_block_y;

// current block info
input logic        [63:0]                      cur_block_data;
input logic        [`TETRIS_COLORS_WIDTH-1:0]  cur_block_color;
input logic        [1:0]                       cur_block_rotation;
input logic signed [`FIELD_COL_CNT_WIDTH:0]    cur_block_x;
input logic signed [`FIELD_ROW_CNT_WIDTH:0]    cur_block_y;

logic              cur_block_draw_en;

logic              sys_event;

logic              check_move_run;
logic              check_move_done;
logic              can_move;
logic signed [1:0] move_x;
logic signed [1:0] move_y;

logic [2:0]        req_move;
logic [2:0]        next_req_move;

logic [`FIELD_ROW_CNT-1:0]         full_row;
logic [$clog2(`FIELD_ROW_CNT)-1:0] full_row_num;

logic check_lines_first_tick;

enum int unsigned { IDLE_S,
                    NEW_GAME_S,
                    GEN_NEW_BLOCK_S,
                    WAIT_EVENT_S,
                    CHECK_MOVE_S,
                    MAKE_MOVE_S,
                    APPEND_BLOCK_S,
                    CHECK_LINES_S,
                    GAME_OVER_S } state, next_state;

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

always_ff @( posedge clk_i or posedge rst_i )
  if( rst_i )
    field_with_color <= '0;
  else
    begin
      case( state )
        NEW_GAME_S:     field_with_color <= field_clean;
        APPEND_BLOCK_S: field_with_color <= field_with_cur_block;
        CHECK_LINES_S:  field_with_color <= field_shifted;
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

assign cur_block_data = cur_block.data[ cur_block.rotation ];

always_comb
  begin
    field_with_cur_block = field_with_color;

    if( cur_block_draw_en )
      begin
        for( int i = 0; i < 4; i++ )
          begin
            for( int j = 0; j < 4; j++ )
              begin
                if( cur_block_data[i][j] )
                  field_with_cur_block[ cur_block.y + i ][ cur_block.x + j ] = cur_block.color;
              end
          end
      end
  end

assign user_event_rd_req_o = user_event_ready_i && ( ( state == IDLE_S       ) ||
                                                     ( state == WAIT_EVENT_S ) ||
                                                     ( state == GAME_OVER_S  ) );
always_comb
  begin
    next_req_move[2:0] = `MOVE_DOWN;

    if( state == WAIT_EVENT_S )
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
      if( state == GEN_NEW_BLOCK_S )
        begin
          next_req_move[2:0] = `MOVE_APPEAR;
        end
  end

always_ff @( posedge clk_i or posedge rst_i )
  if( rst_i )
    req_move[2:0] <= `MOVE_DOWN;
  else
    if( ( next_state == CHECK_MOVE_S ) && ( state != CHECK_MOVE_S ) )
      req_move[2:0] <= next_req_move[2:0];

always_ff @( posedge clk_i or posedge rst_i )
  if( rst_i )
    state <= IDLE_S;
  else
    state <= next_state;

always_comb
  begin
    next_state = state;

    case( state )
      IDLE_S:
        begin
          if( user_event_ready_i )
            begin
              if( user_event_i[2:0] == `EV_NEW_GAME )
                next_state = NEW_GAME_S;
            end
        end

      NEW_GAME_S:
        begin
          next_state = GEN_NEW_BLOCK_S;
        end

      GEN_NEW_BLOCK_S:
        begin
          next_state = CHECK_MOVE_S;
        end

      WAIT_EVENT_S:
        begin
          if( user_event_ready_i )
            begin
              case( user_event_i[2:0] )
                `EV_LEFT, `EV_RIGHT, `EV_DOWN, `EV_ROTATE:
                  begin
                    next_state = CHECK_MOVE_S;
                  end
                `EV_NEW_GAME:
                  begin
                    next_state = NEW_GAME_S;
                  end
                default:
                  begin
                    next_state = WAIT_EVENT_S;
                  end
              endcase
            end
          else
            if( sys_event )
              begin
                // shifting down after waiting
                next_state = CHECK_MOVE_S;
              end
        end

      CHECK_MOVE_S:
        begin
          if( check_move_done )
            next_state = MAKE_MOVE_S;
        end

      MAKE_MOVE_S:
        begin
          if( ( req_move[2:0] == MOVE_APPEAR ) && ( !can_move ) )
            next_state = GAME_OVER_S;
          else
            if( ( req_move[2:0] == MOVE_DOWN ) && ( !can_move ) )
              begin
                if( |field[0][`FIELD_COL_CNT:1] )
                  next_state = GAME_OVER_S;
                else
                  // bottom edge reached
                  next_state = APPEND_BLOCK_S;
              end
            else
              begin
                next_state = WAIT_EVENT_S;
              end
        end

      APPEND_BLOCK_S:
        begin
          next_state = CHECK_LINES_S;
        end

      CHECK_LINES_S:
        begin
          // preserving state if at least one cell active
          if( !( |full_row ) )
            next_state = GEN_NEW_BLOCK_S;
        end

      GAME_OVER_S:
        begin
          if( user_event_ready_i )
            begin
              if( user_event_i[2:0] == `EV_NEW_GAME )
                next_state = NEW_GAME_S;
            end
        end

      default:
        begin
          next_state = IDLE_S;
        end
    endcase
  end

always_ff @( posedge clk_i or posedge rst_i )
  if( rst_i )
    begin
      cur_block         <= '0;
      cur_block_draw_en <= 1'b0;
    end
  else
    begin
      if( state == GEN_NEW_BLOCK_S )
        begin
          cur_block_data <= next_block_data;
          cur_block_color <= next_block_color;
          cur_block_rotation <= next_block_rotation;
          cur_block_x <= next_block_x;
          cur_block_y <= next_block_y;

          cur_block_draw_en <= 1'b0;
        end

      if( state == MAKE_MOVE_S )
        begin
          if( can_move )
            begin
              cur_block.x    <= cur_block.x + move_x;
              cur_block.y    <= cur_block.y + move_y;

              if( req_move[2:0] == MOVE_APPEAR )
                begin
                  cur_block_draw_en <= 1'b1;
                end

              if( req_move[2:0] == MOVE_ROTATE )
                begin
                  cur_block.rotation <= cur_block.rotation + 1'd1;
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
            game_data_o.field[row][col] = field_with_cur_block[ row + 1 ][ col + 1 ];
          end
      end
  end

always_comb
  begin
    game_data_o_next_block_data = next_block_data;
    game_data_o_next_block_color = next_block_color;
    game_data_o_next_block_rotation = next_block_rotation;
    game_data_o_next_block_x = next_block_x;
    game_data_o_next_block_y = next_block_y;

    game_data_o.next_block_draw_en = ( state != IDLE_S      );
    game_data_o.game_over_state    = ( state == GAME_OVER_S );
  end

assign check_move_run = ( state != CHECK_MOVE_S ) && ( next_state == CHECK_MOVE_S );

check_move check_move(
  .clk_i                                  ( clk_i             ),

  .run_i                                  ( check_move_run    ),

  .req_move_i                             ( next_req_move[2:0]),

  // block info
  .block_i_data                           ( cur_block_data    ),
  .block_i_color                          ( cur_block_color   ),
  .block_i_rotation                       ( cur_block_rotation),
  .block_i_x                              ( cur_block_x       ),
  .block_i_y                              ( cur_block_y       ),

  .field_i                                ( field             ),

  .done_o                                 ( check_move_done   ),
  .can_move_o                             ( can_move          ),
  .move_x_o                               ( move_x            ),
  .move_y_o                               ( move_y            )
);


always_ff @( posedge clk_i or posedge rst_i )
  if( rst_i )
    check_lines_first_tick <= '0;
  else
    check_lines_first_tick <= ( state == APPEND_BLOCK_S ) && ( next_state == CHECK_LINES_S );


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

assign stat_srst = ( state == NEW_GAME_S ) && ( next_state != NEW_GAME_S );

logic level_changed;

tetris_stat stat(
  .clk_i                                  ( clk_i                  ),

  // sync reset - when starts new game
  .srst_i                                 ( stat_srst              ),

  .disappear_lines_cnt_i                  ( disappear_lines_cnt    ),
  .update_stat_en_i                       ( check_lines_first_tick ),

  .score_o                                ( game_data_o.score      ),
  .lines_o                                ( game_data_o.lines      ),
  .level_o                                ( game_data_o.level      ),

  .level_changed_o                        ( level_changed          )
);


logic gen_next_block_en;

assign gen_next_block_en = ( state == IDLE_S          ) ||
                           ( state == GEN_NEW_BLOCK_S );

gen_next_block gen_next_block(
  .clk_i                                  ( clk_i                     ),
  .en_i                                   ( gen_next_block_en         ),

    // block info
  .next_block_o_data                      ( next_block_data    ),
  .next_block_o_color                     ( next_block_color   ),
  .next_block_o_rotation                  ( next_block_rotation),
  .next_block_o_x                         ( next_block_x       ),
  .next_block_o_y                         ( next_block_y       )
);

logic sys_event_srst;

assign sys_event_srst = ( state == NEW_GAME_S ) && ( next_state != NEW_GAME_S );

gen_sys_event gen_sys_event(
  .clk_i                                  ( clk_i             ),
  .srst_i                                 ( sys_event_srst    ),

  .level_changed_i                        ( level_changed     ),

  .sys_event_o                            ( sys_event         )

);

// synthesis translate_off
initial
  begin
    forever
      begin
        @( posedge clk_i );
        $write("-------%t-------\n", $time() );
        for( int row = 0; row < `FIELD_EXT_ROW_CNT; row++ )
          begin
            for( int col = 0; col < `FIELD_EXT_COL_CNT; col++ )
              begin
                if( ( col == 0 ) || ( col == ( `FIELD_EXT_COL_CNT - 1 ) ) ||
                                    ( row == ( `FIELD_EXT_ROW_CNT - 1 ) ) )
                  begin
                    $write( "*" );
                  end
                else
                  begin
                    $write( "%h", field_with_cur_block[ row ][ col ] );
                  end
              end
            $write("\n");
          end
      end
  end
// synthesis translate_on

endmodule

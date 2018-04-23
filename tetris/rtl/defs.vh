`ifndef TETRIS_DEFS
`define TETRIS_DEFS

// user_events
`define EV_DOWN 3'b000
`define EV_RIGHT 3'b001
`define EV_LEFT 3'b010
`define EV_ROTATE 3'b011
`define EV_NEW_GAME 3'b100

// moves
`define MOVE_DOWN 3'b000
`define MOVE_RIGHT 3'b001
`define MOVE_LEFT 3'b010
`define MOVE_ROTATE 3'b011
`define MOVE_APPEAR 3'b100

// game state machine
`define STATE_IDLE 0
`define STATE_NEW_GAME 1
`define STATE_GEN_NEW_BLOCK 2
`define STATE_WAIT_EVENT 3
`define STATE_CHECK_MOVE 4
`define STATE_MAKE_MOVE 5
`define STATE_APPEND_BLOCK 6
`define STATE_CHECK_LINES 7
`define STATE_GAME_OVER 8

// ******* PS/2 keyboard scan codes *******

// from http://www.computer-engineering.org/ps2keyboard/scancodes2.html
`define SCAN_CODE_ESC         8'h76
`define SCAN_CODE_N           8'h31
`define SCAN_CODE_ENTER       8'h5A

`define SCAN_CODE_ARROW_UP    16'hE0_75
`define SCAN_CODE_ARROW_LEFT  16'hE0_6B
`define SCAN_CODE_ARROW_DOWN  16'hE0_72
`define SCAN_CODE_ARROW_RIGHT 16'hE0_74


// ******* Tetris Settings *******

`define  FIELD_COL_CNT           10
`define  FIELD_ROW_CNT           20
`define  FIELD_COL_CNT_WIDTH     $clog2( `FIELD_COL_CNT )
`define  FIELD_ROW_CNT_WIDTH     $clog2( `FIELD_ROW_CNT )

// plus two to set up border blocks
`define FIELD_EXT_COL_CNT       ( `FIELD_COL_CNT + 2 )
`define FIELD_EXT_ROW_CNT       ( `FIELD_ROW_CNT + 2 )

`define TETRIS_COLORS_CNT       8
`define TETRIS_COLORS_WIDTH     $clog2( `TETRIS_COLORS_CNT )

// ******* Colors *******
`define COLOR_BACKGROUND  24'h80_80_80

`define COLOR_BORDERS     24'hFF_FF_FF

`define COLOR_BRICKS_0    24'hFF_FF_FF
`define COLOR_BRICKS_1    24'h76_C5_DA
`define COLOR_BRICKS_2    24'hC9_92_C9
`define COLOR_BRICKS_3    24'h75_A3_D0
`define COLOR_BRICKS_4    24'hCC_99_33
`define COLOR_BRICKS_5    24'h87_C3_7F
`define COLOR_BRICKS_6    24'hDE_7F_72
`define COLOR_BRICKS_7    24'h8A_8A_B0

`define COLOR_TEXT        24'hFF_D7_00 // gold

`define COLOR_HEAD        24'hFA_94_54 // some sort of orange

`define COLOR_GAME_OVER   24'h8A_07_07 // blooooody red

`endif

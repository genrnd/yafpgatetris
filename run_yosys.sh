#!/bin/bash

yosys -p "synth_intel -family cyclonev -top rtl_top -vqm rtl_top.vqm" rtl_top.sv tetris/rtl/defs.vh tetris/rtl/bin_2_bcd.sv tetris/rtl/draw_tetris.sv tetris/rtl/main_game_logic.sv tetris/rtl/check_move.sv tetris/rtl/font.mif tetris/rtl/game_over.mif tetris/rtl/string_rom.v tetris/rtl/draw_big_string.sv tetris/rtl/gen_next_block.sv tetris/rtl/tetris_stat.sv tetris/rtl/draw_field_helper.sv tetris/rtl/user_input_fifo.v tetris/rtl/draw_field.sv tetris/rtl/gen_sys_event.sv tetris/rtl/user_input.sv tetris/rtl/draw_strings.sv tetris/rtl/head.mif ip_cores/ps2_keyboard/Altera_UP_PS2_Command_Out.v ip_cores/ps2_keyboard/PS2_Controller.v ip_cores/ps2_keyboard/Altera_UP_PS2_Data_In.v ip_cores/vga/vga_time_generator.v


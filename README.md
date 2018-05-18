# Yosys-tetris project

Originally "yafpgatetris" project by johan92

This fork is an adaptation of original tetris for Yosys open synthesis framework

[yosys-tetris wiki pages](https://github.com/genrnd/yosys-tetris/wiki)

### To run this project:

  * install **Yosys** and its prerequisites from latest souces at https://github.com/YosysHQ. We work on **Yosys** commit `a728193` and external **ABC** tool commit `37504a4`. Please see https://github.com/genrnd/yosys-tetris/wiki/Installing-Yosys and https://github.com/genrnd/yosys-tetris/wiki/Our-Yosys-setup wiki pages for more information.
  * clone project repository from https://github.com/genrnd/yosys-tetris
  * launch `run.sh` from project repository in Linux terminal

### Expected compilation results

  * **Yosys** compilation log will be stored as `yosys.log` in project root directory
  * Generated `vqm` netlist will be stored in project root directory in case of sucessful compile (we don't got it yet)
  * after getting `vqm` netlist please open `yosys-tetris.qpf` project in latest Intel Quartus Lite software and launch compilation
  * resulting `sof` file is suitable for Intel Cyclone V chip, part number 5CGXFC7C7F23C8

### Current project status

Current project status is described on https://github.com/genrnd/yosys-tetris/wiki/Project-status wiki page

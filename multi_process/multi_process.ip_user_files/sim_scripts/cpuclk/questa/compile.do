vlib work
vlib msim

vlib msim/xil_defaultlib

vmap xil_defaultlib msim/xil_defaultlib

vlog -work xil_defaultlib -64 \
"../../../../multi_process.srcs/sources_1/ip/cpuclk/cpuclk_clk_wiz.v" \
"../../../../multi_process.srcs/sources_1/ip/cpuclk/cpuclk.v" \


vlog -work xil_defaultlib "glbl.v"


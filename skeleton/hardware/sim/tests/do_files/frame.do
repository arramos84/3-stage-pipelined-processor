proc start {m} {vsim -L unisims_ver -L unimacro_ver -L xilinxcorelib_ver -L secureip work.glbl $m}
start FrameFillerTestbench
add wave FrameFillerTestbench/*
add wave FrameFillerTestbench/FF/*
run 5000us

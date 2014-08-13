start asmTestbench
file copy -force ../../../software/asmtest/asmtest.mif imem_blk_ram.mif
file copy -force ../../../software/asmtest/asmtest.mif dmem_blk_ram.mif
add wave asmTestbench/*
add wave asmTestbench/CPU/*
add wave asmTestbench/CPU/InstFetch_Stage/*
add wave asmTestbench/CPU/RegEx_Stage/*
add wave asmTestbench/CPU/MemWriteBack_Stage/*
run 10000us

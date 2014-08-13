start EchoTestbench
file copy -force ../../../software/bios150v3/bios150v3.mif imem_blk_ram.mif
file copy -force ../../../software/bios150v3/bios150v3.mif dmem_blk_ram.mif
add wave EchoTestbench/*
add wave EchoTestbench/CPU/*
add wave EchoTestbench/CPU/InstFetch_Stage/*
add wave EchoTestbench/CPU/RegEx_Stage/*
add wave EchoTestbench/CPU/MemWriteBack_Stage/*
run 100000us

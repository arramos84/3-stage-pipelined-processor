start EchoTestbenchCaches
file copy -force ../../../software/mmult/mmult.mif bios_mem.mif
add wave EchoTestbenchCaches/*
add wave EchoTestbenchCaches/CPU/*
add wave EchoTestbenchCaches/CPU/InstFetch_Stage/*
add wave EchoTestbenchCaches/CPU/RegEx_Stage/*
add wave EchoTestbenchCaches/CPU/MemWriteBack_Stage/*
add wave EchoTestbenchCaches/mem_arch/*
add wave EchoTestbenchCaches/mem_arch/dcache/*
add wave EchoTestbenchCaches/mem_arch/icache/*
run 1000us

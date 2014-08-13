start EchoTestbenchCaches
file copy -force ../../../software/isr/isr.mif isr_mem.mif
file copy -force ../../../software/bios150v3/bios150v3.mif bios_mem.mif
add wave EchoTestbenchCaches/*
add wave EchoTestbenchCaches/CPU/*
add wave EchoTestbenchCaches/CPU/InstFetch_Stage/*
add wave EchoTestbenchCaches/CPU/RegEx_Stage/*
add wave EchoTestbenchCaches/CPU/RegEx_Stage/cpo/*
add wave EchoTestbenchCaches/CPU/MemWriteBack_Stage/*
add wave EchoTestbenchCaches/mem_arch/*
add wave EchoTestbenchCaches/mem_arch/dcache/*
add wave EchoTestbenchCaches/mem_arch/icache/*
run 9000us

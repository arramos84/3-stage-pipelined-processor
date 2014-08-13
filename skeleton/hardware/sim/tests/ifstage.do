start IF_STAGETestbench
file copy -force ../../../software/echo/echo.mif imem_blk_ram.mif
add wave IF_STAGETestbench/*
run 10000us

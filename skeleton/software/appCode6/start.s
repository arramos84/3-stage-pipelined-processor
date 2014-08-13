.section    .start
.global     _start

_start:
    li      $sp, 0x11000000
    addiu		$sp, $sp, -4
		sw 			$ra, 0($sp)

		jal     main

		lw 			$t0, 0($sp)
		jr			$t0

		

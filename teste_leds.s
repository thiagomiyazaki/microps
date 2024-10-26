
.equ DATA_LEDS_R, 0x10000000
.global _start
_start:
    movia r8, DATA_LEDS_R
    addi  r9, r0, 0b0101
    stwio r9, 0(r8)

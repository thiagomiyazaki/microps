/* START - CONFIG PUSHBTN */

.equ PUSHBTN, 0x10000050
.equ TIMER,   0x10002000

.global _pushbtn_interrups
_pushbtn_interrups:
    /* START - PROLOGO */
    stw     r16, 0(sp)
    subi    sp, sp, 4
    stw     r17, 0(sp)
    /* END - PROLOGO */

    /* RESETAR PUSHBTNS */
    movia   r16, PUSHBTN
    addi    r17, r0, 0xF
    stwio   r17,  0xC(r16)          /* reseta os pushbuttons */

    /* VERIFICA SE TIMER == RUNNING / SE ESTIVER -> STOP / SE NÃO ESTIVER -> RUN */
    /* 
        STATUS REGISTER (TIMER)
            TO  - b0 (== 1 when timer reaches zero. The TO bit can be reset by writing a 0 into it.)
            RUN - b1 (is set to 1 by the timer whenever it is currently counting)
        CONTROL REGISTER (TIMER + 4)
            habilitar ITO   - b0 (habilita interrupcoes do timer)
            habilitar CONT  - b1 (quando chega a zero reseta)
            habilitar START - b2 (inicia o contador quando == 1)
            habilitar STOP  - b3 (para o contador)
    */
    movia   r16, TIMER
    ldwio   r16, 0(r16)     /* copia o valor do registrador STATUS (TIMER) */

    /* O TIMER ESTÁ CORRENDO? */
    andi    r16, r16, 0b0010    /* aplica mascara para verificar se RUN (b1) == 1 */
    addi    r17, r0,  0b0010    /* constante para comparação */
    beq     r16, r17, STOP_TIMER_PUSHBTN
    br      START_TIMER_PUSBTH

    STOP_TIMER_PUSHBTN:
        movia   r16, TIMER_STATUS_REG
        addi    r17, r0, 0b1011 /* stop == 1 (b3) */
        stwio   r17, 4(r16)

        /* START - EPILOGO */
        ldw     r17, 0(sp)
        addi    sp, sp, 4
        ldw     r16, 0(sp)
        /* END - EPILOGO */
        ret

    START_TIMER_PUSBTH:
        movia   r16, TIMER_STATUS_REG
        addi    r17, r0, 0b0111 /* start == 1 (b2) */
        stwio   r17, 4(r16)
        /* START - EPILOGO */
        ldw     r17, 0(sp)
        addi    sp, sp, 4
        ldw     r16, 0(sp)
        /* END - EPILOGO */
        ret

/* END - CONFIG PUSHBTN */
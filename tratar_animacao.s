/* START - TRATAR ANIMACAO */

/* 

1. habilitar o bit RUN do registrador STATUS do Interval Timer
2. A cada vez que o contador chegar a 0 limpar o bit TO do Status (limpar == tornar zero)

10 000 000 de ciclos == 200 ms

*/

.equ TIMER_STATUS_REG,   0x10002000
.equ DATA_LEDS_R,        0x10000000
.equ SWITCHES_REG,       0x10000040

.global _tratar_animacao
_tratar_animacao:
    /* START - PROLOGO */
    stw     r16, 0(sp)
    subi    sp, sp, 4
    stw     r17, 0(sp)
    /* END - PROLOGO */

    /* VERIFICAR SE É PARA INICIAR OU PARAR A ANIMACAO / 10 ACENDE e 11 APAGA */
    ldw     r16, 4(r4)                  /* pegar o bit menos significativo do comando */
    subi    r16, r16, 0x30              /* subtrair 0x30 para converter ASCII -> decimal */
    beq     r16, r0, INICIAR_ANIMACAO   /* se o segundo digito for igual a zero, iniciar animacao */
    br      PARAR_ANIMACAO              /* caso não seja, parar animacao */

    INICIAR_ANIMACAO:
        /* CONFIGURAR INTERRUPCAO */
        /* 
            CONTROL REGISTER (TIMER_STATUS_REG + 4)
            habilitar ITO   - b0 (habilita interrupcoes do timer)
            habilitar CONT  - b1 (quando chega a zero reseta)
            habilitar START - b2 (inicia o contador quando == 1)
            habilitar STOP  - b3 (para o contador)
        */

        /* ZERA TODOS OS LEDS - apaga todos */
        movia   r16, DATA_LEDS_R    /* pega endereco dos LEDS R */
        stwio   r0, 0(r16)          /* acende o ultimo led */
        
        movia   r16, TIMER_STATUS_REG   /* armazena em r16 o enderco do status reg do timer */

        /* setar o valor de contagem --> 10 000 000 == 0x0098 9680 */
        movia   r17, 0x9680     /* parte baixa de 10 000 000*/
        stwio   r17, 8(r16)     /* escreve parte baixa  */
        movia   r17, 0x0098     /* parte alta de 10 000 000*/
        stwio   r17, 12(r16)    /* escreve parte alta  */

        movia   r17, 0b0111     /* habilita interrups, habilita reset, e inicia contagem */
        stwio   r17, 4(r16)

        /* TO-DO HABILITAR FLAG DE ANIMACAO */

        /* LIGA O PRIMEIRO LED */
        movia   r16, SWITCHES_REG
        ldwio   r16, 0(r16)
        beq     r16, r0, LIGA_PRIMEIRO

        /* liga o ultimo led (b17) */
        LIGA_ULTIMO:
            /* LIGAR ULTIMO LED */
            movia   r16, DATA_LEDS_R    /* pega endereco dos LEDS R */
            movia   r17, 0x20000        /* valor que representa b17 == on */
            stwio   r17, 0(r16)         /* acende o ultimo led */

            /* START - EPILOGO */
            ldw     r17, 0(sp)
            addi    sp, sp, 4
            ldw     r16, 0(sp)
            /* END - EPILOGO */
            ret
        
        /* liga o primeiro led (b0) */
        LIGA_PRIMEIRO:
            movia   r16, DATA_LEDS_R    /* pega endereco dos LEDS R */
            addi    r17, r0, 0b0001     /* queremos acender o 1o LED */
            stwio   r17, 0(r16)         /* acende o 1o LED de fato */

            /* START - EPILOGO */
            ldw     r17, 0(sp)
            addi    sp, sp, 4
            ldw     r16, 0(sp)
            /* END - EPILOGO */
            ret

    PARAR_ANIMACAO:
        movia   r16, TIMER_STATUS_REG
        movia   r17, 0b1011     /* habilita interrups, habilita reset, e para contagem */
        stwio   r17, 4(r16)

        /* START - EPILOGO */
        ldw     r17, 0(sp)
        addi    sp, sp, 4
        ldw     r16, 0(sp)
        /* END - EPILOGO */
        ret    

/* END - TRATAR ANIMACAO */
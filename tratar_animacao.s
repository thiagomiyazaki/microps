/* 

1. habilitar o bit RUN do registrador STATUS do Interval Timer
2. A cada vez que o contador chegar a 0 limpar o bit TO do Status (limpar == tornar zero)

10 000 000 de ciclos == 200 ms

*/

.equ TIMER_STATUS_REG,   0x10002000

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
        movia   r16, TIMER_STATUS_REG   /* armazena em r16 o enderco do status reg do timer */

        /* setar o valor de contagem --> 10 000 000 == 0x0098 9680 */
        movia   r17, 0x9680     /* parte baixa de 10 000 000*/
        stwio   r17, 8(r16)     /* escreve parte baixa  */
        movia   r17, 0x0098     /* parte alta de 10 000 000*/
        stwio   r17, 12(r16)    /* escreve parte alta  */

        movia   r17, 0b0111     /* habilita interrups, habilita reset, e inicia contagem */
        stwio   r17, 4(r16)

        /* HABILITAR FLAG DE ANIMACAO */

        /* START - EPILOGO */
        ldw     r17, 0(sp)
        addi    sp, sp, 4
        ldw     r16, 0(sp)
        /* END - EPILOGO */
        ret

    PARAR_ANIMACAO:
        /* parar animacao */
        /* DESABILITAR INTERRUPCAO */
        /* FAZER EPILOGO */
        ret

    /* ADICIONAR PROLOGO DEPOIS */
    
    
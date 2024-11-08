.equ END_7SEG_DISPLAY,  0x10000020
.equ TIMER_STATUS_REG,  0x10002000

.global _tratar_cronometro
_tratar_cronometro:
    /* START - PROLOGO */
    stw     r16, 0(sp)
    subi    sp, sp, 4
    /* END - PROLOGO */

    /* VERIFICAR SE É PARA INICIAR OU PARAR O CRONOMETRO / 20 INICIAR e 21 CANCELA */
    ldw     r16, 4(r4)                    /* pegar o bit menos significativo do comando */
    subi    r16, r16, 0x30                /* subtrair 0x30 para converter ASCII -> decimal */
    beq     r16, r0, INICIAR_CRONOMETRO   /* se o segundo digito for igual a zero, iniciar cronometro */
    br      CANCELAR_CRONOMETRO              /* caso não seja, parar cronometro */

    INICIA_CRONOMETRO:
        /* CONFIGURAR O TIMER PARA INICIAR A CONTAGEM */
        movia   r16, TIMER_STATUS_REG
        
        /* setar o valor de contagem --> 50 000 000 == 0x02FA F080 */
        movia   r17, 0xF080     /* parte baixa de 10 000 000*/
        stwio   r17, 8(r16)     /* escreve parte baixa  */
        movia   r17, 0x02FA     /* parte alta de 10 000 000*/
        stwio   r17, 12(r16)    /* escreve parte alta  */

        movia   r17, 0b0111     /* habilita interrups, habilita reset, e inicia contagem */
        stwio   r17, 4(r16)

        addi    r23, r0, 1      /* INDICA PARA O TRATADOR DE INTERRUPS QUE O JOB ATUAL É DE CRONOMETRO */

        22 21 20 19

    CANCELAR_CRONOMETRO:
        /* CONFIGURAR O TIMER PARA INTERROMPER A CONTAGEM */



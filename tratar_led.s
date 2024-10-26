/* INIT TRATAR LED */

/*
    r4: endereco do primeiro caractere do comando
    0x30 : codigo ascii do caractere '0'
    00 : acender led
    01 : apagar led

    0       0       |       0        1       LF
    0       4       8       12       16      20
*/

.equ DATA_LEDS_R, 0x10000000

.global _tratar_led
_tratar_led:
    /* START - PROLOGO */
    stw     r16, 0(sp)
    subi    sp, sp, 4
    stw     r17, 0(sp)
    subi    sp, sp, 4
    stw     r18, 0(sp)
    subi    sp, sp, 4
    stw     r19, 0(sp)
    subi    sp, sp, 4
    stw     r20, 0(sp)
    /* END - PROLOGO */

    movia   r16, DATA_LEDS_R        /* guarda o endereco do DATA REG dos LEDS R */

    /* conversao decimal para binario */
    ldw     r18, 16(r4)             /* pega o digito decimal menos significativo */
    subi    r18, r18, 0x30          /* subtrai 0x30 do digito menos significativo */

    ldw     r19, 12(r4)              /* pega o digito decimal mais significativo */
    subi    r19, r19, 0x30          /* subtrai 0x30 do digito mais significativo */

    /* multiplica por dez : multiplica por oito e soma duas vezes */
    slli    r20, r19, 8             /* shift left 8 bits == multiplicar por 8 */
    add     r20, r20, r19           /* soma uma vez - primeira */
    add     r20, r20, r19           /* soma uma vez - segunda */

    /* resultado final da soma */
    add     r18, r18, r20

    /* verificar se devemos acender ou apagar o led */
    addi    r19, r0, 1              /* armazena o valor 1 em r18 para comparacao da linha 16 */
    ldw     r20, 4(r4)              /* pega o caractere que define a acao (apagar ou acender) */
    subi    r20, r20, 0x30          /* subtrai 0x30 do valor pego na linha anterior - 1 == 0x31 e 0 == 0x30 */
    beq     r20, r0,  ACENDER_LED   /* codigo 00 */
    beq     r20, r18, APAGAR_LED    /* codigo 01 */

    /*  
        r16 : endereco do DATA REG dos leds r
        r4 : endereco onde comeca o comando na memoria
        r18 : numero decimal que representa o led a ser manipulado
    */
    APAGAR_LED:
        ldwio   r19, 0(r16)          /* LER ESTADO DOS LEDS */
        addi    r20, r0, 1           /* inicializa a mascara como 0b0001 */
        sll     r20, r20, r18        /* leva o digito 1 para a casa binaria correta */
        sub     r19, r19, r20        /* estados_dos_leds OR mascara => acende o led */
        stwio   r19, 0(r16)          /* escreve o estado dos leds atualizado */

        /* START - EPILOGO */
        ldw     r20, 0(sp)
        addi    sp, sp, 4
        ldw     r19, 0(sp)
        addi    sp, sp, 4
        ldw     r18, 0(sp)
        addi    sp, sp, 4
        ldw     r17, 0(sp)
        addi    sp, sp, 4
        ldw     r16, 0(sp)
        /* END - EPILOGO */

        ret

    ACENDER_LED:
        ldwio   r19, 0(r16)          /* LER ESTADO DOS LEDS */
        addi    r20, r0, 1           /* inicializa a mascara como 0b0001 */
        sll     r20, r20, r18        /* leva o digito 1 para a casa binaria correta */
        or      r19, r19, r20        /* estados_dos_leds OR mascara => acende o led */
        stwio   r19, 0(r16)          /* escreve o estado dos leds atualizado */

        /* START - EPILOGO */
        ldw     r20, 0(sp)
        addi    sp, sp, 4
        ldw     r19, 0(sp)
        addi    sp, sp, 4
        ldw     r18, 0(sp)
        addi    sp, sp, 4
        ldw     r17, 0(sp)
        addi    sp, sp, 4
        ldw     r16, 0(sp)
        /* END - EPILOGO */

        ret

/* END TRATAR LED */
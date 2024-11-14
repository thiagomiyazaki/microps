/*
PROJETO FINAL DE MICROPROCESSADORES

r8 ... r15  CALEE-SAVED (caller pode usar tranquilo)
r16 ... r23 CALLER-SAVED (callee pode usar tranquilo)
*/

.equ LEFTMOST_LED_R_ON,  0x20000
.equ INIT_STACK,         0x30000
.equ DATA_LEDS_R,        0x10000000
.equ UART_DATA_REG,      0x10001000
.equ UART_CONTROL_REG,   0x10001004
.equ SWITCHES_REG,       0x10000040
.equ PUSHBTN,            0x10000050
.equ TIMER_STATUS_REG,   0x10002000

.org 0x20
    /* START - PROLOGO */
    stw     r8, 0(sp)
    subi    sp, sp, 4
    stw     r9, 0(sp)
    subi    sp, sp, 4
    stw     r10, 0(sp)
    subi    sp, sp, 4
    stw     ra, 0(sp)
    /* END - PROLOGO */
    
    rdctl   et, ipending              /* checa se houve interrupcao */
    subi    ea, ea, 4                 /* decrementa ea para retornar corretamente ao main */

    andi    r8, et, 0b0001            /* aplica mascara para pegar valor do b0 (IRQ #0) */
    beq     r8, r0, OTHER_INTERRUPTS  /* se nao foi, ir para outras interrupcoes */
    call    EXT_IRQ0                  /* chamar rotina para tratar IRQ #0 (TIMER) */
    br      END_HANDLER

OTHER_INTERRUPTS:
    /* se chegou aqui, e é interrupção, então é interrup de pushbtn e não de interval timer */

    /* START PROLOGO */
    stw     ra, 0(sp)
    subi    sp, sp, 4
    /* END PROLOGO */

    call _pushbtn_interrups

    /* START EPILOGO */
    addi    sp, sp, 4
    ldw     ra, 0(sp)
    /* END EPILOGO */

    br END_HANDLER

END_HANDLER:
    /* START - EPILOGO */
    ldw     ra, 0(sp)
    addi    sp, sp, 4
    ldw     r10, 0(sp)
    addi    sp, sp, 4
    ldw     r9, 0(sp)
    addi    sp, sp, 4
    ldw     r8, 0(sp)
    /* END - EPILOGO */
    eret

EXT_IRQ0:
    beq     r23, r0, SKIP_CRONOMETRO
    /* START PROLOGO */
    stw     ra, 0(sp)
    subi    sp, sp, 4
    /* END PROLOGO */
    movia   r8, TIMER_STATUS_REG
    stwio   r0, 0(r8)                       /* limpa bit de timeout */
    call    _interrups_cronometro
    /* START EPILOGO */
    addi    sp, sp, 4
    ldw     ra, 0(sp)
    /* END EPILOGO */
    ret

    SKIP_CRONOMETRO:

    /* TRATAMENTO DA ANIMACAO */
    movia   r8, TIMER_STATUS_REG
    stwio   r0, 0(r8)                       /* limpa bit de timeout */
    movia   r8, DATA_LEDS_R                 /* pega o endereco do DATA REG dos LEDS R */ 
    ldwio   r9, 0(r8)                       /* pega o estado dos leds */

    /* VERIFICA SW0 (SWITCH b0) */
    movia   r10, SWITCHES_REG       /* pega o estado dos switches */
    ldwio   r10, 0(r10)
    beq     r10, r0, SWITCH_OFF     /* se o estado == 0 -> nao ligado */

    SWITCH_ON:
        /* entra aqui se o switch esta ligado */
        movia   r10, 0b0001
        beq     r9, r10, REINICIAR_SEQUENCIA    /* se b0 == 1 -> reinicia sequencia */
        srli    r9, r9, 1       /* shift right de 1 bit */
        stwio   r9, 0(r8)           /* escreve o novo estado dos leds */
        ret

    SWITCH_OFF:
        movia   r10, LEFTMOST_LED_R_ON          /* pega o estado dos leds R quando o led mais à esq está ligado */ 
        beq     r9, r10, REINICIAR_SEQUENCIA    /* se o ultimo led esta ligado, devemos reiniciar a sequencia  */
        slli    r9, r9, 1           /* shift left de 1 bit */
        stwio   r9, 0(r8)           /* escreve o novo estado dos leds */
        ret

    REINICIAR_SEQUENCIA:
        movia   r10, SWITCHES_REG               
        ldwio   r10, 0(r10)                     /* pega o estado dos switches */
        beq     r10, r0, RESTART_SWITCH_OFF     /* se o estado == 0 -> nao ligado */

        RESTART_SWITCH_ON:
            movia   r9, LEFTMOST_LED_R_ON   /* liga o LED b17 */
            stwio   r9, 0(r8)               /* escreve o novo estado dos leds */
            ret

        RESTART_SWITCH_OFF:
            addi    r9, r0, 0b0001      /* liga o LED b0 */
            stwio   r9, 0(r8)           /* escreve o novo estado dos leds */
            ret

.global _start
_start:
    /* HABILITAR INTERRUPCOES */
    /* HABILITAR INTERRUPCOES NO PROCESSADOR */
    addi    r8, r0, 1       /* define constante = 1 (0001) */
    wrctl   status, r8      /* habilita interrupcoes no processador */

    /* HABILITAR INTERRUPCOES NO IENABLE */
    movia   r8, 0b0011      /* habilita INTERVAL TIMER e PUSHBTN (IRQs #1 e #2) */
    wrctl   ienable, r8

    /* HABILITAR KEY2 EM PUSHBTN */
    movia   r8, PUSHBTN
    movi    r9, 0b0010       /* bit referente a KEY1 */
    stwio   r9, 8(r8)        /* habilita interrupcoes no key1 no pushbutton */

    movia sp, INIT_STACK
    movia r14, COMANDO                       /* pega o endereco do inicial do comando e armazena em 14 */

    movia r4, ASK_COMMAND_STRING
    call  write_string

    movia   r8, UART_DATA_REG
    POLLING_LEITURA:
        movia  r12, 0x0A     	            /* codigo ASCII do LF (ENTER) */

        ldwio  r9, 0(r8)                    /* copia o valor em DATA_REG para r8 */
        andi   r10, r9, 0x8000              /* aplica a mascara e pega o resultado */
        beq    r10, r0, POLLING_LEITURA     /* se o resultado for igual a zero, 
                                            nao ha nada para ler, voltar */
        andi   r11, r9, 0xff                /* guarda o dado de leitura */
        stw    r11, 0(r14)                  /* coloca o dado no stack */
        addi   r14, r14, 4                  /* avanca o stack em 01 word */
        beq    r11, r12, REDIRECTION        /* se o dado for igual a ENTER (0A) ir para REDIRECTION */
        br     POLLING_LEITURA

    REDIRECTION:    /* 20 / 21*/
        movia   r4, COMANDO     /* aponta para o endereco do codigo do comando */
        ldw     r8, 0(r4)       /* pega o primeiro caractere do comando */

        addi    r9, r0, 0x30    /* numero 0 em ASCII CODE */
        addi    r10, r0, 0x31   /* numero 1 em ASCII CODE */
        addi    r11, r0, 0x32   /* numero 2 em ASCII CODE */

        beq     r8, r9,  TRATAR_LED         /* se r8 == 0 -> tratar led */
        beq     r8, r10, TRATAR_ANIMACAO    /* se r8 == 1 -> tratar animacao */
        beq     r8, r11, TRATAR_CRONOMETRO  /* se r8 == 2 -> tratar cronometro */

        br _start

    END:
        br END

TRATAR_LED:
    call _tratar_led
    br   _start

TRATAR_ANIMACAO:
    call _tratar_animacao
    br   _start

TRATAR_CRONOMETRO:
    call _tratar_cronometro
    br  _start


/* escreve uma string no console do UART ("Digite o codigo do comando: ") */
write_string:
    /* 
    argumentos:
        r4 : endereco inicial de leitura (primeiro caractere)
    */
    movia   r10, UART_CONTROL_REG
    movia   r12, UART_DATA_REG
    POLLING_ESCRITA:
        ldwio  r8, 0(r10)                   /* copia o valor de CONTROL_REG */
        andhi  r9, r13, 0xFFFF              /* aplica a mascara para verificar WSPACE */
        bne    r9, r0, POLLING_ESCRITA      /* se n houver espaco no buffer, volte */

        ldb    r11, 0(r4)                    /* carrega chars */
        beq    r11, r0, RET_STR              /* se achou o zero entao acabou a string */
        stwio  r11, 0(r12)                   /* escreve o dado em DATA de DATA_REG */
        addi   r4, r4, 1

        br POLLING_ESCRITA
    
    RET_STR:
        ret

.org 0x10000
.global COMANDO
COMANDO:
    .skip 6*4

.global ASK_COMMAND_STRING
ASK_COMMAND_STRING:
    .asciz "Digite o codigo do comando: \n"

.global COD_7SEG
COD_7SEG:
    .byte 0b00111111, 0b00000110, 0b01011011, 0b01001111, 0b01100110, 0b01101101, 0b01111101, 0b00000111, 0b01111111, 0b01100111

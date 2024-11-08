/*
PROJETO FINAL DE MICROP


*/

/*
while True {

    exibe Entre com o comando

    comando = pegaComando()

    switch (comando):

    case 0:

    TRATA_LED()

    case 1:

    TRATA_ANIMACAO()

    case 2: 

    TRATA_CRONOMETRO()

}

r8 ... r15  CALEE-SAVED (caller pode usar tranquilo)
r16 ... r23 CALLER-SAVED (callee pode usar tranquilo)
*/

/*
TRATADOR DE INTERRUPCAO
10 ENTER
SHIFT LEFT E WRITE 
*/

.equ DATA_LEDS_R,        0x10000000
.equ UART_DATA_REG,      0x10001000
.equ UART_CONTROL_REG,   0x10001004
.equ TIMER_STATUS_REG,   0x10002000
.equ SWITCHES_REG,       0x10000040
.equ LEFTMOST_LED_R_ON,  0x20000
.equ INIT_STACK,         0x30000

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
    beq     et, r0, OTHER_EXCEPTIONS  /* se ipending == 0, nao houve interrupcao logo excecao */
    subi    ea, ea, 4                 /* decrementa ea para retornar corretamente ao main */

    andi    r8, et, 0b0001            /* aplica mascara para pegar valor do b0 (IRQ #0) */
    beq     r8, r0, OTHER_INTERRUPTS  /* se nao foi, ir para outras interrupcoes */
    call    EXT_IRQ0                  /* chamar rotina para tratar IRQ #0 (TIMER) */

OTHER_INTERRUPTS:
    /* adicione outros tratamentos de interrupcao aqui */
    br      END_HANDLER

OTHER_EXCEPTIONS:
    /* adicione aqui codigo para lidar com excecoes */

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
    call    _interrups_cronometro
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
        movia   r10, SWITCHES_REG               /* pega o estado dos switches */
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

/* só coloquei as funcoes aqui para testar o redirecionamento, no projeto final é melhor
   separar em arquivos diferentes */

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

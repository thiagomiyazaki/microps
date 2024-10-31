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

.equ UART_DATA_REG,      0x10001000
.equ UART_CONTROL_REG,   0x10001004
.equ INIT_STACK,         0x30000

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

    REDIRECTION:
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
    br TRATAR_CRONOMETRO


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

.org 0x10000
.global COMANDO
COMANDO:
    .skip 6*4

.global ASK_COMMAND_STRING
ASK_COMMAND_STRING:
    .asciz "Digite o codigo do comando: \n"

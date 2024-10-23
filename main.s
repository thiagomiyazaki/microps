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

.equ UART_DATA_REG,      0x10001000
.equ UART_CONTROL_REG,   0x10001004
.equ STACK,              0x10000

.global _start
_start:
    movia	sp, STACK                       /* pega o endereco do stack e coloca em sp */

    movia r4, ASK_COMMAND_STRING
    call write_string

    movia   r8, UART_DATA_REG
    POLLING_LEITURA:
        movia  r12, 0x0A     	            /* codigo ASCII do LF (ENTER) */

        ldwio  r9, 0(r8)                    /* copia o valor em DATA_REG para r8 */
        andi   r10, r9, 0x8000              /* aplica a mascara e pega o resultado */
        beq    r10, r0, POLLING_LEITURA     /* se o resultado for igual a zero, 
                                            nao ha nada para ler, voltar */
        andi   r11, r9, 0xff                /* guarda o dado de leitura */
        stw    r11, 0(sp)                   /* coloca o dado no stack */
        addi   sp, sp, 4                    /* avanca o stack em 01 word */
        beq    r11, r12, REDIRECTION        /* se o dado for igual a ENTER (0A) ir para REDIRECTION */
        br     POLLING_LEITURA

    REDIRECTION:
        movia   sp, STACK
        movia   r4, STACK   /* aponta para o endereco do codigo do comando */
        ldw     r8, 0(r4)   /* pega o primeiro caractere do comando */

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
    br TRATAR_LED

TRATAR_ANIMACAO:
    br TRATAR_ANIMACAO

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


.global ASK_COMMAND_STRING
ASK_COMMAND_STRING:
    .asciz "Digite o codigo do comando: "

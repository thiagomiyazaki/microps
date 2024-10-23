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
*/

.equ UART_DATA_REG,      0x10001000
.equ UART_CONTROL_REG,   0x10001004

.global _start
_start:
    movia r4, ASK_COMMAND_STRING
    call write_string
    END:
        br END


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

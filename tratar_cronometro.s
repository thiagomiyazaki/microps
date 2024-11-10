/* START - TRATAR CRONOMETRO */

.equ END_7SEG_DISPLAY,  0x10000020
.equ TIMER_STATUS_REG,  0x10002000

.global _tratar_cronometro
_tratar_cronometro:
    /* START - PROLOGO */
    stw     r16, 0(sp)
    subi    sp, sp, 4
    stw     r17, 0(sp)
    subi    sp, sp, 4
    stw     ra,  0(sp)
    subi    sp, sp, 4
    /* END - PROLOGO */

    /* VERIFICAR SE É PARA INICIAR OU PARAR O CRONOMETRO / 20 INICIAR e 21 CANCELA */
    ldw     r16, 4(r4)                    /* pegar o bit menos significativo do comando */
    subi    r16, r16, 0x30                /* subtrair 0x30 para converter ASCII -> decimal */
    beq     r16, r0, INICIAR_CRONOMETRO   /* se o segundo digito for igual a zero, iniciar cronometro */
    br      CANCELAR_CRONOMETRO              /* caso não seja, parar cronometro */

    INICIAR_CRONOMETRO:
        /* CONFIGURAR O TIMER PARA INICIAR A CONTAGEM */
        movia   r16, TIMER_STATUS_REG
        
        /* setar o valor de contagem --> 50 000 000 == 0x02FA F080 */
        movia   r17, 0x9680     /* parte baixa de 50 000 000*/
        stwio   r17, 8(r16)     /* escreve parte baixa  */
        movia   r17, 0x0098     /* parte alta de 50 000 000*/
        stwio   r17, 12(r16)    /* escreve parte alta  */

        movia   r17, 0b0111     /* habilita interrups, habilita reset, e inicia contagem */
        stwio   r17, 4(r16)     /* escreve no status reg do timer */

        addi    r23, r0, 1      /* INDICA PARA O TRATADOR DE INTERRUPS QUE O JOB ATUAL É DE CRONOMETRO */

        /* ZERAR OS REGISTRADORES QUE REPRESENTAM AS UNIDADES */
        mov     r19, r0     /* r19 - _ _ _ X */
        mov     r20, r0     /* r20 - _ _ X _ */
        mov     r21, r0     /* r21 - _ X _ _ */
        mov     r22, r0     /* r22 - X _ _ _ */

        call _write_to_display

        /* START - EPILOGO */
        addi    sp, sp, 4
        ldw     ra,  0(sp)
        addi    sp, sp, 4
        ldw     r17, 0(sp)
        addi    sp, sp, 4
        ldw     r16, 0(sp)
        /* END - EPILOGO */

        ret

    CANCELAR_CRONOMETRO:
    /* CONFIGURAR O TIMER PARA INTERROMPER A CONTAGEM */
        /* START - EPILOGO */
        addi    sp, sp, 4
        ldw     ra,  0(sp)
        addi    sp, sp, 4
        ldw     r17, 0(sp)
        addi    sp, sp, 4
        ldw     r16, 0(sp)
        /* END - EPILOGO */

        ret

/* ESTA FUNÇÃO LÊ O REGISTRADORES RELATIVOS AOS DIGITOS, MONTA A WORD E ESCREVE NO DISPLAY*/
.global _write_to_display
_write_to_display:
    /*
        r22 - X _ _ _
        r21 - _ X _ _
        r20 - _ _ X _ 
        r19 - _ _ _ X
    */

    /* START - PROLOGO */
    stw     r16, 0(sp)
    subi    sp, sp, 4
    stw     r17, 0(sp)
    subi    sp, sp, 4
    stw     r18, 0(sp)
    subi    sp, sp, 4
    stw     ra,  0(sp)
    /* END - PROLOGO */

    mov     r16, r0         /* zerar o registrador r16 - nele vamos escrever o estado final a ser escrito no display */

    /* PRIMEIRO DIGITO */
    movia   r17, COD_7SEG   /* pega o endereço do mapeamento entre código binário e letra (desenho) do display      */
    mov     r18, r19        /* pega o número em r19 e guarda em r18 para poder manipular o valor preservando r19    */
    add     r17, r17, r18   /* soma o valor decimal com o binário e utiliza como offset para pegar o byte adequado  */
    ldb     r17, 0(r17)     /* pega o byte com o codigo correto para incluir no display de 7 segmentos              */

    or      r16, r16, r17   /* 0x000000XX - vamos escrever r19 no primeiro byte */

    /* SEGUNDO DIGITO */
    movia   r17, COD_7SEG   /* pega o endereço do mapeamento entre código binário e letra (desenho) do display      */
    mov     r18, r20        /* pega o número em r20 e guarda em r18 para poder manipular o valor preservando r20    */
    add     r17, r17, r18   /* soma o valor decimal com o binário e utiliza como offset para pegar o byte adequado  */
    ldb     r17, 0(r17)     /* pega o byte com o codigo correto para incluir no display de 7 segmentos              */

    slli    r17, r17, 8     /* 0xXX --> 0x0000XX00  */
    or      r16, r16, r17   /* 0x0000XX00 - vamos escrever r20 no segundo byte */

    /* TERCEIRO DIGITO */
    movia   r17, COD_7SEG   /* pega o endereço do mapeamento entre código binário e letra (desenho) do display      */
    mov     r18, r21        /* pega o número em r21 e guarda em r18 para poder manipular o valor preservando r21    */
    add     r17, r17, r18   /* soma o valor decimal com o binário e utiliza como offset para pegar o byte adequado  */
    ldb     r17, 0(r17)     /* pega o byte com o codigo correto para incluir no display de 7 segmentos              */

    slli    r17, r17, 16     /* 0xXX --> 0x00XX0000  */
    or      r16, r16, r17   /* 0x00XX0000 - vamos escrever r21 no segundo byte */

    /* QUARTO DIGITO */
    movia   r17, COD_7SEG   /* pega o endereço do mapeamento entre código binário e letra (desenho) do display      */
    mov     r18, r22        /* pega o número em r22 e guarda em r18 para poder manipular o valor preservando r22    */
    add     r17, r17, r18   /* soma o valor decimal com o binário e utiliza como offset para pegar o byte adequado  */
    ldb     r17, 0(r17)     /* pega o byte com o codigo correto para incluir no display de 7 segmentos              */

    slli    r17, r17, 24     /* 0xXX --> 0xXX000000  */
    or      r16, r16, r17   /* 0xXX000000 - vamos escrever r22 no segundo byte */

    /* ESCREVE NO DISPLAY */
    movia   r17, END_7SEG_DISPLAY   /* pega o endereço do display de 7-segmentos */
    stwio   r16, 0(r17)             /* escreve a palavra que escrevemos com muito suor :( */

    /* START - EPILOGO */
    ldw     ra,  0(sp)
    addi    sp, sp, 4
    ldw     r18, 0(sp)
    addi    sp, sp, 4
    ldw     r17, 0(sp)
    addi    sp, sp, 4
    ldw     r16, 0(sp)
    /* END - EPILOGO */

    ret

.global _interrups_cronometro
_interrups_cronometro:
    /* START - PROLOGO */
    stw     ra, 0(sp)
    subi    sp, sp, 4
    /* END - PROLOGO*/
    call _somar_unidade
    call _write_to_display
    /* START - EPILOGO */
    addi    sp, sp, 4
    ldw     ra, 0(sp)
    /* END - EPILOGO */
    ret

.global _somar_unidade
_somar_unidade:
    /* START - PROLOGO */
    stw     ra,  0(sp)
    subi    sp, sp, 4
    stw     r16, 0(sp)
    /* END - PROLOGO */

    addi    r19, r19, 1     /* soma 1 a r19 - o registrador que armazena as unidades */
    addi    r16, r0, 10     /* define r16 como 10 - valor utlizado para comparacao */

    beq     r19, r16, OVERFLOW_UNIDADE      /* se r19 == 10 entao há overflow e temos que zerar o valor */
    /* rumo normal sem overflow */
    /* START - EPILOGO */
    ldw     r16, 0(sp)
    addi    sp, sp, 4
    ldw     ra,  0(sp)
    /* END - EPILOGO */

    ret

    OVERFLOW_UNIDADE:
        mov     r19, r0         /* zerar o registrador relativo a unidades */
        call    _somar_dezena   /* tenta adicionar um na casa das dezenas */
        /* START - EPILOGO */
        ldw     r16, 0(sp)
        addi    sp, sp, 4
        ldw     ra,  0(sp)
        /* END - EPILOGO */

        ret

.global _somar_dezena
_somar_dezena:
    /* START - PROLOGO */
    stw     ra,  0(sp)
    subi    sp, sp, 4
    stw     r16, 0(sp)
    /* END - PROLOGO */

    addi    r20, r20, 1     /* soma 1 a r20 - o registrador que armazena as unidades */
    addi    r16, r0, 10     /* define r16 como 10 - valor utlizado para comparacao */

    beq     r20, r16, OVERFLOW_DEZENA      /* se r20 == 10 entao há overflow e temos que zerar o valor */
    /* rumo normal sem overflow */
    /* START - EPILOGO */
    ldw     r16, 0(sp)
    addi    sp, sp, 4
    ldw     ra,  0(sp)
    /* END - EPILOGO */

    ret

    OVERFLOW_DEZENA:
        mov     r20, r0          /* zerar o registrador relativo a unidades */
        call    _somar_centena   /* tenta adicionar um na casa das dezenas */
        /* START - EPILOGO */
        ldw     r16, 0(sp)
        addi    sp, sp, 4
        ldw     ra,  0(sp)
        /* END - EPILOGO */

        ret

.global _somar_centena
_somar_centena:
    /* START - PROLOGO */
    stw     ra,  0(sp)
    subi    sp, sp, 4
    stw     r16, 0(sp)
    /* END - PROLOGO */

    addi    r21, r21, 1     /* soma 1 a r21 - o registrador que armazena as unidades */
    addi    r16, r0, 10     /* define r16 como 10 - valor utlizado para comparacao */

    beq     r21, r16, OVERFLOW_CENTENA      /* se r21 == 10 entao há overflow e temos que zerar o valor */
    /* rumo normal sem overflow */
    /* START - EPILOGO */
    ldw     r16, 0(sp)
    addi    sp, sp, 4
    ldw     ra,  0(sp)
    /* END - EPILOGO */

    ret

    OVERFLOW_CENTENA:
        mov     r21, r0          /* zerar o registrador relativo a unidades */
        call    _somar_milhar   /* tenta adicionar um na casa das dezenas */
        /* START - EPILOGO */
        ldw     r16, 0(sp)
        addi    sp, sp, 4
        ldw     ra,  0(sp)
        /* END - EPILOGO */

        ret

.global _somar_milhar
_somar_milhar:
    /* START - PROLOGO */
    stw     ra,  0(sp)
    subi    sp, sp, 4
    stw     r16, 0(sp)
    /* END - PROLOGO */

    addi    r22, r22, 1     /* soma 1 a r22 - o registrador que armazena as unidades */
    addi    r16, r0, 10     /* define r16 como 10 - valor utlizado para comparacao */

    beq     r22, r16, OVERFLOW_MILHAR      /* se r21 == 10 entao há overflow e temos que zerar o valor */
    /* rumo normal sem overflow */
    /* START - EPILOGO */
    ldw     r16, 0(sp)
    addi    sp, sp, 4
    ldw     ra,  0(sp)
    /* END - EPILOGO */

    ret

    OVERFLOW_MILHAR:
        mov     r22, r0          /* zerar o registrador relativo a unidades */

        /* START - EPILOGO */
        ldw     r16, 0(sp)
        addi    sp, sp, 4
        ldw     ra,  0(sp)
        /* END - EPILOGO */
        
        ret

/* END - TRATAR CRONOMETRO */
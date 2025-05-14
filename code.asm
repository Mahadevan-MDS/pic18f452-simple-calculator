#include "p18f452.inc"
; RC0-REG SELECT, RC1-READ/WRITE, RC2-ENABLE
	 CONFIG OSC = HS
	 CONFIG WDT = OFF
	 CONFIG LVP = OFF
       
	 ORG 0H
	 GOTO MAIN
       
HIGH_ISR ORG 08H
	 BTFSC INTCON, RBIF
	 BRA RBIF_ISR
	 RETFIE
	 
;---------------------------------DISPLAY---------------------------------------------------------------------------------------------------
SNDDATA	 BSF PORTC,0
         CALL LDELAY
         BSF PORTC,2
         CALL LDELAY
         MOVFF DISPVAL, PORTD
         CALL LDELAY
         BCF PORTC,2
         CALL LDELAY
         RETURN

SNDCMD	 BCF PORTC,0
         CALL LDELAY
         BSF PORTC,2
         CALL LDELAY
         MOVFF DISPVAL, PORTD
         CALL LDELAY
         BCF PORTC,2
         CALL LDELAY
         RETURN

DISPINIT MOVLW 38H	;STAGE 0
	 MOVWF DISPVAL
	 CALL SNDCMD
	 MOVLW 0CH
	 MOVWF DISPVAL
	 CALL SNDCMD
	 MOVLW 01H
	 MOVWF DISPVAL
	 CALL SNDCMD
	 CALL CLEARDISP
	 MOVLW 07H
	 MOVWF TBLPTRH
	 MOVLW 00H
	 MOVWF TBLPTRL
L11   	 TBLRD*+
	 MOVF TABLAT,W
	 BZ H11
	 MOVWF DISPVAL
	 CALL SNDDATA
	 BRA L11
H11   	 CALL PAUSE
	 MOVLW 1H
	 MOVWF DISPVAL
	 CALL SNDCMD
	 BRA EQ
       
CLEARDISP MOVLW 1H
         MOVWF DISPVAL
         CALL SNDCMD
         MOVLW 80H
         MOVWF DISPVAL
         CALL SNDCMD
         CALL LDELAY
         RETURN
       
;-----------------------------KEYPAD---------------------------------------------------------------------------------------------------------
KEYINIT	 BCF INTCON2, RBPU
	 MOVLW 0XF0
	 MOVWF TRISB
	 MOVWF PORTB
KEYOPEN	 CPFSEQ PORTB
	 GOTO KEYOPEN
	 MOVLW 0H
	 MOVWF TBLPTRU
	 MOVLW 06H
	 MOVWF TBLPTRH
	 BSF INTCON, RBIE
	 BSF INTCON, GIE
LOOP     GOTO LOOP

RBIF_ISR CALL LDELAY
	 MOVFF PORTB, KEYCOL
	 MOVLW 0XFE	;ROW0
	 MOVWF PORTB
	 CPFSEQ PORTB
	 BRA ROW0
	 MOVLW 0XFD	;ROW1
	 MOVWF PORTB
	 CPFSEQ PORTB
	 BRA ROW1
	 MOVLW 0XFB	;ROW2
	 MOVWF PORTB
	 CPFSEQ PORTB
	 BRA ROW2
	 MOVLW 0XF7	;ROW3
	 MOVWF PORTB
	 CPFSEQ PORTB
	 BRA ROW3
	 GOTO BAD_RBIF
ROW0	 MOVLW 00H
	 BRA FIND
ROW1	 MOVLW 04H
	 BRA FIND
ROW2	 MOVLW 08H
	 BRA FIND
ROW3	 MOVLW 0CH
	 BRA FIND
FIND	 MOVWF TBLPTRL
	 MOVLW 0XF0
	 XORWF KEYCOL
	 SWAPF KEYCOL,F
A4	 RRCF KEYCOL
	 BC MATCH
	 INCF TBLPTRL
	 BRA A4
MATCH	 TBLRD*+
	 MOVLW '='
	 CPFSEQ TABLAT
	 BRA G
	 BRA EQ
G	 MOVLW 'C'
	 CPFSEQ TABLAT
	 BRA G1
	 CALL CC
	 BRA KEYINIT
G1	 MOVFF TABLAT,DISPVAL
	 CALL HDELAY
	 CALL SNDDATA
	 CALL ASSIGN
WAIT     MOVLW 0XF0
	 MOVWF PORTB
	 CPFSEQ PORTB
	 BRA WAIT
	 BCF INTCON, RBIF
	 RETFIE
BAD_RBIF MOVLW 0H
	 GOTO WAIT
	 
;---------------------------DELAY-----------------------------------------------------------------------------------------------------------------
LDELAY   MOVLW 01H		;Low Delay
         MOVWF T0CON
         MOVLW 0XFC
         MOVWF TMR0H
         MOVLW 0XAF
         MOVWF TMR0L
         BCF INTCON, TMR0IF
         BSF T0CON, TMR0ON
A1 	 BTFSS INTCON, TMR0IF
         BRA A1
         BCF T0CON, TMR0ON
         RETURN

HDELAY   MOVLW 04H		;High Delay
         MOVWF T0CON
         MOVLW 0XF0
         MOVWF TMR0H
         MOVLW 0X69
         MOVWF TMR0L
         BCF INTCON, TMR0IF
         BSF T0CON, TMR0ON
A2 	 BTFSS INTCON, TMR0IF
         BRA A2
         BCF T0CON, TMR0ON
         RETURN
	 
PAUSE    MOVLW 06H		;Pause
         MOVWF T0CON
         MOVLW 0X00
         MOVWF TMR0H
         MOVLW 0X00
         MOVWF TMR0L
         BCF INTCON, TMR0IF
         BSF T0CON, TMR0ON
A3 	 BTFSS INTCON, TMR0IF
         BRA A3
         BCF T0CON, TMR0ON
         RETURN

;-----------------------------SPL.FUNCTION KEYS-----------------------------------------------------------------------------------------------------------

;**************************EQUAL KEY********************************************************************************************************
EQ       MOVLW 0H
         CPFSEQ STAGE
	 BRA NS0
	 BRA S0
NS0   	 MOVLW 1H
	 CPFSEQ STAGE
	 BRA NS1
	 BRA S1
NS1	 MOVLW 2H
	 CPFSEQ STAGE
	 BRA NS2
	 BRA S2
NS2   	 MOVLW 3H
	 CPFSEQ STAGE
	 BRA NS3
	 BRA S3
NS3   	 BRA S4
S0    	 CALL CLEARDISP
	 INCF STAGE,F
	 BRA NUM1
S1    	 CALL CLEARDISP
	 INCF STAGE,F
	 BRA NUM2
S2    	 CALL CLEARDISP
	 INCF STAGE,F
	 BRA OPER
S3    	 CALL CLEARDISP
	 INCF STAGE,F
	 BRA RESULT
S4    	 CALL CLEARDISP
	 CLRF STAGE
	 BRA DISPINIT

;**************************CLEAR KEY********************************************************************************************************
CC    	 MOVLW 10H
	 MOVWF DISPVAL
	 CALL SNDCMD
	 MOVLW ' '
	 MOVWF DISPVAL
	 CALL SNDDATA
	 MOVLW 10H
	 MOVWF DISPVAL
	 CALL SNDCMD
	 RETURN
;-----------------------------ALU-----------------------------------------------------------------------------------------------------------   
;****************ASSIGN**********************************************************************************************************************
ASSIGN 	 MOVLW 0H
	 CPFSEQ STAGE
	 BRA NSS0
	 RETURN
NSS0   	 MOVLW 1H
	 CPFSEQ STAGE
	 BRA NSS1
	 MOVF DISPVAL,W
	 MOVWF N1
	 CALL CHKCHAR1
	 MOVLW 30H
	 SUBWF N1,F
	 RETURN
NSS1  	 MOVLW 2H
	 CPFSEQ STAGE
	 BRA NSS2
	 MOVF DISPVAL,W
	 MOVWF N2
	 CALL CHKCHAR2
	 MOVLW 30H
	 SUBWF N2,F
	 RETURN
NSS2  	 MOVLW 3H
	 CPFSEQ STAGE
	 BRA NSS3
	 MOVF DISPVAL,W
	 MOVWF OP
	 CALL OPERATION
	 RETURN
NSS3  	 RETURN
	 
;****************OPERATION*********************************************************************************************************************
OPERATION MOVLW '+'
	 CPFSEQ OP
	 BRA NSSS0
	 CALL ADD
	 RETURN
NSSS0  	 MOVLW '-'
	 CPFSEQ OP
	 BRA NSSS1
	 CALL SUBTRACT
	 RETURN
NSSS1  	 MOVLW '*'
	 CPFSEQ OP
	 BRA NSSS2
	 CALL MULTIPLY
	 RETURN
NSSS2    MOVLW '/'
	 CPFSEQ OP
	 BRA NSSS3
	 CALL DIVIDE
	 RETURN
NSSS3  	 BRA BAD_OP 
	 RETURN

;****************CHAR-CHECK*********************************************************************************************************************
CHKCHAR1 MOVLW '+'
	 CPFSEQ N1
	 BRA CHK11
	 BRA BAD_OP
	 RETURN
CHK11    MOVLW '-'
	 CPFSEQ N1
	 BRA CHK21
	 BRA BAD_OP
	 RETURN
CHK21    MOVLW '*'
	 CPFSEQ N1
	 BRA CHK31
	 BRA BAD_OP
	 RETURN
CHK31    MOVLW '/'
	 CPFSEQ N1
	 BRA CHK41
	 BRA BAD_OP
	 RETURN
CHK41    RETURN

CHKCHAR2 MOVLW '+'
	 CPFSEQ N2
	 BRA CHK12
	 BRA BAD_OP
	 RETURN
CHK12    MOVLW '-'
	 CPFSEQ N2
	 BRA CHK22
	 BRA BAD_OP
	 RETURN
CHK22    MOVLW '*'
	 CPFSEQ N2
	 BRA CHK32
	 BRA BAD_OP
	 RETURN
CHK32    MOVLW '/'
	 CPFSEQ N2
	 BRA CHK42
	 BRA BAD_OP
         RETURN
CHK42    RETURN        
      
;****************MAIN ALU*********************************************************************************************************************      
ADD      MOVF N1,W
	 ADDWF N2,W
	 DAW
	 MOVWF RESH
	 SWAPF RESH,F
	 MOVWF RESL
	 MOVLW 0X0F
	 ANDWF RESL,F
	 ANDWF RESH,F
	 RETURN
      
SUBTRACT MOVF N1,W
	 CPFSGT N2
	 BRA LT
	 SUBWF N2,W
	 MOVWF RESL
	 MOVLW '-'
	 MOVWF RESH
	 BRA SUBDONE
LT    	 MOVF N2,W
	 SUBWF N1,W
	 MOVWF RESL	
SUBDONE  RETURN

MULTIPLY MOVLW 0H
MUL1  	 ADDWF N2,W
	 DAW
	 DECF N1,F
	 BNZ MUL1
	 MOVWF RESH
	 SWAPF RESH,F
	 MOVWF RESL
	 MOVLW 0X0F
	 ANDWF RESL,F
	 ANDWF RESH,F
	 RETURN

DIVIDE 	 MOVLW 0H
	 MOVWF RESL
	 CPFSEQ N2
	 BRA GOO
	 CALL LDELAY
	 BRA BAD_OP
GOO   	 MOVF N2,W
DIV      CPFSLT N1
	 BRA DIV1
	 BRA DIVDONE
DIV1  	 SUBWF N1,F
	 INCF RESL,F
	 BRA DIV
DIVDONE  RETURN
;****************BAD OPERATION*********************************************************************************************************************
BAD_OP   CALL CLEARDISP
	 CLRF STAGE
	 MOVLW 07H		;STAGE 3
	 MOVWF TBLPTRH
	 MOVLW 80H
	 MOVWF TBLPTRL
L2B   	 TBLRD*+
	 MOVF TABLAT,W
	 BZ H2B
	 MOVWF DISPVAL
	 CALL SNDDATA
	 BRA L2B
      
H2B   	 CALL PAUSE
	 BRA EQ
;****************FIRST NUM*******************************************************************************************************************
NUM1  	 MOVLW 07H		;STAGE 1
	 MOVWF TBLPTRH
	 MOVLW 20H
	 MOVWF TBLPTRL
L21   	 TBLRD*+
	 MOVF TABLAT,W
	 BZ H21
	 MOVWF DISPVAL
	 CALL SNDDATA
	 BRA L21
      
H21  	 MOVLW 0XC0
	 MOVWF DISPVAL
	 CALL SNDCMD
	 CALL LDELAY
	 CALL KEYINIT

;****************SECOND NUM*******************************************************************************************************************
NUM2  	 MOVLW 07H		;STAGE 2
	 MOVWF TBLPTRH
	 MOVLW 40H
	 MOVWF TBLPTRL
L22   	 TBLRD*+
	 MOVF TABLAT,W
	 BZ H22
	 MOVWF DISPVAL
	 CALL SNDDATA
	 BRA L22
      
H22   	 MOVLW 0XC0
	 MOVWF DISPVAL
	 CALL SNDCMD
	 CALL LDELAY
	 CALL KEYINIT

;****************OPERATOR*******************************************************************************************************************
OPER  	 MOVLW 07H		;STAGE 3
	 MOVWF TBLPTRH
	 MOVLW 60H
	 MOVWF TBLPTRL
L23   	 TBLRD*+
	 MOVF TABLAT,W
	 BZ H23
	 MOVWF DISPVAL
	 CALL SNDDATA
	 BRA L23
      
H23   	 MOVLW 0XC0
	 MOVWF DISPVAL
	 CALL SNDCMD
	 CALL LDELAY
	 CALL KEYINIT

;****************RESULT*******************************************************************************************************************
RESULT 	 MOVLW 08H	;STAGE 4
	 MOVWF TBLPTRH
	 MOVLW 00H
	 MOVWF TBLPTRL
L24   	 TBLRD*+
	 MOVF TABLAT,W
	 BZ H24
	 MOVWF DISPVAL
	 CALL SNDDATA
	 BRA L24
      
H24   	 MOVLW 0XC0
	 MOVWF DISPVAL
	 CALL SNDCMD
	 CALL LDELAY
	 MOVLW 0H
	 CPFSEQ RESH
	 BRA NIL
	 BRA NNIL
NIL  	 MOVLW '-'
	 CPFSEQ RESH
	 BRA POS
	 BRA NEG
POS   	 MOVF RESH, W
	 ADDLW 30H
	 MOVWF DISPVAL
	 BRA RESDONE
NEG      MOVF RESH, W
	 MOVWF DISPVAL
RESDONE  CALL SNDDATA
NNIL  	 MOVF RESL, W
	 ADDLW 30H
	 MOVWF DISPVAL
	 CALL SNDDATA
	 CLRF STAGE
	 CLRF N1
	 CLRF N2
	 CLRF OP
	 CLRF RESH
	 CLRF RESL
	 CALL KEYINIT

;-----------------------------MAIN-----------------------------------------------------------------------------------------------------------
MAIN 	 ORG    500H
DISPVAL	 EQU	20H
KEYCOL	 EQU	21H
N1 	 EQU	22H
N2	 EQU	23H
OP	 EQU	24H
RESH	 EQU	25H
RESL	 EQU	26H
STAGE 	 EQU	27H	;0-1ST NUM, 1-2ND NUM, 2-OP, 3-RES
	 CLRF STAGE
	 CLRF TRISD	;DISPLAY
	 BCF TRISC,0	;RS
	 BCF TRISC,1	;EN
	 BCF TRISC,2	;R/W
	 CLRF N1
	 CLRF N2
	 CLRF OP
	 CLRF RESH
	 CLRF RESL
	 BRA DISPINIT
;-----------------------------Look-up Tables-------------------------------------------------------------------------------------------------
	 ORG 600H
KEYCODE0 DB '7','4','1','C'
KEYCODE1 DB '8','5','2','0'
KEYCODE2 DB '9','6','3','='
KEYCODE3 DB '/','*','-','+'
	 ORG 700H
DATA0	 DB "****WELCOME!****",0
	 ORG 720H
DATA1	 DB "Enter 1st Numbers:",0
	 ORG 740H
DATA2	 DB "Enter 2nd Number:",0
	 ORG 760H
DATA_OP	 DB "Enter Operator:",0
	 ORG 780H	 
DATA_INV DB "BAD OPERATION!!",0
	 ORG 800H
DATA_ADD DB "Result:"
	 END

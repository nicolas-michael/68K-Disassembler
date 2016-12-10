*-----------------------------------------------------------------
* Title      : 68K INSTRUCTION DISASSEMBLER
* Written by : KUNLAKAN CHERDCHUSILP, NICOLAS MICHAEL, VUOCHLY KY
* Date       : 5/29/15
* Description: CSS422 PROJECT, 68K INSTRUCTION DISASSEMBLER
*-----------------------------------------------------------------

CR          EQU     $0D
LF          EQU     $0A
starting    EQU     $00003000
ending      EQU     $00FFFFFE
TAB         EQU     $09

            ORG     $1000
START:      
            MOVEA.L #outData, A2        ;THIS LOCATION IS WHERE THE DISASSEMBLED INSTRUCTION IS STORED

*-----------------------------------------------------------------
* DISPLAY WELCOME MESSAGE
*-----------------------------------------------------------------    
WELCOME     LEA     WelcomeMsg,A1       ;LOAD WELCOME MESSAGE
            MOVE.B  #14,D0              ;DISPLAY THE WELCOME MESSAGE
            TRAP    #15                 
            LEA     WrtBy,A1            ;LOAD THE WRITEN-BY MESSAGE
            MOVE.B  #14,D0              ;DISPLAY THE MESSAGE
            TRAP    #15                 
            MOVEA   #$0,A1              ;CLEAR A1 REGISTER
            LEA     note1,A1            ;LOAD THE PRE-CONDITIONS MESSAGES AND
            MOVE.B  #14,D0              ;DISPLAY ALL THE PRE-CONDITION MESSAGES
            TRAP    #15                 
            LEA     note2,A1            
            MOVE.B  #14,D0              
            TRAP    #15                 
            LEA     note3,A1            
            MOVE.B  #14,D0              
            TRAP    #15                 
            LEA     note4,A1            
            MOVE.B  #14,D0              
            TRAP    #15                 
            
*-----------------------------------------------------------------
* THE MAIN METHOD: 
*   -- GET USER'S STARTING AND ENDING ADDRESSES
*   -- DISPLAY THE INPUT ACCORDING TO THE START AND END ADDRESSES
*-----------------------------------------------------------------
MAIN        JSR     getStart            ;GET THE USER'S STARTING ADDRESS
            JSR     getEnd              ;GET THE USER'S ENDING ADDRESS
            MOVE.B  #0,D4               ;INITIALIZE THE OUTPUT COUNTER TO 0
            BRA     LOOPDYDOOP          ;DISPLAY THE OUTPUT
            
*-----------------------------------------------------------------
* GET THE STARTING ADDRESS, DECODE, AND SAVE IN A6
*-----------------------------------------------------------------         
getStart    LEA     startLoc,A1         ;LOAD THE ASK-FOR-START-ADDR MESSAGE
            MOVE.B  #14,D0              ;PROMPT THE USER FOR HIS/HER STARTING ADDRESS
            TRAP    #15                 ;FOR THE USER TO ENTER THE ADDRESS
            MOVEA   #$0,A1              ;CLEAR A1
            CLR     D6                  ;CLEAR D6
            MOVEA.L startAddr,A1        ;MAKE A1 POINT TO ADDR $90, TO ACCESS THE DATA TO DECODE
            MOVE.L  #2,d0               ;GET THE USER INPUT (THE INPUT WILL BE STORED IN (A1), POINTER => $90)
            TRAP    #15                 ;(THE LENGTH OF THE USER INPUT WILL BE STORED IN D1)
            JSR     validate            ;VALIDATE AND DECODE THE USER INPUT, THEN SAVE IN D6 (FOR FURTHER CHECKING)
            CMP.B   #0,D3               ;CHECK IF THE INPUT INVALID (D3 SET TO 0/1 WHILE VALIDATING), 0=GOOD, 1=BAD
            BEQ     checkRangeS         ;IF NO PROBLEM (0), CHECK IF THE ADDRESS IS WITHIN THE LIMIT RANGE
errMsgS     LEA     error,A1            ;ELSE, LOAD THE INPUT ERROR MESSAGE AND
            MOVE.B  #14,D0              ;DISPLAY THE ERROR MESSAGE TO THE USER
            TRAP    #15                 
            JSR     getStart            ;FOR THE USER TO ENTER THE ADDRESS AGAIN

checkRangeS JSR     checkOdd            ;CHECK IF THE STARTING ADDRESS IS ODD (BAD)
            CMP.B   #1,D3               ;THE checkOdd WILL UPDATE TO D3 IF EVEN OR ODD (0=EVEN, 1=ODD)
            BEQ     errMsgS             ;IF D3=1, THEN PRINT THE INPUT ERROR MESSAGE, AND RE-PROMPT
            MOVE.L  #starting,D2        ;COPY THE LOWER LIMIT ADDRESS TO D2 TO CHECK
            CMP.L   D2,D6               ;  IF THE ADDRESS IS BELOW THIS LOWER LIMIT
            BLT     errMsgS             ;IF YES, THEN PRINT THE INPUT ERROR MSG AND PROMPT AGAIN
            MOVE.L  #ending,D2          ;COPY THE UPPER LIMIT ADDRESS TO D2 TO CHECK 
            CMP.L   D2,D6               ;  IF THE ADDRESS IS OVER THE UPPER LIMIT
            BGT     errMsgS             ;IF YES, PRINT THE INPUT ERROR MESSAGE AND PROMPT AGAIN
            MOVEA.L D6,A6               ;****THE STARTING ADDRESS IS VALID, SAVE IT IN A6****

checkOdd    CLR.L   D5                  ;CLEAR D5 
            MOVE.W  D6,D5               ;COPY THE ADDRESS FROM D6 TO D5 TO CHECK FOR ODD
            MOVE.L  #$00000002,D2       ;PUT #2 INTO D2
            DIVU    D2,D5               ;DIVIDE THE ADDRESS BY 2
            SWAP    D5                  ;SWAP THE REMAINDER AND THE QUOTIENT (TO ACCESS THE REMAINDER)
            CMP.B   #$01,D5             ;CHECK IF THE REMAINDER IS 1 (IF REMAINDER = 1, THEN ADDRESS IS ODD) 
            BEQ     badInput            ;IF YES, GIVE BAD-INPUT SIGNAL (PUT #1 IN D3)
            RTS                         ;ELSE, THE ADDRESS IS GOOD, JUST RETURN
            
*--------------------------------------------------------------
* GET THE ENDING ADDRESS, DECODE, AND SAVE IN A5
*--------------------------------------------------------------
getEnd      LEA     endLoc,A1           ;LOAD THE ASK-FOR-END-ADDRESS MESSAGE
            MOVE.B  #14,D0              ;PROMPT THE USER FOR HIS/HER ENDING ADDRESS
            TRAP    #15                 ;FOR THE USER TO ENTER THE ENDING ADDRESS
            MOVEA   #$0,A1              ;CLEAR A1
            CLR     D6                  ;CLEAR D6
            MOVEA.L endAddr,A1          ;MAKE A1 POINT TO $98 FOR ACCESSING INPUT (ENDING ADDR) TO DECODE
            MOVE.L  #2,D0               ;GET THE USER INPUT
            TRAP    #15                 ; AND IT WILL BE STORED IN (A1)
            JSR     validate            ;VALIDATE AND DECODE THE USER INPUT AND SAVE IN D6
            CMP.B   #0,D3               ;CHECK IF THE INPUT IS INVALID (WHILE VALIDATING) 0=GOOD, 1=BAD
            BEQ     checkRangeE         ;IF 0 (GOOD), CHECK IF THE ADDRESS IS WITHIN THE LIMIT RANGE
checkRangeE JSR     checkOdd            ;CHECK IF THE ENDING ADDRESS IS ODD (BAD)
            CMP.B   #1,D3               ;CHECK IF THE INPUT IS NOT ODD (0=EVEN, 1=ODD)
            BEQ     errMsgE             ;IF 1 (ODD), THEN PRINT THE INPUT ERROR MESSAGE AND PROMPT AGAIN
            MOVE.L  #starting,D2        ;CHECK IF THE ADDRESS IS LESS THAN THE 
            CMP.L   D2,D6               ;  LOWER LIMIT ADDRESS
            BLT     errMsgE             ;IF YES, PRINT INPUT ERROR MESSAGE AND PROMPT AGAIN
            MOVE.L  #ending,D2          ;CHECK IF THE ADDRESS IS GREATER THAN THE 
            CMP.L   D2,D6               ;  UPPER LIMIT ADDRESSS
            BGT     errMsgE             ;IF YES, PRINT INPUT ERROR MESSAGE AND PROMPT AGAIN
            MOVE.L  A6,D2               ;MOVE THE USER'S STARTING ADDRESS TO D2 TO COMPARE WITH HIS/HER ENDING ADDRESS
            CMP.L   D2,D6               ;CHECK IF THE ENDING ADDRESS IS LESS THAN THE STARTING ADDRESS
            BLT     errMsgE             ;IF YES, PRINT THE INPUT ERROR MESSAGE AND PROMPT AGAIN
            MOVEA.L D6,A5               ;*****THE ENDING ADDRESS IS VALID, SAVE IT IN A5*****
            RTS            
errMsgE     LEA     error,A1            ;LOAD THE INPUT ERROR MESSAGE
            MOVE.B  #14,D0              ;DIPSPLAY THE MESSAGE TO THE USER
            TRAP    #15                 
            JSR     getEnd              ;FOR THE USER TO ENTER HIS/HER ENDING ADDRESS AGAIN
            
*---------------------------------------------------------------------------------------------
* VALIDATE EACH DIGITS OF THE USER INPUT AND DECODE INTO ACTUAL VALUE
* -- CHECK IF THE USER INPUT IS NULL OR GREATER THAN 8 DIGITS
* -- CHECK EACH CHARACTER IF IT IS VALID. IF VALID, DECODE IT
* NOTE:
*   --USING D5 TO TEMPORARY STORE EACH DIGIT TO VALIDATE
*   --USING D6 TO STORE THE CONVERTED ADDRESS (TEMPORARY)
*   --USING D3 TO STORE THE SIGNAL REPRESENTS GOOD(0) OR BAD(1) INPUT
*   -- '0' ~ '9' ==> 30 ~ 39
*   -- 'A' ~ 'F' ==> 41 ~ 46
*   -- 'a' ~ 'f' ==> 61 ~ 66
*---------------------------------------------------------------------------------------------
validate    MOVEQ   #$0,D2              ;SET D2 TO 0 TO COMPARE IF THE INPUT IS NULL 
            CMP.B   D2,D1               ;IS THE LENGTH OF THE USER INPUT = 0?
            BEQ     badInput            ;IF YES, BRANCH TO badInput
            CMPI    #$8,D1              ;CHECK IF THE LENGTH OF THE USER INPUT IS
            BGT     badInput            ;GREATER THAN 8 CHARACTERS. IF YES, badInput
valLoop                                 ;VALIDATION LOOP, VALIDATE CHARACTER BY CHARACTER
            MOVE.B  (A1),D5             ;COPY AN INPUT DIGIT INTO D5 TO VALIDATE 
            CMP.B   D2,D5               ;CHECK IF THE CHARACTER IS NULL
            BEQ     badInput            ;IF NULL, IT'S A BAD INPUT
            CMP.B   #$66,D5             ;66 IS ASCII VALUE OF CHARACTER 'f', HIGHEST IN THE VALID RANGE 
            BGT     badInput            ;IF THIS DIGIT IS GREATEER THAN 66, IT'S A BAD INPUT CHARACTER
            CMP.B   #$60,D5             ;60 IS AN ASCII VALUE OF 'a', CHECK 'a' <= x <= 'f'
            BGT     conLCase            ;IF THIS DIGIT IS GREATER THAN 60, IT'S A VALID LOWER CASE LETER
            CMP.B   #$46,D5             ;IS THE DIGIT GREATER THAN 46? 46='F'
            BGT     badInput            ;IF YES, THEN IT'S BAD (IT'S BETWEEN 'F' AND 'a')
            CMP.B   #$40,D5             ;GREATER THAN 40?
            BGT     conUCase            ;IF YES, IT'S AN UPPER CASE CHAR
            CMP.B   #$39,D5             ;IS THIS NUMBER IS GREATER THAN '9'?
            BGT     badInput            ;IF YES, IT'S A BAD CHAR INPUT
            CMP.B   #$29,D5             ;IS THIS NUMBER GREATER THAN 29?
            BGT     conNum              ;IF YES, IT'S A NUMBER BETWEEN 0 AND 9
            
conLCase    SUB.B   #$57,D5             ;CONVERT THE ASCII VALUE OF LOWER-CASE CHAR TO HEXADECIMAL
            BRA     converted           ;AFTER CONVERTED, BRANCH TO converted TO SAVE
conUCase    SUB.B   #$37,D5             ;CONVERT THE ASCII VALUE OF UPPER-CASE CHAR TO HEXADECIMAL
converted   ASL.L   #4,D6               ;ARITHMETIC SHIFT LEFT, SHIFT D6 4 BITS TO THE LEFT (THEN 4 ZEROS ADDED AT THE RIGHT END)
            ADD.B   D5,D6               ;NOW REPLACE THE LAST 4 BITS (ZEROS) WITH THE HEXADECIMAL NUMBER
            ADDQ    #1,A1               ;INCREMENT THE ADDRESS POINTER, POINT TO THE NEXT DIGIT
            SUB.B   #1,D1               ;DECREMENT THE LENTH OF THE USER INPUT STRING
            CMP.B   #0,D1               ;CHECK IF THE LENGTH IS 0 (DONE WITH ALL THE DIGITS?)
            BEQ     goodInput           ;IF YES, GIVE SIGNAL AS GOOD INPUT
            BRA     valLoop             ;ELSE, KEEP VALIDATING THE NEXT DIGIT
conNum      SUB.B   #$30,D5             ;CONVERT THE ASCII VALUE OF NUMBER TO HEXADECIMAL
            ASL.L   #4,D6               ;ARITHMETIC SHIFT LEFT, SHIFT D6 4 BITS TO THE LEFT (THEN 4 ZEROS ADDED AT THE RIGHT END)
            ADD.B   D5,D6               ;NOW REPLACE THE 4 BITS (ZEROS) WITH THE HEXADECIMAL NUMBER
            ADDQ    #1,A1               ;INCREMENT THE ADDRESS POINTER, POINT TO THE LOCATION OF THE NEXT DIGIT
            SUB.B   #1,D1               ;DECREMENT THE LENGTH OF THE USER INPUT STRING
            CMP.B   #0,D1               ;CHECK IF THE LENGTH IS 0 (DONE WITH ALL THE DIGITS?)
            BNE     valLoop             ;IF NO, KEEP VALIDATING THE NEXT DIGIT
goodInput   MOVEQ   #$0,D3              ;GIVE GOOD INPUT SIGNAL BY
            RTS                         ;PUT #0 INTO D3 TO REPRESENT THE BAD INPUT
badInput    MOVEQ   #$1,D3              ;GIVE BAD INPUT SIGNAL BY
            RTS                         ;PUT #1 INTO D3 TO REPRESENT THE BAD INPUT



*---------------------------------------------------------------------------------
* PROMPT IF THE USER WANT TO RE-RUN THE PROGRAM AGAIN 
* -- USER MUST ENTER EITHER UPPER OR LOWERCASE OF
*       - 'N'/'n' FOR NO
*       - 'Y'/'y' FOR YES 
*---------------------------------------------------------------------------------
promptCont  LEA     AskToCont,A1        ;LOAD THE WANT-TO-CONTINUE MESSAGE
            MOVE.B  #14,D0              ;PRINT OUT THE MESSAGE
            TRAP    #15
            MOVEA.W YN,A1               ;POINT THE A1 POINTER TO ADDRESS YN = 80
            MOVE.B  #2, D0
            TRAP    #15
            CMP.B   #$79, (A1)          ;CHECK IF THE USER ENTER LOWER CASE 'y'
            BEQ     MAIN                ;IF YES, BRANCH TO main TO START OVER
            CMP.B   #$59, (A1)          ;CHECK IF THE USER ENTER UPPER CASE 'Y'
            BEQ     MAIN                ;IF YES, BRANCH TO main TO START OVER
            CMP.B   #$6e, (A1)          ;CHECK IF THE USER INPUT IS LOWER CASE 'n'
            BEQ     DONE                ;IF YES, BRANCH TO DONE
            CMP.B   #$4e, (A1)          ;CHECK IF THE USER INPUT UPPER CASE 'N'
            BEQ     DONE                ;IF YES, BRANCH TO DONE
            BRA     NEITHER             ;ELSE PRINT OUT AN ERROR MESSAGE      

NEITHER     LEA     NOTNY,A1            ;PRINT THE ERROR MESSAGE
            MOVE.B  #14,D0              ;BECUASE THE USER DIDN'T
            TRAP    #15                 ;ENTER THE LETTER N OR Y
            BRA     promptCont          ;PROMPT THE USER TO RE-ENTER COMMAND

*---------------------------------------------------------------------------------
* LOAD THE THANK-YOU MESSAGE AND TERMINATE THE PROGRAM
*---------------------------------------------------------------------------------                
DONE        LEA     ThxMsg,A1           ;LOAD THE THANK-YOU MESSAGE
            MOVE.B  #14,D0              ;PRINT OUT THE MESSAGE AND
            TRAP    #15    
            MOVE.B  #9, d0              ;TERMINATE THE PROGRAM
            TRAP    #15

**********************************************************************************
* DISPLAY THE DISASSEMBLED INSTRUCTIONS
*
* FORMATTED AS: ADDRESS FOLLOWED BY THE INSTRUCTION. 
* EXAMPLE:
*           00000000    MOVE.B  D0,D1
**********************************************************************************

LOOPDYDOOP  JSR     DOOPDYLOOP 
            MOVEA.L A2, A1              ;MAKE A1 POINT TO ADDRESS IN A2
            JSR     APPENDADDRESS       ;PREPARE THE ADDRESS TO PRINT OUT
            MOVE.B  #TAB, (A2)+        
            JSR     DISASSEMBLE         ;DISASSEMLE AN INSTRUCTION
            MOVE.B  #$0D, (A2)+         ;NEW
            MOVE.B  #$0A, (A2)+         ;LINE
            MOVE.B  #$0, (A2)+          
            MOVE.B  #14, D0             ;PRINT OUT THE ADDRESS AND ITS 
            TRAP    #15                 ;CORRESPONDING DISASSEMBLED INSTRUCTION
            ADD.B   #1,D4               ;INCREMENT THE COUNTER AND CHECK 
            CMP.B   #30,D4              ;IF IT REACHES THE SPECIFIED NUMBER OF LINES
            BEQ     ENTR                ;IF YES, PROMPT USER TO HIT THE ENTER KEY
            JMP     ISEND               ;ELSE, CHECK IF IT REACHES THE ENDING ADDRESS
                    
ENTR        JSR     CHKEND              ;CHECK IF IT REACHES THE ENDING ADDRESS 
                                        ;BEFORE PRINT OUT THE HIT-ENTER MESSAGE
            LEA     enter,A1            ;PRINT THE HIT-ENTER-TO-SHOW-MORE MESSAGE
            MOVE.B  #14,D0              
            TRAP    #15
            MOVEA.W ent,A1
            MOVE.B  #2,D0               ;INPUT BUFFER, WAIT FOR USER TO HIT ENTER
            TRAP    #15
            JMP     CONTI               ;THEN CONTINUE PRINTING IF HASN'T REACH END ADDRESS YET
            
CONTI       MOVE.B  #0,D4               ;RESET THE OUTPUT COUNTER BACK TO 0
ISEND       CMP.L   A5,A6               ;REACHED THE ENDING ADDRESS?
            BLT     LOOPDYDOOP          ;IF CURRENT ADDRESS LESS THAN ENDING ADDR, KEEP LOOPING
            JMP     promptCont          ;ELSE, PROMPT IF THE USER WANT TO RERUN THE PROGRAM

CHKEND      CMP.L   A5,A6               ;CHECK IF REACHES THE ENDING ADDRESS
            BEQ     promptCont          ;IF YES, ASK IF USER WANT TO RERUN THE PROGRAM
            RTS  
            
DOOPDYLOOP  MOVE.L  #OUTDATA, D0
            CMP.L   #OUTDATA, A2
            BEQ     DIEDIEDIE
            MOVE.B  #$FF, -(A2)
            JMP     DOOPDYLOOP
DIEDIEDIE   RTS

*----------------------------------------------------------------------------------------------------
* DISASSEMBLE: DISASSEMBLE HEXADECIMAL INSTRUCTION CODE TO MNEMONIC INSTRUCTION
* PRECONDITION: - D2 AND D3 MUST NOT BE IN USED
*               - A2 STORES AN APPROPRIATE MEMORY REGION ADDRESS
*               - A6 STORES AN APPROPRIATE ADDRESS HAVING HEXADECIMLA INSTRUCTION TO BE DISASSEMBLED
* POSTCONDITION: - IF THE INSTRUCTION IS DEFINED IN THE REQUIREMENT, THE STRING OF THE RESULT WILL BE
*                  STORED IN OUTPUT MEMORY REGION POINTED BY A2
*                - IF THE INSTRUCTION IS NOT IN THE REQUIREMENT, "BAD DATA" WILL BE STORED IN OUTPUT
*                  MEMORY REGION POINTED BY A2
*----------------------------------------------------------------------------------------------------

DISASSEMBLE     CLR         D2              ;CLEAR BITS IN D2 AND D3 TO PREVENT INFORMATION OVERLAPED
                CLR         D3
                
                MOVE.W      (A6), D2        ;RETRIEVE ORIGINAL INSTRUCTION TO D2 (NO CHANGE ALLOWED)
                MOVE.W      D2, D3          ;COPY ORIGINAL INSTRUCTION TO D3 (CHANGE ALLOW)

                LSR         #8, D3          ;GET THE FIRST 4 BITS TO DETERMIND TYPE OF MNEMONIC
                LSR         #4, D3
                MULU        #6, D3
                LEA         MAINTABLE, A3   ;LOAD INDEX INTO THE TABLE
                JSR         0(A3, D3)       ;JUMP INDIRECT WITH INDEX TO MAINTABLE

                RTS                         ;FINISH DIASSEMBLING
            
                    
*----------------------------------------------------------------------------------------------------
* MAINTABLE: THIS IS A PRIMARY JUMP TABLE FOR DETERMINING TYPES OF OPCODES INSTRUCTION BY LOOKING AT
*            THE FIRST 4 BITS IN THE HEXADECIMAL INSTRUCTION
* PRECONDITION: - D2 MUST CONTAINS ORIGINAL INSTRUCTION FOR FUTHURE DETERMINING
*               - D3 MUST CONTAINS THE FIRST 4 BITS OF INSTRUCTION
* POSTCONDITION: - IF THE INSTRUCTION IS DEFINED IN THE REQUIREMENT, THE STRING OF THE RESULT WILL BE
*                  STORED IN OUTPUT MEMORY REGION POINTED BY A2
*                - IF THE INSTRUCTION IS NOT IN THE REQUIREMENT, "BAD DATA" WILL BE STORED IN OUTPUT
*                  MEMORY REGION POINTED BY A2
*----------------------------------------------------------------------------------------------------
MAINTABLE       JMP         CODE0000
                JMP         CODE0001
                JMP         CODE0010
                JMP         CODE0011
                JMP         CODE0100
                JMP         CODE0101
                JMP         CODE0110
                JMP         CODE0111
                JMP         CODE1000
                JMP         CODE1001
                JMP         CODE1010
                JMP         CODE1011
                JMP         CODE1100
                JMP         CODE1101
                JMP         CODE1110
                JMP         CODE1111
FINISH          RTS

*----------------------------------------------------------------------------------------------------
* CODE0000: DISASSEMBLE THE HEXADECIMAL INSTRUCTION STARTING WITH 0000
*----------------------------------------------------------------------------------------------------
CODE0000        JSR         SHIFT8
                CMPI.B      #%1, D3         ;CHECK IF THE 8TH BIT IS EQUAL TO 1
                BEQ         IFBCLR_DY       ;IF IT IS EQUAL, THE INSTRUCTION IS "BCLR DN, <EA>"
                
                MOVE.W      D2, D3          ;OTHERWISE, GET BIT 11, 10, AND 9 FOR FUTHER DISASSEMBLING
                LSL.W       #4, D3
                LSR.W       #8, D3
                LSR.W       #5, D3
                MULU        #6, D3
                LEA         TABLEZERO, A3   ;LOAD INDEX INTO THE TABLE
                JSR         0(A3, D3)       ;JUMP INDIRECT WITH INDEX TO TABLEZERO
RETURN0000      BRA         FINISH          ;INSTRUCTION IS FINISHED DECODING


IFBCLR_DY       JSR         SHIFT76
                CMPI.B      #%10, D3        ;CHECK IF INSTRUCTION IS ACTUALLY BCLR WITH NUMBER DYNAMIC
                BNE         BAD_DATA        ;IF IT IS NOT, THEN THE OPCODE IS NOT DEFINED
                MOVE.B      #'B', (A2)+     ;OTHERWISE, IT IS ACTUALLY "BCLR DN, <EA>"    
                MOVE.B      #'C', (A2)+
                MOVE.B      #'L', (A2)+
                MOVE.B      #'R', (A2)+
                MOVE.B      #TAB, (A2)+
                JSR         ISBCLR          ;GET EFFECTIVE ADDRESS
                BRA         RETURN0000      ;RETURN BACK TO THE MAIN FUNCTION

*----------------------------------------------------------------------------------------------------
* CODE0001: DISASSEMBLE THE HEXADECIMAL INSTRUCTION STARTING WITH 0001
*----------------------------------------------------------------------------------------------------
CODE0001        MOVE.B      #'M', (A2)+     ;THE INSTRUCTION IS "MOVE.B"
                MOVE.B      #'O', (A2)+
                MOVE.B      #'V', (A2)+
                MOVE.B      #'E', (A2)+
                MOVE.B      #'.', (A2)+
                MOVE.B      #'B', (A2)+
                MOVE.B      #TAB, (A2)+
                JSR         ISMOVE          ;GET EFFECTIVE ADDRESS
                BRA         FINISH          ;RETURN BACK TO THE MAIN FUNCTION
           
*----------------------------------------------------------------------------------------------------
* CODE0010: DISASSEMBLE THE HEXADECIMAL INSTRUCTION STARTING WITH 0010
*----------------------------------------------------------------------------------------------------
CODE0010        MOVE.B      #'M', (A2)+     ;THE INSTRUCTION IS "MOVE..."
                MOVE.B      #'O', (A2)+
                MOVE.B      #'V', (A2)+
                MOVE.B      #'E', (A2)+
                BRA         IFMOVEAL        ;CHECK IF THE INSTRUCTION IS MOVEA OR JUST MOVE
IFMOVEL         MOVE.B      #'.', (A2)+     ;PROVIDE SIZE OF THE INSTRUCTION
                MOVE.B      #'L', (A2)+
                MOVE.B      #TAB, (A2)+
                BRA         ISMOVEL         ;GET EFFECTIVE ADDRESS
                BRA         FINISH          ;RETURN BACK TO THE MAIN FUNCTION
          
IFMOVEAL        JSR         SHIFT876
                CMPI.W      #%001, D3       ;CHECK IF THIS INSTRUCTION IS MOVEA
                BNE         IFMOVEL         ;IF THE INSTRUCTION IS NOT MOVEA, IT MUST BE MOVE
                MOVE.B      #'A',(A2)+      ;OTHERWISE, IT IS "MOVEA.L"
                BRA         IFMOVEL

*----------------------------------------------------------------------------------------------------
* CODE0011: DISASSEMBLE THE HEXADECIMAL INSTRUCTION STARTING WITH 0011
*----------------------------------------------------------------------------------------------------
CODE0011        MOVE.B      #'M', (A2)+     ;THE INSTRUCTION IS "MOVE..."
                MOVE.B      #'O', (A2)+
                MOVE.B      #'V', (A2)+
                MOVE.B      #'E', (A2)+
                BRA         IFMOVEAW        ;CHECK IF THE INSTRUCTION IS MOVEA OR JUST MOVE
IFMOVEW         MOVE.B      #'.', (A2)+     ;PROVIDE SIZE OF THE INSTRUCTION
                MOVE.B      #'W', (A2)+
                MOVE.B      #TAB, (A2)+
                BRA         ISMOVE          ;GET EFFECTIVE ADDRESS
                BRA         FINISH          ;RETURN BACK TO THE MAIN FUNCTION
                
IFMOVEAW        JSR         SHIFT876
                CMPI.W      #%001, D3       ;CHECK IF THIS INSTRUCTION IS MOVEA
                BNE         IFMOVEW         ;IF THE INSTRUCTION IS NOT MOVEA, IT MUST BE MOVE
                MOVE.B      #'A',(A2)+      ;OTHERWISE, IT IS "MOVEA.W"
                BRA         IFMOVEW

*----------------------------------------------------------------------------------------------------
* CODE0100: DISASSEMBLE THE HEXADECIMAL INSTRUCTION STARTING WITH 0100
*----------------------------------------------------------------------------------------------------
CODE0100        JSR         SHIFT8
                CMPI.B      #%1, D3         ;CHECK IF THE 8TH BIT IS EQUAL TO 1
                BEQ         IFLEA           ;IF IT IS EQUAL, THE INSTRUCTION MAY BE "LEA"

                MOVE.W      D2, D3
                LSL.W       #4, D3          ;IF NOT, GET BIT 11, 10, AND 9 FOR FUTHER DISASSEMBLING
                LSR.W       #8, D3
                LSR.W       #5, D3
                MULU        #6, D3
                LEA         TABLEFOUR, A3   ;LOAD INDEX INTO THE TABLE
                JSR         0(A3, D3)       ;JUMP INDIRECT WITH INDEX TO TABLEFOUR
RETURN0100      BRA         FINISH          ;RETURN BACK TO THE MAIN FUNCTION


IFLEA           JSR         SHIFT876
                CMPI.B      #%111, D3       ;CHECK IF THE INSTRUCTION IS ACTUALLY "LEA"
                BNE         BAD_DATA        ;IF IT IS NOT, THEN THE OPCODE IS NOT DEFINED
                MOVE.B      #'L', (A2)+     ;OTHERWISE, IT IS ACTUALLY "LEA"
                MOVE.B      #'E', (A2)+
                MOVE.B      #'A', (A2)+
                MOVE.B      #TAB, (A2)+
                MOVE.B      #TAB, (A2)+
                JSR         ISLEA           ;GET EFFECTIVE ADDRESS
                BRA         RETURN0100      ;RETURN TO CODE0100

*----------------------------------------------------------------------------------------------------
* CODE0101: DISASSEMBLE THE HEXADECIMAL INSTRUCTION STARTING WITH 0101
*----------------------------------------------------------------------------------------------------
CODE0101        JSR         SHIFT8
                CMPI.B      #%1, D3         ;CHECK IF THE INSTRUCTION IS ACTUALLY "LEA"
                BNE         BAD_DATA        ;IF IT IS NOT, THEN THE OPCODE IS NOT DEFINED
                
                MOVE.B      #'S', (A2)+     ;THE INSTRUCTION IS "SUBQ"
                MOVE.B      #'U', (A2)+
                MOVE.B      #'B', (A2)+
                MOVE.B      #'Q', (A2)+
                JSR         GET_SIZE        ;GET SIZE FOR THE INSTRUCTION
                MOVE.B      #TAB, (A2)+
                JSR         ISSUBQ          ;GET EFFECTIVE ADDRESS
                BRA         FINISH          ;RETURN BACK TO THE MAIN FUNCTION

*----------------------------------------------------------------------------------------------------
* CODE0110: DISASSEMBLE THE HEXADECIMAL INSTRUCTION STARTING WITH 0110
*----------------------------------------------------------------------------------------------------
CODE0110        MOVE.W      D2, D3
                LSL.W       #4, D3          ;GET BIT 11 TO 8
                LSR.W       #8, D3
                LSR.W       #4, D3

                MULU        #6, D3
                LEA         TABLESIX, A3    ;LOAD INDEX INTO THE TABLE
                JSR         0(A3, D3)       ;JUMP INDIRECT WITH INDEX TO TABLESIX
               
                BRA         FINISH          ;RETURN BACK TO THE MAIN FUNCTION

*----------------------------------------------------------------------------------------------------
* CODE0111: HEXADECIMAL INSTRUCTION STARTING WITH 0111 IS NOT DEFINED
*----------------------------------------------------------------------------------------------------
CODE0111		BRA         BAD_DATA

*----------------------------------------------------------------------------------------------------
* CODE1000: DISASSEMBLE THE HEXADECIMAL INSTRUCTION STARTING WITH 1000
*----------------------------------------------------------------------------------------------------
CODE1000        JSR         SHIFT876
                CMPI.W      #%111, D3       ;CHECK IF BIT 8, 7, AND 6 IS EQUAL TO 111
                BEQ         IFDIVS          ;IF IT IS, THE INSTRUCTION IS "DIVS"
                BRA         IFOR            ;OTHERWISE, IT IS "OR"
RETURN1000      BRA         FINISH          ;RETURN BACK TO THE MAIN FUNCTION


IFDIVS          MOVE.B      #'D', (A2)+     ;THE INSTRUCTION IS "DIVS"
                MOVE.B      #'I', (A2)+
                MOVE.B      #'V', (A2)+
                MOVE.B      #'S', (A2)+
                MOVE.B      #TAB, (A2)+
                JSR         ISMULS          ;GET EFFECTIVE ADDRESS
                BRA         RETURN1000      ;RETURN TO CODE1000

IFOR            JSR         SHIFT876
                CMPI.W      #%011, D3       ;CHECK IF BIT 8, 7, AND 6 IS EQUAL TO 011
                BEQ         BAD_DATA        ;IF IT IS EQUAL, THE INSTRUCTION IS NOT DEFINED
                MOVE.B      #'O', (A2)+     ;OTHERWISE, THE INSTRUCTION IS "OR"
                MOVE.B      #'R', (A2)+
                JSR         GET_OPMODE      ;GET OPMODE
                BRA         RETURN1000      ;RETURN TO CODE1000


*----------------------------------------------------------------------------------------------------
* CODE1001: DISASSEMBLE THE HEXADECIMAL INSTRUCTION STARTING WITH 1001
*----------------------------------------------------------------------------------------------------
CODE1001        JSR         SHIFT876
                CMPI.W      #%011, D3
                BEQ         BAD_DATA
                CMPI.W      #%111, D3
                BEQ         BAD_DATA
                
                MOVE.B      #'S', (A2)+     ;THE INSTRUCTION IS "SUB"
                MOVE.B      #'U', (A2)+
                MOVE.B      #'B', (A2)+
                JSR         GET_OPMODE      ;GET OPMODE
                BRA         FINISH          ;RETURN BACK TO THE MAIN FUNCTION

*----------------------------------------------------------------------------------------------------
* CODE1010: HEXADECIMAL INSTRUCTION STARTING WITH 1010 IS NOT DEFINED
*----------------------------------------------------------------------------------------------------
CODE1010        BRA         BAD_DATA

*----------------------------------------------------------------------------------------------------
* CODE1011: DISASSEMBLE THE HEXADECIMAL INSTRUCTION STARTING WITH 1011
*----------------------------------------------------------------------------------------------------
CODE1011		JSR         SHIFT876
                MULU        #6, D3
                LEA         TABLEELEVEN, A3 ;LOAD INDEX INTO THE TABLE
                JSR         0(A3, D3)       ;JUMP INDIRECT WITH INDEX TO TABLEELEVEN
                BRA         FINISH          ;RETURN BACK TO THE MAIN FUNCTION

*----------------------------------------------------------------------------------------------------
* CODE1100: DISASSEMBLE THE HEXADECIMAL INSTRUCTION STARTING WITH 1100
*----------------------------------------------------------------------------------------------------
CODE1100        JSR         SHIFT876
                CMPI.W      #%111, D3       ;CHECK IF BIT 8, 7, AND 6 ARE EQUAL TO 111
                BNE         BAD_DATA         ;IF NOT, THEN THE INSTRUCTION IS NOT DEFINED
                
                MOVE.B      #'M', (A2)+     ;OTHERWISE, THE INSTRUCTION IS "MULS"
                MOVE.B      #'U', (A2)+
                MOVE.B      #'L', (A2)+
                MOVE.B      #'S', (A2)+
                MOVE.B      #TAB, (A2)+
                JSR         ISMULS         ;GET EFFECTIVE ADDRESS
                BRA         FINISH          ;RETURN BACK TO THE MAIN FUNCTION
                
*----------------------------------------------------------------------------------------------------
* CODE1101: DISASSEMBLE THE HEXADECIMAL INSTRUCTION STARTING WITH 1101
*----------------------------------------------------------------------------------------------------
CODE1101		MOVE.B		#'A', (A2)+     ;THE INSTRUCTION IS "ADD"
				MOVE.B		#'D', (A2)+
				MOVE.B		#'D', (A2)+
                JSR         SHIFT876
                MULU        #6, D3
                LEA         TABLETHIRTEEN, A3   ;LOAD INDEX INTO THE TABLE
                JSR         0(A3, D3)           ;JUMP INDIRECT WITH INDEX TO TABLETHIRTEEN
                BRA         FINISH          ;RETURN BACK TO THE MAIN FUNCTION

*----------------------------------------------------------------------------------------------------
* CODE1110: DISASSEMBLE THE HEXADECIMAL INSTRUCTION STARTING WITH 1110
*----------------------------------------------------------------------------------------------------
CODE1110		JSR         SHIFT76
				CMPI.W		#%11, D3		;CHECK IF BIT 7 AND 6 ARE EQUAL TO 11
				BEQ			FOURTEEN_MEM	;IF IT IS EQAUL, THE INSTRUCTION IS MEMORY SHIFT/ROTATION
				BRA			FOURTEEN_REG	;OTHERWISE, IT IS A REGISTER SHIFT/ROTATION
CODE1110_CONT   JSR			GET_DIRECTION   ;GET DIRECTION OF THE INSTRUCTION
                JSR         GET_SIZE        ;GET SIZE OF THE INSTRUCTION
                MOVE.B      #TAB, (A2)+
                JSR         ISSHIFTYSTUFF
                BRA         FINISH          ;RETURN BACK TO THE MAIN FUNCTION
				
FOURTEEN_MEM	MOVE.W		D2, D3
				LSL.W		#4, D3		    ;GET BIT 11TH
				LSR.W		#8, D3
				LSR.W		#7, D3
				CMPI.B		#%0, D3		    ;CHECK IF THE INSTRUCTION IS ACTUALLY MEMORY SHIFT/ROTATION
				BNE			BAD_DATA         ;IF NOT, THE INSTRUCTION IS NOT DEFINED
				
				MOVE.W		D2, D3          ;OTHERWISE, SHIFT BITS TO GET BIT 10 AND 9 FOR FUTHER
				LSL.W		#5, D3          ;DISASSEMBLING
				LSR.W		#8, D3
				LSR.W		#6, D3
				
                MULU        #6, D3           
                LEA         TABLEFOURTEEN, A3   ;LOAD INDEX INTO THE TABLE
                JSR         0(A3, D3)           ;JUMP INDIRECT WITH INDEX TO TABLEFOURTEEN
				BRA         CODE1110_CONT       ;GO TO CODE1110_CONT FOR MORE DISASSEBMBLING
				
FOURTEEN_REG	MOVE.W		D2, D3
				LSL.W		#8, D3			    ;GET BIT 4 AND 3 FOR FUTHER DISASSEMBLING
				LSL.W		#3, D3
				LSR.W		#8, D3
				LSR.W		#6, D3
				
				CMPI        #%10, D3
				BEQ         BAD_DATA
				
                MULU        #6, D3
                LEA         TABLEFOURTEEN, A3   ;LOAD INDEX INTO THE TABLE
                JSR         0(A3, D3)           ;JUMP INDIRECT WITH INDEX TO TABLEFOURTEEN
                BRA         CODE1110_CONT       ;GOES BACK TO CODE1110_CONT FOR MORE DISASSEBMBLING
								
*----------------------------------------------------------------------------------------------------
* CODE1111: HEXADECIMAL INSTRUCTION STARTING WITH 1111 IS NOT DEFINED
*----------------------------------------------------------------------------------------------------
CODE1111		BNE         BAD_DATA




*----------------------------------------------------------------------------------------------------
* TABLEZERO: THIS IS SUBROUTINE JUMP TABLE. IT IS FOR DETERMINING OPMODE OF THE INSTRUCTION THAT IS
*            STARED WITH 0000
* PRECONDITION: - D2 MUST CONTAINS ORIGINAL INSTRUCTION FOR FUTHURE DETERMINING
*               - D3 MUST CONTAINS BIT 11, 10, AND 9 OF INSTRUCTION
* POSTCONDITION: - IF THE INSTRUCTION IS DEFINED IN THE REQUIREMENT, THE STRING OF THE RESULT WILL BE
*                  STORED IN OUTPUT MEMORY REGION POINTED BY A2
*                - IF THE INSTRUCTION IS NOT IN THE REQUIREMENT, "BAD DATA" WILL BE STORED IN OUTPUT
*                  MEMORY REGION POINTED BY A2
*----------------------------------------------------------------------------------------------------
TABLEZERO       JMP         ZERO000
                JMP         ZERO001
                JMP         ZERO010
                JMP         ZERO011
                JMP         ZERO100
                JMP         ZERO101
                JMP         ZERO110
                JMP         ZERO111
RETURN_ZERO     RTS                             ;RETURN BACK TO MAINTABLE

*----------------------------------------------------------------------------------------------------
* ZERO000: DISASSEMBLE THE HEXADECIMAL INSTRUCTION THAT HAS BIT 11, 10, AND 9 EQUAL TO 000
*----------------------------------------------------------------------------------------------------
ZERO000         MOVE.B      #'O', (A2)+         ;THE INSTRUCTION IS ORI
                MOVE.B      #'R', (A2)+
                MOVE.B      #'I', (A2)+
                JSR         GET_SIZE            ;GET SIZE OF THE INSTRUCTION
                MOVE.B      #TAB, (A2)+
                
                JSR         SHIFT76
                CMPI.B      #%10, D3            ;CHECK IF INSTRUCTION IS ACTUALLY "BCLF #<DATA>, <EA>"
                BEQ         IFORIL
                JSR         ISORI               ;GET EFFECTIVE ADDRESS
RETURN_ZERO000  BRA         RETURN_ZERO         ;RETURN TO TABLEZERO
                
IFORIL          JSR         ISORIL              ;GET EFFECTIVE ADDRESS
                BRA         RETURN_ZERO000

*----------------------------------------------------------------------------------------------------
* ZERO001: HEXADECIMAL INSTRUCTION THAT HAS BIT 11, 10, AND 9 EQUAL TO 001 IS NOT DEFINED
*----------------------------------------------------------------------------------------------------
ZERO001         JSR         BADDATA
                BRA         RETURN_ZERO

*----------------------------------------------------------------------------------------------------
* ZERO010: HEXADECIMAL INSTRUCTION THAT HAS BIT 11, 10, AND 9 EQUAL TO 010 IS NOT DEFINED
*----------------------------------------------------------------------------------------------------
ZERO010         JSR         BADDATA
                BRA         RETURN_ZERO

*----------------------------------------------------------------------------------------------------
* ZERO011: HEXADECIMAL INSTRUCTION THAT HAS BIT 11, 10, AND 9 EQUAL TO 011 IS NOT DEFINED
*----------------------------------------------------------------------------------------------------
ZERO011         JSR         BADDATA
                BRA         RETURN_ZERO

*----------------------------------------------------------------------------------------------------
* ZERO100: DISASSEMBLE THE HEXADECIMAL INSTRUCTION THAT HAS BIT 11, 10, AND 9 EQUAL TO 100
*----------------------------------------------------------------------------------------------------
ZERO100         JSR         SHIFT876
                CMPI.B      #%010, D3       ;CHECK IF INSTRUCTION IS ACTUALLY "BCLF #<DATA>, <EA>"
                BNE         BAD_DATA         ;IF IT IS NOT, THEN THE OPCODE IS NOT DEFINED
                
                MOVE.B      #'B', (A2)+     ;OTHERWISE, IT IS ACTUALLY "BCLF #<DATA>, <EA>"
                MOVE.B      #'C', (A2)+
                MOVE.B      #'L', (A2)+
                MOVE.B      #'R', (A2)+
                MOVE.B      #TAB, (A2)+
                JSR         ISBCLR         ;GET EFFECTIVE ADDRESS
                BRA         RETURN_ZERO     ;RETURN TO TABLEZERO

*----------------------------------------------------------------------------------------------------
* ZERO101: HEXADECIMAL INSTRUCTION THAT HAS BIT 11, 10, AND 9 EQUAL TO 101 IS NOT DEFINED
*----------------------------------------------------------------------------------------------------
ZERO101         JSR         BADDATA
                BRA         RETURN_ZERO

*----------------------------------------------------------------------------------------------------
* ZERO110: DISASSEMBLE THE HEXADECIMAL INSTRUCTION THAT HAS BIT 11, 10, AND 9 EQUAL TO 110
*----------------------------------------------------------------------------------------------------
ZERO110         MOVE.B      #'C', (A2)+     ;THE INSTRUCTION IS "CMPI"
                MOVE.B      #'M', (A2)+
                MOVE.B      #'P', (A2)+
                MOVE.B      #'I', (A2)+
                JSR         GET_SIZE        ;GET SIZE OF THE INSTRUCTION
                MOVE.B      #TAB, (A2)+
                
                JSR         SHIFT76
                CMPI.B      #%10, D3        ;CHECK IF THE SIZE IS LONG
                BEQ         IFCMPIL         ;IF IT IS, GET EFFECTIVE ADDRESS FOR CMPI.L
                JSR         ISORI           ;OTHERWISE, GET EFFECTIVE ADDRESS FOR CMPI
                BRA         RETURN_ZERO     ;RETURN TO TABLEZERO

IFCMPIL         JSR         ISORIL
                BRA         RETURN_ZERO
                
*----------------------------------------------------------------------------------------------------
* ZERO111: HEXADECIMAL INSTRUCTION THAT HAS BIT 11, 10, AND 9 EQUAL TO 111 IS NOT DEFINED
*----------------------------------------------------------------------------------------------------
ZERO111         JSR         BADDATA
                BRA         RETURN_ZERO




*----------------------------------------------------------------------------------------------------
* TABLEFOUR: THIS IS SUBROUTINE JUMP TABLE. IT IS FOR DETERMINING OPMODE OF THE INSTRUCTION THAT IS
*            STARED WITH 0100
* PRECONDITION: - D2 MUST CONTAINS ORIGINAL INSTRUCTION FOR FUTHURE DETERMINING
*               - D3 MUST CONTAINS BIT 11, 10, AND 9 OF INSTRUCTION
* POSTCONDITION: - IF THE INSTRUCTION IS DEFINED IN THE REQUIREMENT, THE STRING OF THE RESULT WILL BE
*                  STORED IN OUTPUT MEMORY REGION POINTED BY A2
*                - IF THE INSTRUCTION IS NOT IN THE REQUIREMENT, "BAD DATA" WILL BE STORED IN OUTPUT
*                  MEMORY REGION POINTED BY A2
*----------------------------------------------------------------------------------------------------
TABLEFOUR       JMP         FOUR000
                JMP         FOUR001
                JMP         FOUR010
                JMP         FOUR011
                JMP         FOUR100
                JMP         FOUR101
                JMP         FOUR110
                JMP         FOUR111
RETURN_FOUR     RTS

*----------------------------------------------------------------------------------------------------
* FOUR000: HEXADECIMAL INSTRUCTION THAT HAS BIT 11, 10, AND 9 EQUAL TO 000 IS NOT DEFINED
*----------------------------------------------------------------------------------------------------
FOUR000         JSR         BADDATA
                BRA         RETURN_FOUR

*----------------------------------------------------------------------------------------------------
* FOUR001: HEXADECIMAL INSTRUCTION THAT HAS BIT 11, 10, AND 9 EQUAL TO 001 IS NOT DEFINED
*----------------------------------------------------------------------------------------------------
FOUR001         JSR         BADDATA
                BRA         RETURN_FOUR

*----------------------------------------------------------------------------------------------------
* FOUR010: DISASSEMBLE THE HEXADECIMAL INSTRUCTION THAT HAS BIT 11, 10, AND 9 EQUAL TO 010
*----------------------------------------------------------------------------------------------------
FOUR010         MOVE.B      #'N', (A2)+     ;THE INSTRUCTION IS "NEG"
                MOVE.B      #'E', (A2)+
                MOVE.B      #'G', (A2)+
                MOVE.B      #TAB, (A2)+
                MOVE.B      #TAB, (A2)+
                JSR         ISNEG           ;GET EFFECTIVE ADDRESS
                BRA         RETURN_FOUR     ;RETURN TO TABLEFOUR

*----------------------------------------------------------------------------------------------------
* FOUR011: HEXADECIMAL INSTRUCTION THAT HAS BIT 11, 10, AND 9 EQUAL TO 011 IS NOT DEFINED
*----------------------------------------------------------------------------------------------------
FOUR011         JSR         BADDATA
                BRA         RETURN_FOUR

*----------------------------------------------------------------------------------------------------
* FOUR100: DISASSEMBLE THE HEXADECIMAL INSTRUCTION THAT HAS BIT 11, 10, AND 9 EQUAL TO 100
*----------------------------------------------------------------------------------------------------
FOUR100         JSR         SHIFT876
                CMPI.B      #%010, D3       ;CHECK IF THE INSTRUCTION IS ACTUALLY "MOVEM.W"
                BEQ         IFMOVEMW
                BRA         IFMOVEML        ;IF IT IS NOT, CHECK IF IT IS MOVEM.L
RETURN_FOUR100  BRA         RETURN_FOUR     ;RETURN TO TABLEFOUR

IFMOVEML        JSR         SHIFT876
                CMPI.B      #%011, D3       ;CHECK IF THE INSTRUCTION IS ACTUALLY "MOVEM.W"
                BEQ         ISMOVEML
                JSR         BADDATA
                BRA         RETURN_FOUR100
               
             
IFMOVEMW        JSR         GETMOVE
                MOVE.B      #'W', (A2)+
                MOVE.B      #TAB, (A2)+
                JSR         ISMOVEM
                BRA         RETURN_FOUR100

ISMOVEML        JSR         GETMOVE
                MOVE.B      #'L', (A2)+
                MOVE.B      #TAB, (A2)+
                JSR         ISMOVEM
                BRA         RETURN_FOUR100
            
GETMOVE         MOVE.B      #'M', (A2)+     ;INSTRUCTION IS "MOVEM.W"
                MOVE.B      #'O', (A2)+
                MOVE.B      #'V', (A2)+
                MOVE.B      #'E', (A2)+
                MOVE.B      #'M', (A2)+
                MOVE.B      #'.', (A2)+
                RTS    
*----------------------------------------------------------------------------------------------------
* FOUR001: HEXADECIMAL INSTRUCTION THAT HAS BIT 11, 10, AND 9 EQUAL TO 001 IS NOT DEFINED
*----------------------------------------------------------------------------------------------------
FOUR101         BRA         BADDATA
                BRA		    RETURN_FOUR

*----------------------------------------------------------------------------------------------------
* FOUR110: DISASSEMBLE THE HEXADECIMAL INSTRUCTION THAT HAS BIT 11, 10, AND 9 EQUAL TO 110
*----------------------------------------------------------------------------------------------------
FOUR110         BRA         FOUR100         ;THE INSTRUCTION IS "MOVEM"

*----------------------------------------------------------------------------------------------------
* FOUR111: DISASSEMBLE THE HEXADECIMAL INSTRUCTION THAT HAS BIT 11, 10, AND 9 EQUAL TO 111
*----------------------------------------------------------------------------------------------------
FOUR111         MOVE.W      D2, D3
                LSL.W       #8, D3          ;GET BIT 7 TO 0
                LSR.W       #8, D3
                CMPI.B      #%01110101, D3  ;CHECK IF THE INSTRUCTION IS ACTUALLY "RTS"
                BNE         IFJSR
                BRA         IFRTS
RETURN_FOUR111  BRA         RETURN_FOUR     ;RETURN TO TABLEFOUR

IFRTS           MOVE.B      #'R', (A2)+     ;THE INSTRUCTION IS "RTS"
                MOVE.B      #'T', (A2)+
                MOVE.B      #'S', (A2)+
                ADDQ        #2,   A6
                BRA         RETURN_FOUR111  ;RETURN BACK TO FOUR111


IFJSR           JSR         SHIFT76
                CMPI.B      #%10, D3         ;CHECK IF THE INSTRUCTION IS ACTUALLY "JSR"
                BEQ         ISJSR
                JSR         BADDATA
                BRA         RETURN_FOUR111  ;RETURN BACK TO FOUR111   
                
ISJSR           MOVE.B      #'J', (A2)+     ;THE INSTRUCTION IS "JSR"
                MOVE.B      #'S', (A2)+
                MOVE.B      #'R', (A2)+
                MOVE.B      #TAB, (A2)+
                MOVE.B      #TAB, (A2)+
                JSR         ISNEGL           ;GET EFFECTIVE ADDRESS
                BRA         RETURN_FOUR111  ;RETURN BACK TO FOUR111


*----------------------------------------------------------------------------------------------------
* TABLESIX: THIS IS SUBROUTINE JUMP TABLE. IT IS FOR DETERMINING OPMODE OF THE INSTRUCTION THAT IS
*            STARED WITH 0110
* PRECONDITION: - D2 MUST CONTAINS ORIGINAL INSTRUCTION FOR FUTHURE DETERMINING
*               - D3 MUST CONTAINS BIT 11 TO 8 OF INSTRUCTION
* POSTCONDITION: - IF THE INSTRUCTION IS DEFINED IN THE REQUIREMENT, THE STRING OF THE RESULT WILL BE
*                  STORED IN OUTPUT MEMORY REGION POINTED BY A2
*                - IF THE INSTRUCTION IS NOT IN THE REQUIREMENT, "BAD DATA" WILL BE STORED IN OUTPUT
*                  MEMORY REGION POINTED BY A2
*----------------------------------------------------------------------------------------------------
TABLESIX  		JMP         SIX0000
				JMP	    	SIX0001
				JMP	    	SIX0010
				JMP	    	SIX0011
                JMP         SIX0100
                JMP         SIX0101
				JMP	    	SIX0110
				JMP	    	SIX0111
                JMP         SIX1000
				JMP	    	SIX1001
				JMP	    	SIX1010
				JMP	    	SIX1011
                JMP         SIX1100
                JMP         SIX1101
				JMP	    	SIX1110
				JMP	    	SIX1111
RETURN_SIX    	RTS

*----------------------------------------------------------------------------------------------------
* SIX0000: DISASSEMBLE THE HEXADECIMAL INSTRUCTION THAT HAS BIT 11 TO 8 EQUAL TO 0000
*----------------------------------------------------------------------------------------------------
SIX0000       	MOVE.B		#'B', (A2)+     ;THE INSTRUCTION IS "BRA"
				MOVE.B      #'R', (A2)+ 
                MOVE.B      #'A', (A2)+
                MOVE.B      #TAB, (A2)+
                MOVE.B      #TAB, (A2)+
                JSR         ISBRA           ;GET EFFECTIVE ADDRESS
                BRA         RETURN_SIX      ;RETURN TO TABLESIX

*----------------------------------------------------------------------------------------------------
* SIX0001: HEXADECIMAL INSTRUCTION THAT HAS BIT 11 TO 8 EQUAL TO 0001 IS NOT DEFINED
*----------------------------------------------------------------------------------------------------
SIX0001			JSR         BADDATA
                BRA		    RETURN_SIX

*----------------------------------------------------------------------------------------------------
* SIX0010: HEXADECIMAL INSTRUCTION THAT HAS BIT 11 TO 8 EQUAL TO 0010 IS NOT DEFINED
*----------------------------------------------------------------------------------------------------
SIX0010			JSR         BADDATA
                BRA		    RETURN_SIX

*----------------------------------------------------------------------------------------------------
* SIX0011: HEXADECIMAL INSTRUCTION THAT HAS BIT 11 TO 8 EQUAL TO 0011 IS NOT DEFINED
*----------------------------------------------------------------------------------------------------
SIX0011			JSR         BADDATA
                BRA		    RETURN_SIX

*----------------------------------------------------------------------------------------------------
* SIX0100: DISASSEMBLE THE HEXADECIMAL INSTRUCTION THAT HAS BIT 11 TO 8 EQUAL TO 0100
*----------------------------------------------------------------------------------------------------
SIX0100       	MOVE.B      #'B', (A2)+     ;THE INSTRUCTION IS "BCC"
                MOVE.B      #'C', (A2)+
                MOVE.B      #'C', (A2)+
                MOVE.B      #TAB, (A2)+
                MOVE.B      #TAB, (A2)+
                JSR         ISBRA           ;GET EFFECTIVE ADDRESS
                BRA         RETURN_SIX      ;RETURN TO TABLESIX

*----------------------------------------------------------------------------------------------------
* SIX0101: DISASSEMBLE THE HEXADECIMAL INSTRUCTION THAT HAS BIT 11 TO 8 EQUAL TO 0101
*----------------------------------------------------------------------------------------------------
SIX0101       	MOVE.B      #'B', (A2)+     ;THE INSTRUCTION IS "BCS"
                MOVE.B      #'C', (A2)+
                MOVE.B      #'S', (A2)+
                MOVE.B      #TAB, (A2)+
                MOVE.B      #TAB, (A2)+
                JSR         ISBRA           ;GET EFFECTIVE ADDRESS
                BRA         RETURN_SIX      ;RETURN TO TABLESIX

*----------------------------------------------------------------------------------------------------
* SIX0110: HEXADECIMAL INSTRUCTION THAT HAS BIT 11 TO 8 EQUAL TO 0110 IS NOT DEFINED
*----------------------------------------------------------------------------------------------------
SIX0110			JSR         BADDATA
                BRA		    RETURN_SIX

*----------------------------------------------------------------------------------------------------
* SIX0111: HEXADECIMAL INSTRUCTION THAT HAS BIT 11 TO 8 EQUAL TO 0111 IS NOT DEFINED
*----------------------------------------------------------------------------------------------------
SIX0111			JSR         BADDATA
                BRA		    RETURN_SIX

*----------------------------------------------------------------------------------------------------
* SIX1000: DISASSEMBLE THE HEXADECIMAL INSTRUCTION THAT HAS BIT 11 TO 8 EQUAL TO 1000
*----------------------------------------------------------------------------------------------------
SIX1000      	MOVE.B      #'B', (A2)+     ;THE INSTRUCTION IS "BVC"
                MOVE.B      #'V', (A2)+ 
                MOVE.B      #'C', (A2)+
                MOVE.B      #TAB, (A2)+
                MOVE.B      #TAB, (A2)+
                JSR         ISBRA           ;GET EFFECTIVE ADDRESS
                BRA         RETURN_SIX      ;RETURN TO TABLESIX
                
*----------------------------------------------------------------------------------------------------
* SIX1001: HEXADECIMAL INSTRUCTION THAT HAS BIT 11 TO 8 EQUAL TO 1001 IS NOT DEFINED
*----------------------------------------------------------------------------------------------------
SIX1001			JSR         BADDATA
                BRA		    RETURN_SIX

*----------------------------------------------------------------------------------------------------
* SIX1010: HEXADECIMAL INSTRUCTION THAT HAS BIT 11 TO 8 EQUAL TO 1010 IS NOT DEFINED
*----------------------------------------------------------------------------------------------------
SIX1010			JSR         BADDATA
                BRA		    RETURN_SIX

*----------------------------------------------------------------------------------------------------
* SIX1011: HEXADECIMAL INSTRUCTION THAT HAS BIT 11 TO 8 EQUAL TO 1011 IS NOT DEFINED
*----------------------------------------------------------------------------------------------------
SIX1011		    JSR          BADDATA
                BRA		     RETURN_SIX


*----------------------------------------------------------------------------------------------------
* SIX1100: DISASSEMBLE THE HEXADECIMAL INSTRUCTION THAT HAS BIT 11 TO 8 EQUAL TO 1100
*----------------------------------------------------------------------------------------------------
SIX1100       	MOVE.B      #'B', (A2)+     ;THE INSTRUCTION IS "BEG"
                MOVE.B      #'G', (A2)+
                MOVE.B      #'E', (A2)+
                MOVE.B      #TAB, (A2)+
                MOVE.B      #TAB, (A2)+
                JSR         ISBRA           ;GET EFFECTIVE ADDRESS
                BRA         RETURN_SIX      ;RETURN TO TABLESIX

*----------------------------------------------------------------------------------------------------
* SIX1101: DISASSEMBLE THE HEXADECIMAL INSTRUCTION THAT HAS BIT 11 TO 8 EQUAL TO 1101
*----------------------------------------------------------------------------------------------------
SIX1101         MOVE.B      #'B', (A2)+     ;THE INSTUCTION IS "BLT"
                MOVE.B      #'L', (A2)+
                MOVE.B      #'T', (A2)+
                MOVE.B      #TAB, (A2)+
                MOVE.B      #TAB, (A2)+
                JSR         ISBRA           ;GET EFFECTIVE ADDRESS
                BRA         RETURN_SIX      ;RETURN TO TABLESIX

*----------------------------------------------------------------------------------------------------
* SIX1110: HEXADECIMAL INSTRUCTION THAT HAS BIT 11 TO 8 EQUAL TO 1110 IS NOT DEFINED
*----------------------------------------------------------------------------------------------------
SIX1110			JSR         BADDATA
                BRA			RETURN_SIX

*----------------------------------------------------------------------------------------------------
* SIX1111: HEXADECIMAL INSTRUCTION THAT HAS BIT 11 TO 8 EQUAL TO 1111 IS NOT DEFINED
*----------------------------------------------------------------------------------------------------
SIX1111        JSR          BADDATA
               BRA		    RETURN_SIX


*----------------------------------------------------------------------------------------------------
* TABLEELEVEN: THIS IS SUBROUTINE JUMP TABLE. IT IS FOR DETERMINING OPMODE OF THE INSTRUCTION THAT IS
*              STARED WITH 1011
* PRECONDITION: - D2 MUST CONTAINS ORIGINAL INSTRUCTION FOR FUTHURE DETERMINING
*               - D3 MUST CONTAINS BIT 8, 7, AND 6 OF INSTRUCTION
* POSTCONDITION: - IF THE INSTRUCTION IS DEFINED IN THE REQUIREMENT, THE STRING OF THE RESULT WILL BE
*                  STORED IN OUTPUT MEMORY REGION POINTED BY A2
*                - IF THE INSTRUCTION IS NOT IN THE REQUIREMENT, "BAD DATA" WILL BE STORED IN OUTPUT
*                  MEMORY REGION POINTED BY A2
*----------------------------------------------------------------------------------------------------
TABLEELEVEN		JMP			ELEVEN000
				JMP			ELEVEN001
				JMP			ELEVEN010
				JMP			ELEVEN011
				JMP			ELEVEN100
				JMP			ELEVEN101
				JMP			ELEVEN110
				JMP			ELEVEN111
RETURN_ELEVEN	RTS
		
*----------------------------------------------------------------------------------------------------
* ELEVEN000: DISASSEMBLE HEXADECIMAL INSTRUCTION THAT HAS BIT 8, 7, AND 6 EQUAL TO 000
*----------------------------------------------------------------------------------------------------		
ELEVEN000		MOVE.B		#'C', (A2)+
				MOVE.B		#'M', (A2)+
				MOVE.B		#'P', (A2)+
				MOVE.B		#'.', (A2)+
				MOVE.B		#'B', (A2)+
				MOVE.B		#TAB, (A2)+
				JSR			ISOR
				BRA			RETURN_ELEVEN
		
*----------------------------------------------------------------------------------------------------
* ELEVEN001: DISASSEMBLE HEXADECIMAL INSTRUCTION THAT HAS BIT 8, 7, AND 6 EQUAL TO 001
*----------------------------------------------------------------------------------------------------						
ELEVEN001		MOVE.B		#'C', (A2)+
				MOVE.B		#'M', (A2)+
				MOVE.B		#'P', (A2)+
				MOVE.B		#'.', (A2)+
				MOVE.B		#'W', (A2)+
				MOVE.B		#TAB, (A2)+
				JSR			ISOR
				BRA			RETURN_ELEVEN
			
*----------------------------------------------------------------------------------------------------
* ELEVEN010: DISASSEMBLE HEXADECIMAL INSTRUCTION THAT HAS BIT 8, 7, AND 6 EQUAL TO 010
*----------------------------------------------------------------------------------------------------			
ELEVEN010		MOVE.B		#'C', (A2)+
				MOVE.B		#'M', (A2)+
				MOVE.B		#'P', (A2)+
				MOVE.B		#'.', (A2)+
				MOVE.B		#'L', (A2)+
				MOVE.B		#TAB, (A2)+
				JSR			ISORL
				BRA			RETURN_ELEVEN

*----------------------------------------------------------------------------------------------------
* ELEVEN011: HEXADECIMAL INSTRUCTION THAT HAS BIT 8, 7, AND 6 EQUAL TO 011 IS NOT DEFINED
*----------------------------------------------------------------------------------------------------	
ELEVEN011		JSR         BADDATA
                BRA			RETURN_ELEVEN
		
*----------------------------------------------------------------------------------------------------
* ELEVEN100: DISASSEMBLE HEXADECIMAL INSTRUCTION THAT HAS BIT 8, 7, AND 6 EQUAL TO 100
*----------------------------------------------------------------------------------------------------		
ELEVEN100		MOVE.B		#'E', (A2)+
				MOVE.B		#'O', (A2)+
				MOVE.B		#'R', (A2)+
				MOVE.B		#'.', (A2)+
				MOVE.B		#'B', (A2)+
				MOVE.B		#TAB, (A2)+
				JSR			ISEOR
				BRA			RETURN_ELEVEN
		
*----------------------------------------------------------------------------------------------------
* ELEVEN101: DISASSEMBLE HEXADECIMAL INSTRUCTION THAT HAS BIT 8, 7, AND 6 EQUAL TO 101
*----------------------------------------------------------------------------------------------------				
ELEVEN101		MOVE.B		#'E', (A2)+
				MOVE.B		#'O', (A2)+
				MOVE.B		#'R', (A2)+
				MOVE.B		#'.', (A2)+
				MOVE.B		#'W', (A2)+
				MOVE.B		#TAB, (A2)+
				JSR			ISEOR
				BRA			RETURN_ELEVEN
		
*----------------------------------------------------------------------------------------------------
* ELEVEN110: DISASSEMBLE HEXADECIMAL INSTRUCTION THAT HAS BIT 8, 7, AND 6 EQUAL TO 110
*----------------------------------------------------------------------------------------------------				
ELEVEN110		MOVE.B		#'E', (A2)+
				MOVE.B		#'O', (A2)+
				MOVE.B		#'R', (A2)+
				MOVE.B		#'.', (A2)+
				MOVE.B		#'L', (A2)+
				MOVE.B		#TAB, (A2)+
				JSR			ISEORL
				BRA			RETURN_ELEVEN

*----------------------------------------------------------------------------------------------------
* ELEVEN111: HEXADECIMAL INSTRUCTION THAT HAS BIT 8, 7, AND 6 EQUAL TO 111 IS NOT DEFINED
*----------------------------------------------------------------------------------------------------					
ELEVEN111		JSR         BADDATA
                BRA			RETURN_ELEVEN



*----------------------------------------------------------------------------------------------------
* TABLETHIRTEEN: THIS IS SUBROUTINE JUMP TABLE. IT IS FOR DETERMINING OPMODE OF THE INSTRUCTION THAT
*                IS STARED WITH 1101
* PRECONDITION: - D2 MUST CONTAINS ORIGINAL INSTRUCTION FOR FUTHURE DETERMINING
*               - D3 MUST CONTAINS BIT 8, 7, AND 6 OF INSTRUCTION
* POSTCONDITION: - IF THE INSTRUCTION IS DEFINED IN THE REQUIREMENT, THE STRING OF THE RESULT WILL BE
*                  STORED IN OUTPUT MEMORY REGION POINTED BY A2
*                - IF THE INSTRUCTION IS NOT IN THE REQUIREMENT, "BAD DATA" WILL BE STORED IN OUTPUT
*                  MEMORY REGION POINTED BY A2
*----------------------------------------------------------------------------------------------------
TABLETHIRTEEN   JMP         THIRTEEN000
                JMP         THIRTEEN001
                JMP         THIRTEEN010
                JMP         THIRTEEN011
                JMP         THIRTEEN100
                JMP         THIRTEEN101
                JMP         THIRTEEN110
                JMP         THIRTEEN111
RETURN_THIRTEEN RTS

*----------------------------------------------------------------------------------------------------
* THIRTEEN000: DISASSEMBLE HEXADECIMAL INSTRUCTION THAT HAS BIT 8, 7, AND 6 EQUAL TO 000
*----------------------------------------------------------------------------------------------------				
THIRTEEN000     MOVE.B		#'.', (A2)+
                MOVE.B		#'B', (A2)+
                MOVE.B      #TAB, (A2)+
                JSR         ISOR
                BRA         RETURN_THIRTEEN

*----------------------------------------------------------------------------------------------------
* THIRTEEN001: DISASSEMBLE HEXADECIMAL INSTRUCTION THAT HAS BIT 8, 7, AND 6 EQUAL TO 001
*----------------------------------------------------------------------------------------------------	
THIRTEEN001     MOVE.B		#'.', (A2)+
                MOVE.B		#'W', (A2)+
                MOVE.B      #TAB, (A2)+
                JSR         ISOR
                BRA         RETURN_THIRTEEN

*----------------------------------------------------------------------------------------------------
* THIRTEEN010: DISASSEMBLE HEXADECIMAL INSTRUCTION THAT HAS BIT 8, 7, AND 6 EQUAL TO 010
*----------------------------------------------------------------------------------------------------	
THIRTEEN010     MOVE.B		#'.', (A2)+
                MOVE.B		#'L', (A2)+
                MOVE.B      #TAB, (A2)+
                JSR         ISORL
                BRA         RETURN_THIRTEEN

*----------------------------------------------------------------------------------------------------
* THIRTEEN011: DISASSEMBLE HEXADECIMAL INSTRUCTION THAT HAS BIT 8, 7, AND 6 EQUAL TO 011
*----------------------------------------------------------------------------------------------------	
THIRTEEN011     MOVE.B      #'A', (A2)+
                MOVE.B		#'.', (A2)+
                MOVE.B		#'W', (A2)+
                MOVE.B      #TAB, (A2)+
                JSR         ISADDA
                BRA         RETURN_THIRTEEN

*----------------------------------------------------------------------------------------------------
* THIRTEEN100: DISASSEMBLE HEXADECIMAL INSTRUCTION THAT HAS BIT 8, 7, AND 6 EQUAL TO 100
*----------------------------------------------------------------------------------------------------	
THIRTEEN100     MOVE.B		#'.', (A2)+
                MOVE.B		#'B', (A2)+
                MOVE.B      #TAB, (A2)+
                JSR         ISOR
                BRA         RETURN_THIRTEEN

*----------------------------------------------------------------------------------------------------
* THIRTEEN101: DISASSEMBLE HEXADECIMAL INSTRUCTION THAT HAS BIT 8, 7, AND 6 EQUAL TO 101
*----------------------------------------------------------------------------------------------------	
THIRTEEN101     MOVE.B		#'.', (A2)+
                MOVE.B		#'W', (A2)+
                MOVE.B      #TAB, (A2)+
                JSR         ISOR
                BRA         RETURN_THIRTEEN

*----------------------------------------------------------------------------------------------------
* THIRTEEN110: DISASSEMBLE HEXADECIMAL INSTRUCTION THAT HAS BIT 8, 7, AND 6 EQUAL TO 110
*----------------------------------------------------------------------------------------------------	
THIRTEEN110     MOVE.B		#'.', (A2)+
                MOVE.B		#'L', (A2)+
                MOVE.B      #TAB, (A2)+
                JSR         ISOR
                BRA         RETURN_THIRTEEN

*----------------------------------------------------------------------------------------------------
* THIRTEEN111: DISASSEMBLE HEXADECIMAL INSTRUCTION THAT HAS BIT 8, 7, AND 6 EQUAL TO 111
*----------------------------------------------------------------------------------------------------	
THIRTEEN111     MOVE.B      #'A', (A2)+
                MOVE.B		#'.', (A2)+
                MOVE.B		#'L', (A2)+
                MOVE.B      #TAB, (A2)+
                JSR         ISADDAL
                BRA         RETURN_THIRTEEN

*----------------------------------------------------------------------------------------------------
* TABLEFOURTEEN: THIS IS SUBROUTINE JUMP TABLE. IT IS FOR DETERMINING OPMODE OF THE INSTRUCTION THAT
*                IS STARED WITH 1110
* PRECONDITION: - D2 MUST CONTAINS ORIGINAL INSTRUCTION FOR FUTHURE DETERMINING
*               - D3 MUST CONTAINS BIT 10 AND 9 / 4 AND 3 OF INSTRUCTION
* POSTCONDITION: - IF THE INSTRUCTION IS DEFINED IN THE REQUIREMENT, THE STRING OF THE RESULT WILL BE
*                  STORED IN OUTPUT MEMORY REGION POINTED BY A2
*                - IF THE INSTRUCTION IS NOT IN THE REQUIREMENT, "BAD DATA" WILL BE STORED IN OUTPUT
*                  MEMORY REGION POINTED BY A2
*----------------------------------------------------------------------------------------------------
TABLEFOURTEEN	JMP			FOURTEEN00
				JMP			FOURTEEN01
				JMP			FOURTEEN10
				JMP			FOURTEEN11
RETURN_FOURTEEN	RTS
		
*----------------------------------------------------------------------------------------------------
* THIRTEEN00: DISASSEMBLE HEXADECIMAL INSTRUCTION THAT HAS BIT 10 AND 9 / 4 AND 3 EQUAL TO 00
*----------------------------------------------------------------------------------------------------			
FOURTEEN00		MOVE.B		#'A', (A2)+
				MOVE.B		#'S', (A2)+
				BRA			RETURN_FOURTEEN
		
*----------------------------------------------------------------------------------------------------
* THIRTEEN01: DISASSEMBLE HEXADECIMAL INSTRUCTION THAT HAS BIT 10 AND 9 / 4 AND 3 EQUAL TO 01
*----------------------------------------------------------------------------------------------------			
FOURTEEN01		MOVE.B		#'L', (A2)+
				MOVE.B		#'S', (A2)+
				BRA			RETURN_FOURTEEN
			
*----------------------------------------------------------------------------------------------------
* THIRTEEN10: HEXADECIMAL INSTRUCTION THAT HAS BIT 10 AND 9 / 4 AND 3 EQUAL TO 10 IS NOT DEFINED
*----------------------------------------------------------------------------------------------------		
FOURTEEN10		JSR			BADDATA
                BRA			RETURN_FOURTEEN
			
*----------------------------------------------------------------------------------------------------
* THIRTEEN11: DISASSEMBLE HEXADECIMAL INSTRUCTION THAT HAS BIT 10 AND 9 / 4 AND 3 EQUAL TO 11
*----------------------------------------------------------------------------------------------------		
FOURTEEN11		MOVE.B		#'R', (A2)+
				MOVE.B		#'O', (A2)+
				BRA			RETURN_FOURTEEN


*----------------------------------------------------------------------------------------------------
* GET_OPMODE: THIS IS SUBROUTINE FOR DETERMINING OPMODE OF THE INSTRUCTION OR AND SUB ONLY.
* PRECONDITION: - D2 MUST CONTAINS ORIGINAL INSTRUCTION FOR FUTHURE DETERMINING
* POSTCONDITION: - IF THE OPMODE IS DEFINED IN THE REQUIREMENT, THE STRING OF THE RESULT WILL BE
*                  STORED IN OUTPUT MEMORY REGION POINTED BY A2
*                - IF THE OPMODE IS NOT IN THE REQUIREMENT, THE OPMODE INFORMATION WILL BE IGNORED
*----------------------------------------------------------------------------------------------------
GET_OPMODE      JSR         SHIFT876
                MULU        #6, D3
                LEA         TABLEOPMODE, A3
                JSR         0(A3, D3)
                RTS

*----------------------------------------------------------------------------------------------------
* TABLEOPMODE: THIS IS FUNCTION CONTAINS LOOKS UP TABLE FOR DETERMINING THE OPMODE OF THE INSTRUCTION
*----------------------------------------------------------------------------------------------------
TABLEOPMODE     JMP         MODE000
                JMP         MODE001
                JMP         MODE010
                JMP         MODE011
                JMP         MODE100
                JMP         MODE101
                JMP         MODE110
                JMP         MODE111
RETURN_OPMODE   RTS
                
*----------------------------------------------------------------------------------------------------
* MODE000: DISASSEMBLE HEXADECIMAL INSTRUCTION THAT HAS OPMODE BITS EQUAL TO 000
*----------------------------------------------------------------------------------------------------	
MODE000      	MOVE.B      #'.', (A2)+
                MOVE.B      #'B', (A2)+
                MOVE.B      #TAB, (A2)+
                JSR         ISOR
                BRA         RETURN_OPMODE
				
*----------------------------------------------------------------------------------------------------
* MODE001: DISASSEMBLE HEXADECIMAL INSTRUCTION THAT HAS OPMODE BITS EQUAL TO 001
*----------------------------------------------------------------------------------------------------	
MODE001      	MOVE.B      #'.', (A2)+
                MOVE.B      #'W', (A2)+
                MOVE.B      #TAB, (A2)+
                JSR         ISOR
                BRA         RETURN_OPMODE
				
*----------------------------------------------------------------------------------------------------
* MODE010: DISASSEMBLE HEXADECIMAL INSTRUCTION THAT HAS OPMODE BITS EQUAL TO 010
*----------------------------------------------------------------------------------------------------	
MODE010      	MOVE.B      #'.', (A2)+
                MOVE.B      #'L', (A2)+
                MOVE.B      #TAB, (A2)+
                JSR         ISORL
                BRA         RETURN_OPMODE
                
*----------------------------------------------------------------------------------------------------
* MODE011: HEXADECIMAL INSTRUCTION THAT HAS OPMODE BITS EQUAL TO 011 IS NOT DEFINED
*----------------------------------------------------------------------------------------------------
MODE011			BRA			RETURN_OPMODE

*----------------------------------------------------------------------------------------------------
* MODE100: DISASSEMBLE HEXADECIMAL INSTRUCTION THAT HAS OPMODE BITS EQUAL TO 100
*----------------------------------------------------------------------------------------------------	
MODE100			MOVE.B      #'.', (A2)+
                MOVE.B      #'B', (A2)+
                MOVE.B      #TAB, (A2)+
                JSR         ISOR
                BRA         RETURN_OPMODE

*----------------------------------------------------------------------------------------------------
* MODE101: DISASSEMBLE HEXADECIMAL INSTRUCTION THAT HAS OPMODE BITS EQUAL TO 101
*----------------------------------------------------------------------------------------------------	
MODE101      	MOVE.B      #'.', (A2)+
                MOVE.B      #'W', (A2)+
                MOVE.B      #TAB, (A2)+
                JSR         ISOR
                BRA         RETURN_OPMODE
			
*----------------------------------------------------------------------------------------------------
* MODE110: DISASSEMBLE HEXADECIMAL INSTRUCTION THAT HAS OPMODE BITS EQUAL TO 110
*----------------------------------------------------------------------------------------------------	
MODE110      	MOVE.B      #'.', (A2)+
                MOVE.B      #'L', (A2)+
                MOVE.B      #TAB, (A2)+
                JSR         ISORL
                BRA         RETURN_OPMODE
				
*----------------------------------------------------------------------------------------------------
* MODE111: HEXADECIMAL INSTRUCTION THAT HAS OPMODE BITS EQUAL TO 111 IS NOT DEFINED
*----------------------------------------------------------------------------------------------------
MODE111			BRA			RETURN_OPMODE
        
        
*----------------------------------------------------------------------------------------------------
* GET_SIZE: THIS IS SUBROUTINE FOR DETERMINING SIZE OF THE INSTRUCTION.
* PRECONDITION: - D2 MUST CONTAINS ORIGINAL INSTRUCTION FOR FUTHURE DETERMINING
* POSTCONDITION: - IF THE SIZE IS DEFINED IN THE REQUIREMENT, THE STRING OF THE RESULT WILL BE STORED
*                  IN OUTPUT MEMORY REGION POINTED BY A2
*                - IF THE OPMODE IS NOT IN THE REQUIREMENT, THE OPMODE INFORMATION WILL BE IGNORED
*----------------------------------------------------------------------------------------------------        
GET_SIZE        JSR         SHIFT76
                MULU        #6, D3
                LEA         TABLESIZE, A3
                JSR         0(A3, D3)
                RTS

*----------------------------------------------------------------------------------------------------
* TABLESIZE: THIS IS FUNCTION CONTAINS LOOKS UP TABLE FOR DETERMINING THE SIZE OF THE INSTRUCTION
*----------------------------------------------------------------------------------------------------
TABLESIZE       JMP         SIZE00
                JMP         SIZE01
                JMP         SIZE10
                JMP         SIZE11
RETURN_SIZE     RTS
                
*----------------------------------------------------------------------------------------------------
* SIZE00: DISASSEMBLE HEXADECIMAL INSTRUCTION THAT HAS SIZE BITS EQUAL TO 00
*----------------------------------------------------------------------------------------------------
SIZE00 	        MOVE.B      #'.', (A2)+
                MOVE.B      #'B', (A2)+
                BRA         RETURN_SIZE
                
*----------------------------------------------------------------------------------------------------
* SIZE01: DISASSEMBLE HEXADECIMAL INSTRUCTION THAT HAS SIZE BITS EQUAL TO 01
*----------------------------------------------------------------------------------------------------                
SIZE01			MOVE.B      #'.', (A2)+
                MOVE.B      #'W', (A2)+
                BRA         RETURN_SIZE
				
*----------------------------------------------------------------------------------------------------
* SIZE10: DISASSEMBLE HEXADECIMAL INSTRUCTION THAT HAS SIZE BITS EQUAL TO 10
*----------------------------------------------------------------------------------------------------
SIZE10      	MOVE.B      #'.', (A2)+
                MOVE.B      #'L', (A2)+
                BRA         RETURN_SIZE
                
*----------------------------------------------------------------------------------------------------
* SIZE11: HEXADECIMAL INSTRUCTION THAT HAS OPMODE BITS EQUAL TO 11 IS NOT DEFINED
*----------------------------------------------------------------------------------------------------
SIZE11			BRA			RETURN_SIZE


*----------------------------------------------------------------------------------------------------
* GET_DIRECTION: THIS IS SUBROUTINE FOR DETERMINING DIRECTION OF THE SHIFTING AND ROTAING INSTRUCTION
* PRECONDITION: - D2 MUST CONTAINS ORIGINAL INSTRUCTION FOR FUTHURE DETERMINING
* POSTCONDITION: - THE STRING OF THE RESULT WILL BE STORED IN OUTPUT MEMORY REGION POINTED BY A2
*----------------------------------------------------------------------------------------------------
GET_DIRECTION	JSR         SHIFT8          ;GET BIT 8TH TO DETERMIND DIRECTION
				CMPI.B		#%0, D3
				BEQ			RIGHT           ;IF IT IS 0, IT IS RIGHT
				BRA			LEFT            ;OTHERWISE, IT IS LEFT
RETURN_DR		RTS
				
*----------------------------------------------------------------------------------------------------
* LEFT: DISASSEMBLE HEXADECIMAL INSTRUCTION THAT HAS DIRECTION BIT EQUAL TO 1
*----------------------------------------------------------------------------------------------------
LEFT			MOVE.B		#'L', (A2)+
				BRA			RETURN_DR
				
*----------------------------------------------------------------------------------------------------
* LEFT: DISASSEMBLE HEXADECIMAL INSTRUCTION THAT HAS DIRECTION BIT EQUAL TO 0
*----------------------------------------------------------------------------------------------------
RIGHT			MOVE.B		#'R', (A2)+
				BRA			RETURN_DR

				
*----------------------------------------------------------------------------------------------------
* SHIFT76: SHIFT BITS OF A WORD SIZE DATA TO GET BIT 7, AND 6 OF THE DATA
* PRECONDITION: - D2 MUST STORE AN ORIGINAL DATA
*               - D3 MUST NOT BE IN USED
* POSTCONDITION: BIT 7, AND 6 OF THE DATA WILL BE STORE IN D3
*----------------------------------------------------------------------------------------------------            
SHIFT76         MOVE.W      D2, D3
                LSL.W       #8, D3          ;GET BIT 7 AND 6
                LSR.W       #8, D3
                LSR.W       #6, D3
                RTS
                
                
*----------------------------------------------------------------------------------------------------
* SHIFT8: SHIFT BITS OF A WORD SIZE DATA TO GET BIT 8 OF THE DATA
* PRECONDITION: - D2 MUST STORE AN ORIGINAL DATA
*               - D3 MUST NOT BE IN USED
* POSTCONDITION: BIT 8 OF THE DATA WILL BE STORE IN D3
*----------------------------------------------------------------------------------------------------            
SHIFT8          MOVE.W      D2, D3
                LSL.W       #7, D3          ;GET THE 8TH BIT
                LSR.W       #8, D3
                LSR.W       #7, D3
				RTS

*----------------------------------------------------------------------------------------------------
* SHIFT876: SHIFT BITS OF A WORD SIZE DATA TO GET BIT 8, 7, AND 6 OF THE DATA
* PRECONDITION: - D2 MUST STORE AN ORIGINAL DATA
*               - D3 MUST NOT BE IN USED
* POSTCONDITION: BIT 8, 7, AND 6 OF THE DATA WILL BE STORE IN D3
*----------------------------------------------------------------------------------------------------
SHIFT876        MOVE.W      D2, D3
                LSL.W       #7, D3          ;GET BIT 8, 7 AND 6
                LSR.W       #8, D3
                LSR.W       #5, D3
                RTS
                
                				
*----------------------------------------------------------------------------------------------------
* BADDATA: APPEND "BAD DATA" TO OUTPUT MEMORY REGION POINTED BY A2
* PRECONDITION: NONE
* POSTCONDITION: "BAD DATA" WILL BE STORED IN OUTPUT MEMORY REGION POINTED BY A2
*----------------------------------------------------------------------------------------------------
BAD_DATA        JSR         BADDATA
                BRA         FINISH

*----------------------------------------------------------------------------------------------------
* BADDATA: APPEND "BAD DATA" TO OUTPUT MEMORY REGION POINTED BY A2
*----------------------------------------------------------------------------------------------------
BADDATA         MOVE.B      #'B', (A2)+
                MOVE.B      #'A', (A2)+
                MOVE.B      #'D', (A2)+
                MOVE.B      #' ', (A2)+
                MOVE.B      #'D', (A2)+
                MOVE.B      #'A', (A2)+
                MOVE.B      #'T', (A2)+
                MOVE.B      #'A', (A2)+
                ADDQ        #2,   A6
                RTS

            
            
*---------------------------------------------------------------------------------------------------------
*IS SHIFTY STUFF    TO BE CALLED IF CURRENT INSTRUCTION POINTED TO BY A6 IS A KNOWN LSR,LSL, ASL, ASL, ROR, ROL
*
*PRE CONDITIONS -  A6 POINTS TO START OF LEA COMMAND
*
*POST CONDITIONS - A2 POINTS TO NEXT AVAILABLE LOCATION TO ADD NEXT ASCII INSTRUCTION. DO NOT INCREMENT
*                  A2, ALREADY DONE! A6 POINTS TO START OF NEXT COMMAND OR AND OF FILE IF ALL COMMANDS HAVE
*                  BEEN DIASSEMBLED. DO NOT INC A6, ALREADY DONE. ASCII STRINGS HAVE BEEN ADDED TO (A2) IF
*                  NO ERRORS OCCURED. THE STATE OF ALL OTHER REGISTERS IS EXACTLY HOW THEY WERE BEFORE CALLING THIS
*---------------------------------------------------------------------------------------------------------
ISSHIFTYSTUFF    MOVEM.L     D0-D7/A0/A1/A3-A5, -(A7)          *SAVE JEENS REGISTERS AT $400
                 JSR         CLRALLDREG                           
                 MOVE.W      (A6)+, D0                        *GET CURRENT OP CODE DATA TO D7
                 JSR         SHIFTSIZE
                 JSR         GETMOVEREG
                 JSR         SWAP
                 CMPI.B      #3, D4
                 BEQ         MEMORYSHIFT                           *SHIFT FOR I/R
                 CMPI.B      #3, D3
                 BLE         SETUP 
                 MOVE.B      #0, D1
                 MOVE.B      #0, D3
                 JSR         APPENDEA
RTN_SETUP        MOVE.B      #',', (A2)+                      *ADD SPACE BETWEEN ADDRESSES
                 MOVE.B      #' ', (A2)+                      *ADD COMMA BETWEEN ADDRESSES
                 JSR         SWAP
                 JSR         APPENDEA
RTN_MEMSHIFT     MOVEM.L     (A7)+, D0-D7/A0/A1/A3-A5
                 MOVE.L      #0, D6
                 MOVE.L      #0, D7
                 RTS

*-----------------------------------------------------------------------------------------------------------
*SHIFT SIZE - SHIFT DATA TO RETRIEVE SIZE DATA
*-----------------------------------------------------------------------------------------------------------                 
SHIFTSIZE        MOVE.W     D0, D4
                 LSL.W      #8, D4
                 LSR.W      #8, D4
                 LSR.W      #6, D4
                 RTS

*-----------------------------------------------------------------------------------------------------------
*MEMORY SHIFT - MEMORY SHIFT DETERMINED, APPEND APPROPRIATELY
*-----------------------------------------------------------------------------------------------------------                 
MEMORYSHIFT     JSR         SHIFTMEM
                JMP         RTN_MEMSHIFT
 
*-----------------------------------------------------------------------------------------------------------
*SHIFT MEMORY - MEMORY SHIFT DETERMINED, CHECK FOR ERRORS AND APPEND STRING TO A2
*-----------------------------------------------------------------------------------------------------------               
SHIFTMEM        JSR         SWAP
                JSR         APPENDEA
                RTS

*-----------------------------------------------------------------------------------------------------------
*SET UP - SETS UP REGISTER DATA TO BE PRINTED
*-----------------------------------------------------------------------------------------------------------                
SETUP           MOVE.B      #'#', (A2)+
                MOVE.B      #0, D1
                MOVE.B      #0, D3
                CMPI.B      #0, D0
                BEQ         MAKEZEROEIGHT
RTN_ZE          JSR         APPENDDISPLACE
                JMP         RTN_SETUP
MAKEZEROEIGHT   ADDI.W      #8, D0 
                JMP         RTN_ZE


*---------------------------------------------------------------------------------------------------------
*IS MULS           TO BE CALLED IF CURRENT INSTRUCTION POINTED TO BY A6 IS A KNOWN SUBQ COMMAND. APPENDS 
*IS MULS           TO BE CALLED IF CURRENT INSTRUCTION POINTED TO BY A6 IS A KNOWN MULS COMMAND. APPENDS 
*                  ADDRESSING MODES TO END OF CURRENT COMMAND STRING
*
*PRE CONDITIONS -  A6 POINTS TO START OF MOVE COMMAND. A2 POINTS TO LOCATION AFTER MOVE STRING AND TAB
*
*POST CONDITIONS - A6 POINTS TO NEXT COMMAND TO BE DISASSEMBLED. A2 POINTS TO NEXT LOCATION TO BE APPENDED,
*                  DELIMETER SHOULD BE ADDED TO THIS LOCATION IMMEDIATELY. ALL OTHER ADDRESS AND DATA 
*                  REGISTERS ARE PRESERVED
*---------------------------------------------------------------------------------------------------------   
ISMULS       MOVEM.L     D0-D7/A0/A1/A3-A5, -(A7)          *SAVE JEENS REGISTERS AT $400
             JSR         CLRALLDREG                       *CLEAR REGISTERS FOR USE
             MOVE.W      (A6)+, D0
             JSR         GETMOVEREG                                               
             MOVE.B      #0, D3
             JSR         SWAP
             JSR         SWAP
             JSR         APPENDEA 
             JSR         SWAP                             *ELSE APPEND SRC AE
             MOVE.B      #',', (A2)+
             MOVE.B      #' ', (A2)+
             JSR         APPENDEA                         *APPEND DESTINATION EA
RTN_BADMUL   MOVEM.L     (A7)+, D0-D7/A0/A1/A3-A5          *RESTORE JEENS REGISTERS
             MOVE.L      #0, D6
             MOVE.L      #0, D7
             RTS   
             
*---------------------------------------------------------------------------------------------------------
*IS SUBQ           TO BE CALLED IF CURRENT INSTRUCTION POINTED TO BY A6 IS A KNOWN SUBQ COMMAND. APPENDS 
*                  ADDRESSING MODES TO END OF CURRENT COMMAND STRING
*
*PRE CONDITIONS -  A6 POINTS TO START OF MOVE COMMAND. A2 POINTS TO LOCATION AFTER MOVE STRING AND TAB
*
*POST CONDITIONS - A6 POINTS TO NEXT COMMAND TO BE DISASSEMBLED. A2 POINTS TO NEXT LOCATION TO BE APPENDED,
*                  DELIMETER SHOULD BE ADDED TO THIS LOCATION IMMEDIATELY. ALL OTHER ADDRESS AND DATA 
*                  REGISTERS ARE PRESERVED
*---------------------------------------------------------------------------------------------------------   
ISSUBQ       MOVEM.L     D0-D7/A0/A1/A3-A5, -(A7)          *SAVE JEENS REGISTERS AT $400
             JSR         CLRALLDREG                       *CLEAR REGISTERS FOR USE
             MOVE.W      (A6)+, D0
             JSR         GETMOVEREG                                               
             JSR         SWAP
             MOVE.B      #'#', (A2)+
             JSR         APPENDDISPLACE 
             JSR         SWAP                             *ELSE APPEND SRC AE
             MOVE.B      #',', (A2)+
             MOVE.B      #' ', (A2)+
             JSR         APPENDEA                         *APPEND DESTINATION EA
RTN_BADQ     MOVEM.L     (A7)+, D0-D7/A0/A1/A3-A5          *RESTORE JEENS REGISTERS
             MOVE.L      #0, D6
             MOVE.L      #0, D7
             RTS    
 
*---------------------------------------------------------------------------------------------------------
*IS ADDA           TO BE CALLED IF CURRENT INSTRUCTION POINTED TO BY A6 IS A KNOWN ADDA COMMAND. APPENDS 
*                  ADDRESSING MODES TO END OF CURRENT COMMAND STRING
*
*PRE CONDITIONS -  A6 POINTS TO START OF MOVE COMMAND. A2 POINTS TO LOCATION AFTER MOVE STRING AND TAB
*
*POST CONDITIONS - A6 POINTS TO NEXT COMMAND TO BE DISASSEMBLED. A2 POINTS TO NEXT LOCATION TO BE APPENDED,
*                  DELIMETER SHOULD BE ADDED TO THIS LOCATION IMMEDIATELY. ALL OTHER ADDRESS AND DATA 
*                  REGISTERS ARE PRESERVED
*---------------------------------------------------------------------------------------------------------   
ISADDAL      MOVE.L      #1, D6                           *INDICATES LONG DATA
             JSR         ISADDA                                                                             
             RTS   
ISADDA       MOVEM.L     D0-D7/A0/A1/A3-A5, -(A7)          *SAVE JEENS REGISTERS AT $400
             JSR         CLRALLDREG                       *CLEAR REGISTERS FOR USE
             MOVE.W      (A6)+, D0
             JSR         GETMOVEREG
             MOVE.B      #1, D3                           *SET DESTINATION TO ADDRESS REGISTER                                               
             JSR         APPENDEA 
             JSR         SWAP                             *ELSE APPEND SRC AE
             MOVE.B      #',', (A2)+
             MOVE.B      #' ', (A2)+
             JSR         APPENDEA                         *APPEND DESTINATION EA
RTN_BADA     MOVEM.L     (A7)+, D0-D7/A0/A1/A3-A5          *RESTORE JEENS REGISTERS
             MOVE.L      #0, D6
             MOVE.L      #0, D7
             RTS       
                            
*---------------------------------------------------------------------------------------------------------
*IS BCLR           TO BE CALLED IF CURRENT INSTRUCTION POINTED TO BY A6 IS A KNOWN BCLR COMMAND. CAN BE 
*                  CALLED REGARDLESS OF SIZE CODE. EA WILL BE THE SAME FOR BOTH BYTE AND LONG MODES
*
*PRE CONDITIONS -  A6 POINTS TO START OF MOVE COMMAND. A2 POINTS TO LOCATION AFTER MOVE STRING AND TAB
*
*POST CONDITIONS - A6 POINTS TO NEXT COMMAND TO BE DISASSEMBLED. A2 POINTS TO NEXT LOCATION TO BE APPENDED,
*                  DELIMETER SHOULD BE ADDED TO THIS LOCATION IMMEDIATELY. ALL OTHER ADDRESS AND DATA 
*                  REGISTERS ARE PRESERVED
*---------------------------------------------------------------------------------------------------------   
ISBCLR       MOVEM.L     D0-D7/A0/A1/A3-A5, -(A7)          *SAVE JEENS REGISTERS AT $400
             JSR         CLRALLDREG                       *CLEAR REGISTERS FOR USE
             MOVE.W      (A6)+, D0
             JSR         GETMOVEREG                                               
             JSR         SWAP
             CMPI.B      #6, D1
             BNE         IMSOURCE
             MOVE.B      #0, D1
RTN_IMSRC    JSR         APPENDEA 
             JSR         SWAP                             *ELSE APPEND SRC AE
             MOVE.B      #',', (A2)+
             MOVE.B      #' ', (A2)+
             JSR         APPENDEA                         *APPEND DESTINATION EA
RTN_BCLRBAD  MOVEM.L     (A7)+, D0-D7/A0/A1/A3-A5          *RESTORE JEENS REGISTERS
             MOVE.L      #0, D6
             MOVE.L      #0, D7
             RTS 
IMSOURCE     MOVE.B      #7, D1
             MOVE.B      #4, D0
             JMP         RTN_IMSRC
 
*---------------------------------------------------------------------------------------------------------
*IS BRA            TO BE CALLED IF CURRENT INSTRUCTION POINTED TO BY A6 IS A KNOWN BRA OR BRA FAMILY COMMAND. 
*                  APPENDS ADDRESSING OF NEXT INSTRUCTION TO BE EXECUTED TO A2
*
*PRE CONDITIONS -  A6 POINTS TO START OF MOVE COMMAND. A2 POINTS TO LOCATION AFTER MOVE STRING AND TAB
*
*POST CONDITIONS - A6 POINTS TO NEXT COMMAND TO BE DISASSEMBLED. A2 POINTS TO NEXT LOCATION TO BE APPENDED,
*                  DELIMETER SHOULD BE ADDED TO THIS LOCATION IMMEDIATELY. ALL OTHER ADDRESS AND DATA 
*                  REGISTERS ARE PRESERVED
*---------------------------------------------------------------------------------------------------------
ISBRA            MOVEM.L     D0-D7/A0/A1/A3-A5, -(A7)          *SAVE JEENS REGISTERS AT $400
                 JSR         CLRALLDREG                       *CLEAR REGISTERS FOR USE
                 MOVE.L      A6, D1                           *PC ADDRESS
                 ADDQ        #2, D1                           *ADD 2 TO PC ADDRESS
                 MOVE.W      (A6)+, D0
                 JSR         GETDISPLACEMENT                                               
                 CMPI.B      #0, D0
                 BEQ         BITDISPLACE                      *IF SIXTEEN BIT DISPLACEMENT GET NEXT WORD
RTN_16BIT        ADD.L       D1, D0
                 JSR         APPENDDISPLACE                   *APPEND DESTINATION EA
                 MOVEM.L     (A7)+, D0-D7/A0/A1/A3-A5          *RESTORE JEENS REGISTERS
                 MOVE.L      #0, D6
                 MOVE.L      #0, D7
                 RTS
 
*---------------------------------------------------------------------------------------------------------
*GET DISPLACEMENT - SHIFTS CURRENT WORD TO EXTRACT 8 BIT DISPLACEMENT VALUE, CHECK FOR 00 AFTERWARDS
*---------------------------------------------------------------------------------------------------------
GETDISPLACEMENT     LSL.W   #8, D0
                    LSR.W   #8, D0
                    RTS
  
*---------------------------------------------------------------------------------------------------------
*BIT DISPLACEMENT - 8 BIT DISPLACEMENT MUST BE 0, GRAB NEXT WORD TO EXTRACT 16 BIT DISPLACEMENT, HEHE.
*---------------------------------------------------------------------------------------------------------               
BITDISPLACE      MOVE.W      (A6)+, D0
                 JMP         RTN_16BIT
 
*---------------------------------------------------------------------------------------------------------
*IS MOVEB/W/L      TO BE CALLED IF CURRENT INSTRUCTION POINTED TO BY A6 IS A KNOWN MOVE COMMAND. APPENDS 
*                  ADDRESSING MODES TO END OF CURRENT COMMAND STRING
*
*PRE CONDITIONS -  A6 POINTS TO START OF MOVE COMMAND. A2 POINTS TO LOCATION AFTER MOVE STRING AND TAB
*
*POST CONDITIONS - A6 POINTS TO NEXT COMMAND TO BE DISASSEMBLED. A2 POINTS TO NEXT LOCATION TO BE APPENDED,
*                  DELIMETER SHOULD BE ADDED TO THIS LOCATION IMMEDIATELY. ALL OTHER ADDRESS AND DATA 
*                  REGISTERS ARE PRESERVED
*---------------------------------------------------------------------------------------------------------   
ISMOVEL      MOVE.L      #1, D6                           *INDICATES LONG DATA
             JSR         ISMOVE                                                                             
             RTS   
ISMOVE       MOVEM.L     D0-D7/A0/A1/A3-A5, -(A7)          *SAVE JEENS REGISTERS AT $400
             JSR         CLRALLDREG                       *CLEAR REGISTERS FOR USE
             MOVE.W      (A6)+, D0
             JSR         GETMOVEREG                                               
             JSR         APPENDEA 
             JSR         SWAP                             *ELSE APPEND SRC AE
             MOVE.B      #',', (A2)+
             MOVE.B      #' ', (A2)+
             JSR         APPENDEA                         *APPEND DESTINATION EA
RTN_BAD      MOVEM.L     (A7)+, D0-D7/A0/A1/A3-A5          *RESTORE JEENS REGISTERS
             MOVE.L      #0, D6
             MOVE.L      #0, D7
             RTS 

*---------------------------------------------------------------------------------------------------------
*GET MOVE REGISTERS - PARSES MOVE ADDRESSING REGISTERS AND MODES INTO D0, D1, D2 AND D3 TO BE CHECKED FOR ERROR
*---------------------------------------------------------------------------------------------------------            
GETMOVEREG      MOVE.W  D0, D1
                MOVE.W  D0, D2
                MOVE.W  D0, D3
                LSL.W   #8, D0
                LSL.W   #5, D0
                LSR.W   #8, D0
                LSR.W   #5, D0
                LSL.W   #8, D1
                LSL.W   #2, D1
                LSR.W   #8, D1
                LSR.W   #5, D1
                LSL.W   #4, D2
                LSR.W   #8, D2
                LSR.W   #5, D2
                LSL.W   #7, D3
                LSR.W   #8, D3
                LSR.W   #5, D3
                RTS               
                
*---------------------------------------------------------------------------------------------------------
*ISMOVEMW/L        (IS MOVEM.L AND MOVEM.W)- TO BE CALLED IF CURRENT INSTRUCTION POINTED TO BY A6 IS A 
*                  KNOWN MOVEM COMMAND
*
*PRE CONDITIONS -  A6 POINTS TO START OF MOVEM COMMAND
*
*POST CONDITIONS - A2 POINTS TO NEXT AVAILABLE LOCATION TO ADD NEXT ASCII INSTRUCTION. DO NOT INCREMENT
*                  A2, ALREADY DONE! A6 POINTS TO START OF NEXT COMMAND OR AND OF FILE IF ALL COMMANDS HAVE
*                  BEEN DIASSEMBLED. DO NOT INC A6, ALREADY DONE. ASCII STRINGS HAVE BEEN ADDED TO (A2) IF
*                  NO ERRORS OCCURED. IF ADDRESSING MODES ARE USED THAT ARE NOT SUPPORTED, THE COMMAND 
*                  STRING WILL BE INCORRECT, TO BE FIXED! THE STATE OF ALL OTHER REGISTERS IS UNDETERMINED 
*                  AFTER EXECUTION.
*---------------------------------------------------------------------------------------------------------
ISMOVEM       MOVEM.L       D0-D7/A0/A1/A3-A5, -(A7)          *SAVE JEENS REGISTERS AT $400
              JSR           CLRALLDREG                       *CLEAR REGISTERS FOR MOVEM
              JSR           SETEAREGISTERS 
              JSR           GETLISTMASK
              CMPI.B        #1, D4
              BEQ           MMAPPEA1
              JSR           MMAPPEA0
RTN_1DIR      MOVEM.L       (A7)+, D0-D7/A0/A1/A3-A5          *RESTORE JEENS REGISTERS     
              RTS 

*-----------------------------------------------------------------------------------------------------------
*MOVEM APPEND ADDRESS DIRECTION 0 (REG TO MEM) - APPENDS ADDRESSES ACCORDING TO DIRECTION REG TO MEM
*-----------------------------------------------------------------------------------------------------------
MMAPPEA0      MOVEM.W      D0-D7, -(A7)                      *SAVE MY PRECIOUS REGISTERS
              JSR          APPLISTRTM
              MOVEM.W      (A7)+, D0-D7
              MOVE.B       #',', (A2)+
              MOVE.B       #' ', (A2)+
              JSR          APPENDEA
              RTS

*-----------------------------------------------------------------------------------------------------------
*MOVEM APPEND ADDRESS DIRECTION 1 (MEM TO REG) - APPENDS ADDRESSES ACCORDING TO DIRECTION MEM TO REG
*-----------------------------------------------------------------------------------------------------------
MMAPPEA1      JSR          APPENDEA
              MOVE.B       #',', (A2)+
              MOVE.B       #' ', (A2)+
              MOVEM.W      D0-D7, -(A7)                      *SAVE MY PRECIOUS REGISTERS
              JSR          APPLISTRTM
              MOVEM.W      (A7)+, D0-D7
              JMP          RTN_1DIR     

*-----------------------------------------------------------------------------------------------------------
*APPEND LIST - APPENDS SOURCE LIST OF REGISTERS TO COMMAND STRING IN THE FORMAT AN/DN OR DN/AN IF ADDRESS 
*              INDIRECT PRE DECREMENT IS USED FOR DESTINATION ADDRESSING MODE. DOES NOT USE DASH (-) SYMBOL. 
*              IF THERE'S TIME, I WILL ADD.
*-----------------------------------------------------------------------------------------------------------                
APPLISTRTM      CMPI.B        #4, D1              *DIESTINATION IS ADDRESS INDIRECT PRE DECREMEMNT
                BEQ           BACKWARDLIST
                CMPI.B        #2, D1              *DESTINATION IS ADDRESS INDIRECT
                BEQ           FORWARDLIST
                CMPI.B        #7, D1              *DESTINATION IS  ABSOLUTE WORD OR LONG
                BEQ           FORWARDLIST
                CMPI.B        #3, D1              *DESTINATION IS  ABSOLUTE WORD OR LONG
                BEQ           FORWARDLIST
RTN_LIST        RTS

*-----------------------------------------------------------------------------------------------------------
*FORWARD LIST - FOR LOOP USED TO APPEND REGISTER STRINGS FOR EXAMPLE "A7/A6/D3/D1/D0"
*-----------------------------------------------------------------------------------------------------------
FORWARDLIST     MOVE.W  #0015, D1           *BIG UGLY FOR LOOP
                MOVE.W  #0000, D0
                MOVE.W  #0000, D2
FRWRDLOOP       LSL.W   #1, D3              *SHIFT FIELD MASK, CARRY WILL BE SET IF REGISTER SHOULD BE APPENDED
                BCS     APPENDDORAF         *WAS THERE CARRY?
RTN_APPDF       SUBI.B  #1, D1              *DECREMENT 
                CMP.B   D0, D1              *IS GREATER THAN OR EQUAL? FOR(INT D0 = 15; D1 >= D0; D1--)
                BGE     FRWRDLOOP
                JMP     RTN_LIST 

*-----------------------------------------------------------------------------------------------------------
*APPEND D OR A (FORWARD LOOP) - APPENDS STRING D OR A DEPENDING ON FOR LOOP COUNT
*-----------------------------------------------------------------------------------------------------------
APPENDDORAF     CMPI.B  #7, D1
                BGT     APPAF
                MOVE.B  #'D', (A2)+
                ADDI.B  #48, D2
                ADD.B   D1, D2
                MOVE.B  D2, (A2)+
RTN_APPAF       CMP.W   #0, D3
                BEQ     RTN_SLASHF
                JMP     APPENDSLASHF
RTN_SLASHF      CLR     D2
                JMP     RTN_APPDF            *END BIG UGLY FOR LOOP

*-----------------------------------------------------------------------------------------------------------
*APPEND SLASH (FORWARD LOOP) - APPENDS A SLASH (/) TO COMMAND STRING IS MORE REGISTERS ARE TO BE PRINTED
*-----------------------------------------------------------------------------------------------------------
APPENDSLASHF    MOVE.B  #$2F, (A2)+     *ADD SLASH = 2F IN HEX
                JMP     RTN_SLASHF 
                
APPAF           MOVE.B  #'A', (A2)+
                ADDI.B  #40, D2
                ADD.B   D1, D2
                MOVE.B  D2, (A2)+
                JMP     RTN_APPAF

*-----------------------------------------------------------------------------------------------------------
*BACKWARDS LIST - SAME AS BEFORE BUT WE HAVE TO GO THE OTHER WAY FOR(INT D0 = 0; D0 <= D1; D0++)
*-----------------------------------------------------------------------------------------------------------
BACKWARDLIST    MOVE.W  #0015, D1             *BIG UGLY FOR LOOP
                MOVE.W  #0000, D0
                MOVE.W  #0000, D2
BCKWRDLOOP      LSL.W   #1, D3
                BCS     APPENDDORA
RTN_APPD        ADDI.B  #1, D0
                CMP     D1, D0
                BLE     BCKWRDLOOP
                JMP     RTN_LIST 

*-----------------------------------------------------------------------------------------------------------
*APPEND D OR A - SAME AS ABOVE BUT DIFFERENT REGISTERS WERE USED...I SHOULDN'T HAVE DONE THAT...
*-----------------------------------------------------------------------------------------------------------             
APPENDDORA      CMPI.B  #7, D0
                BGT     APPA
                MOVE.B  #'D', (A2)+
                ADDI.B  #48, D2
                ADD.B   D0, D2
                MOVE.B  D2, (A2)+
RTN_APPA        CMP.W   #0, D3
                BEQ     RTN_SLASH
                JMP     APPENDSLASH
RTN_SLASH       CLR     D2
                JMP     RTN_APPD            *END BIG UGLY FOR LOOP

*-----------------------------------------------------------------------------------------------------------
*APPEND SLASH - SAME AS ABOVE BUT DIFFERENT REGISTERS ARE USED FOR THE FORWARD LOOP....STUPID....
*-----------------------------------------------------------------------------------------------------------               
APPENDSLASH     MOVE.B  #$2F, (A2)+     *ADD SLASH = 2F IN HEX
                JMP     RTN_SLASH 
                
APPA            MOVE.B  #'A', (A2)+
                ADDI.B  #40, D2
                ADD.B   D0, D2
                MOVE.B  D2, (A2)+
                JMP     RTN_APPA

*-----------------------------------------------------------------------------------------------------------
*GET LIST MASK - MOVES THE LIST MASK FROM MEMORY TO D3 TO BE SHIFTED FOR EACH REGISTER SAVED
*-----------------------------------------------------------------------------------------------------------
GETLISTMASK     MOVE.W  (A6)+, D3      *THANKS!
                RTS     
              
*-----------------------------------------------------------------------------------------------------------
*SET EA REGISTERS - PUTS THE DIRECTION, MODE, AND REGISTER ID D4, D5, AND D6 TO BE CHECKED FOR ERRORS AND W/E
*-----------------------------------------------------------------------------------------------------------
SETEAREGISTERS  MOVE.W (A6)+, D4       *COPY COMMAND INTO D4, 5 AND 6 TO BE PARSED
                MOVE.W  D4, D1         *FOR DIRECTION, MODE AND REG
                MOVE.W  D4, D0  
                LSL.W   #5, D4         *SHIFTING FOR DIRECTION
                LSR.W   #8, D4
                LSR.W   #7, D4
                LSL.W   #8, D1         *SHIFTING FOR MODE
                LSL.W   #2, D1
                LSR.W   #8, D1
                LSR.W   #5, D1
                LSL.W   #8, D0         *SHIFTING FOR REGISTER
                LSL.W   #5, D0
                LSR.W   #8, D0
                LSR.W   #5, D0
                RTS

*---------------------------------------------------------------------------------------------------------
*isLEA            (IS LEA)- TO BE CALLED IF CURRENT INSTRUCTION POINTED TO BY A6 IS A KNOWN LEA COMMAND
*
*PRE CONDITIONS -  A6 POINTS TO START OF LEA COMMAND
*
*POST CONDITIONS - A2 POINTS TO NEXT AVAILABLE LOCATION TO ADD NEXT ASCII INSTRUCTION. DO NOT INCREMENT
*                  A2, ALREADY DONE! A6 POINTS TO START OF NEXT COMMAND OR AND OF FILE IF ALL COMMANDS HAVE
*                  BEEN DIASSEMBLED. DO NOT INC A6, ALREADY DONE. ASCII STRINGS HAVE BEEN ADDED TO (A2) IF
*                  NO ERRORS OCCURED. THE STATE OF ALL OTHER REGISTERS IS EXACTLY HOW THEY WERE BEFORE CALLING THIS
*---------------------------------------------------------------------------------------------------------
isLEA            MOVEM.L     D0-D7/A0/A1/A3-A5, -(A7)          *SAVE JEENS REGISTERS AT $400
                 JSR         CLRALLDREG                           
                 MOVE.W      (A6)+, D0                        *GET CURRENT OP CODE DATA TO D7
                 JSR         GETMOVEREG
                 MOVE.L      #1, D6                           *INDICATES LONG FOR IMMEDIATE ADDRESSING
                 JSR         APPENDEA
                 MOVE.B      #',', (A2)+                      *ADD SPACE BETWEEN ADDRESSES
                 MOVE.B      #' ', (A2)+                      *ADD COMMA BETWEEN ADDRESSES
                 JSR         SWAP
                 MOVE.W      #1, D1
                 JSR         APPENDEA
LEARTN           MOVEM.L     (A7)+, D0-D7/A0/A1/A3-A5
                 MOVE.L      #0, D6
                 RTS
                
*---------------------------------------------------------------------------------------------------------
*IS ORIB/W/L       TO BE CALLED IF CURRENT INSTRUCTION POINTED TO BY A6 IS A KNOWN ORI COMMAND
*
*PRE CONDITIONS -  A6 POINTS TO START OF MOVE COMMAND. A2 POINTS TO LOCATION AFTER MOVE STRING AND TAB
*
*POST CONDITIONS - A6 POINTS TO NEXT COMMAND TO BE DISASSEMBLED. A2 POINTS TO NEXT LOCATION TO BE APPENDED,
*                  DELIMETER SHOULD BE ADDED TO THIS LOCATION IMMEDIATELY. ALL OTHER ADDRESS AND DATA 
*                  REGISTERS ARE PRESERVED. EXCEPT D6, D6 IS GONE....SORRY
*---------------------------------------------------------------------------------------------------------            
ISORIL          MOVE.L      #1, D6                           *INDICATES LONG DATA
                JSR         ISORI                                                                             
                RTS   
ISORI           MOVEM.L     D0-D7/A0/A1/A3-A5, -(A7)          *SAVE JEENS REGISTERS AT $400
                JSR         CLRALLDREG                       *CLEAR REGISTERS FOR USE
                MOVE.W      (A6)+, D0
                JSR         GETMOVEREG                                              
                JSR         APPENDIMMEDIATE                  *ELSE APPEND SRC AE
                MOVE.B      #',', (A2)+
                MOVE.B      #' ', (A2)+
                JSR         APPENDEA                         *APPEND DESTINATION EA
RTN_BADORI      MOVEM.L     (A7)+, D0-D7/A0/A1/A3-A5          *RESTORE JEENS REGISTERS
                MOVE.L      #0, D6
                RTS      
                
*---------------------------------------------------------------------------------------------------------
*IS NEGB/W/L       TO BE CALLED IF CURRENT INSTRUCTION POINTED TO BY A6 IS A KNOWN NEG COMMAND
*
*PRE CONDITIONS -  A6 POINTS TO START OF MOVE COMMAND. A2 POINTS TO LOCATION AFTER MOVE STRING AND TAB
*
*POST CONDITIONS - A6 POINTS TO NEXT COMMAND TO BE DISASSEMBLED. A2 POINTS TO NEXT LOCATION TO BE APPENDED,
*                  DELIMETER SHOULD BE ADDED TO THIS LOCATION IMMEDIATELY. ALL OTHER ADDRESS AND DATA 
*                  REGISTERS ARE PRESERVED. EXCEPT D6, D6 IS GONE....SORRY
*---------------------------------------------------------------------------------------------------------             
ISNEGL          MOVE.L      #1, D6                           *INDICATES LONG DATA
                JSR         ISNEG
                RTS
ISNEG           MOVEM.L     D0-D7/A0/A1/A3-A5, -(A7)          *SAVE JEENS REGISTERS AT $400
                JSR         CLRALLDREG                       *CLEAR REGISTERS FOR USE
                MOVE.W      (A6)+, D0
                JSR         GETMOVEREG                                               
                JSR         APPENDEA                         *APPEND DESTINATION EA
RTN_NEGERR      MOVEM.L     (A7)+, D0-D7/A0/A1/A3-A5
                MOVE.L      #0, D6
                RTS

*---------------------------------------------------------------------------------------------------------
*IS E/ORB/W/L        TO BE CALLED IF CURRENT INSTRUCTION POINTED TO BY A6 IS A KNOWN OR/EOR COMMAND
*
*PRE CONDITIONS -  A6 POINTS TO START OF MOVE COMMAND. A2 POINTS TO LOCATION AFTER MOVE STRING AND TAB
*
*POST CONDITIONS - A6 POINTS TO NEXT COMMAND TO BE DISASSEMBLED. A2 POINTS TO NEXT LOCATION TO BE APPENDED,
*                  DELIMETER SHOULD BE ADDED TO THIS LOCATION IMMEDIATELY. ALL OTHER ADDRESS AND DATA 
*                  REGISTERS ARE PRESERVED. EXCEPT D6...
*---------------------------------------------------------------------------------------------------------
ISORL           MOVE.L      #1, D6                           *INDICATE LONG DATA
                JSR         ISOR
                RTS
ISEORL          MOVE.L      #1, D6                           *INDICATE LONG DATA
                JSR         ISEOR
                RTS
ISEOR           MOVE.L      #1, D7                           *INDICATES EXCULIVE OR OPERATION TO THE OR DISASSEMBLER
                JSR         ISOR
                RTS
ISOR            MOVEM.L     D0-D7/A0/A1/A3-A5, -(A7)        *SAVE JEENS REGISTERS AT $400
                JSR         CLRALLDREG                       *CLEAR REGISTERS FOR USE
                MOVE.W      (A6)+, D4
                JSR         PARSEOROP 
                CMPI.B      #2, D4                           *IF OPMODE GREATER THAN 2 DN IS SOURCE
                BGT         PARSEDNSOURCE    
                JSR         PARSEDNDEST                                                                 
RTN_PARSEOR     JSR         APPENDEA                         *APPEND DESTINATION EA
                JSR         SWAP
                MOVE.B      #',', (A2)+
                MOVE.B      #' ', (A2)+
                JSR         APPENDEA
RTN_OR          MOVEM.L     (A7)+, D0-D7/A0/A1/A3-A5
                MOVE.L      #0, D6                     
                MOVE.L      #0, D7
                RTS

*---------------------------------------------------------------------------------------------------------
*PARSE OR OP MODE - PARSES THE OPMODE FROM THE COMMAND TO DETERMINE IF DATA REGISTER IS SOURCE OR 
*                   DESTINATION OPERAND
*---------------------------------------------------------------------------------------------------------
PARSEOROP       MOVE.W      D4, D0
                MOVE.W      D4, D1
                MOVE.W      D4, D2
                MOVE.W      D4, D3
                LSL.W       #7, D4
                LSR.W       #8, D4
                LSR.W       #5, D4
                RTS

*---------------------------------------------------------------------------------------------------------
*PARSE DN SOURCE - PARSES ADDRESSING REGISTER AND MODE IF DN IS KNOWN TO BE SOURCE OPERAND
*---------------------------------------------------------------------------------------------------------                
PARSEDNSOURCE   MOVE.W      #0, D1
                LSL.W       #4, D0
                LSR.W       #8, D0
                LSR.W       #5, D0  
                LSL.W       #8, D2
                LSL.W       #5, D2
                LSR.W       #8, D2
                LSR.W       #5, D2
                LSL.W       #8, D3
                LSL.W       #2, D3
                LSR.W       #8, D3
                LSR.W       #5, D3
                *CMPI.B      #1, D6
                *BEQ         RTN_STRGCASE
                JMP         RTN_PARSEOR 

*---------------------------------------------------------------------------------------------------------
*PARSE DN DESTINATION - PARSES ADDRESSING REGISTER AND MODE IF DN IS KNOWN TO BE DESTINATION OPERAND
*---------------------------------------------------------------------------------------------------------
PARSEDNDEST     CMPI.B      #1, D7
                BEQ         PARSEDNSOURCE
                MOVE.W      #0, D3
                LSL.W       #4, D2
                LSR.W       #8, D2
                LSR.W       #5, D2  
                LSL.W       #8, D0
                LSL.W       #5, D0
                LSR.W       #8, D0
                LSR.W       #5, D0
                LSL.W       #8, D1
                LSL.W       #2, D1
                LSR.W       #8, D1
                LSR.W       #5, D1
RTN_STRGCASE    RTS

*-----------------------------------------------------------------------------------------------------------
**********************************************SHARED-CODE-SECTION******************************************* 
*-----------------------------------------------------------------------------------------------------------
*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~HEHE~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*
*-----------------------------------------------------------------------------------------------------------
**********************************************SHARED-CODE-SECTION******************************************* 
*-----------------------------------------------------------------------------------------------------------
                    
*---------------------------------------------------------------------------------------------------------
*ERROR CHECK - CHECKS ADDRESSING MODES AND ADDRESSING REGISTERS FOR GENERAL ERRORS THAT APPLY TO ALL OP CODES
*---------------------------------------------------------------------------------------------------------            
ERRORCHECK      JSR         CHECKMODE
RTN_REGCHK      RTS
CHECKMODE       CMPI.B      #5, D1
                BEQ         ERROR2
                CMPI.B      #6, D1
                BEQ         ERROR
                CMPI.B      #7, D1
                BEQ         CHECKREG
                RTS
CHECKREG        CMPI.B      #2, D0
                BEQ         ERROR2
                CMPI.B      #3, D0
                BEQ         ERROR2
                JMP         RTN_REGCHK
ERROR2          MOVE.W      #$BEEF, $456
                JMP         RTN_REGCHK

*---------------------------------------------------------------------------------------------------------
*APPENDS IMMEDIATE  - APPEND IMMEDIATE DATA FROM A6 TO A2 DEPENDING ON WORD OR LONG ADDRESSING MODE
*                     INDICATED BY D6, (1 FOR LONG, 0 FOR WORD)
*---------------------------------------------------------------------------------------------------------                
APPENDIMMEDIATE MOVE.B      #'#', (A2)+
                MOVE.B      #'$', (A2)+
                CMP.B       #1, D6
                BEQ         ISLONG
                JSR         APPENDWORD
                RTS
                
*---------------------------------------------------------------------------------------------------------
*SWAP  - SWAPS D0 AND D1 WITH D2 AND D3 SO ERROR CHECKING CAN BE DONE ONE BOTH SOURCE AND DEST OPERANDS
*---------------------------------------------------------------------------------------------------------
SWAP            EXG         D0, D2
                EXG         D1, D3
                RTS

*---------------------------------------------------------------------------------------------------------
*APPEND EA          - APPENDS ADDRESSES DEPENDING ON ADDRESSING MODES USED
*PRE-CONDITIONS     - ERROR CHECKING HAS BEEN COMPLETED. D0 CONTAINS ADDRESSING REGISTER. D1 CONTAINS
*                     ADDRESSING MODE. d6 contains 1 for immediate long addressing
*---------------------------------------------------------------------------------------------------------           
APPENDEA        CMPI.B      #7, D1
                BEQ         MSWORL
                CMPI.B      #0, D1
                BEQ         MSDREG
                CMPI.B      #1, D1
                BEQ         MSAREG
                CMPI.B      #2, D1
                BEQ         MSAIREG
                CMPI.B      #3, D1
                BEQ         MSAPIREG
                CMPI.B      #4, D1
                BEQ         MSAPDREG
RTN_APPSRC      RTS

*---------------------------------------------------------------------------------------------------------
*APPEND MOVE SOURCE DATA REGISTER - APPENDS DN TO ADDRESS POINTED TO BY A2
*---------------------------------------------------------------------------------------------------------
MSDREG          JSR         APPENDSRCDREG
                JMP         RTN_APPSRC

*---------------------------------------------------------------------------------------------------------
*APPEND MOVE SOURCE ADDRESS REGISTER - APPENDS AN TO ADDRESS POINTED TO BY A2
*---------------------------------------------------------------------------------------------------------                
MSAREG          JSR         APPENDSRCAREG
                JMP         RTN_APPSRC

*---------------------------------------------------------------------------------------------------------
*APPEND MOVE SOURCE ADRESS INDIRECT REGISTER - APPENDS (AN) TO ADDRESS POINTED TO BY A2
*---------------------------------------------------------------------------------------------------------                
MSAIREG         JSR         APPENDSRCAIREG
                JMP         RTN_APPSRC

*---------------------------------------------------------------------------------------------------------
*APPEND MOVE SOURCE ADRESS INDIRECT POST INCREMENT REGISTER - APPENDS (AN)+ TO ADDRESS POINTED TO BY A2
*---------------------------------------------------------------------------------------------------------                
MSAPIREG        JSR         APPENDSRCAPIREG
                JMP         RTN_APPSRC

*---------------------------------------------------------------------------------------------------------
*APPEND MOVE SOURCE ADRESS INDIRECT PRE DECREMENT REGISTER - APPENDS -(AN) TO ADDRESS POINTED TO BY A2
*---------------------------------------------------------------------------------------------------------                
MSAPDREG        JSR         APPENDSRCAPDREG
                JMP         RTN_APPSRC

*---------------------------------------------------------------------------------------------------------
*MOVE SOURCE WORD OR LONG - SOURCE ADDRESSING MODE IS ABSOLUTE WORD OR LONG, APPEND APPROPRIATELY
*---------------------------------------------------------------------------------------------------------                
MSWORL          CMPI.B      #0, D0
                BEQ         MSWORD
                CMPI.B      #1, D0
                BEQ         MSLONG
                CMPI.B      #4, D0
                BEQ         MSIMMEDIATE
                JMP         RTN_APPSRC

*---------------------------------------------------------------------------------------------------------
*MOVE SOURCE IMMEDIATE - SOURCE ADDRESSING MODE IS IMMEDIATE DATA, APPEND APPROPRIATELY
*---------------------------------------------------------------------------------------------------------                
MSIMMEDIATE     MOVE.B      #'#', (A2)+
                MOVE.B      #'$', (A2)+
                CMP.B       #1, D6
                BEQ         ISLONG
                JSR         APPENDWORD
                JMP         RTN_APPSRC

*---------------------------------------------------------------------------------------------------------
*IS LONG - ADDRESSING MODE IS LONG, APPEND APPROPRIATELY
*---------------------------------------------------------------------------------------------------------                
ISLONG          JSR         APPENDLONG
                JMP         RTN_APPSRC

*---------------------------------------------------------------------------------------------------------
*MOVE SOURCE LONG - IS LONG, APPEND APPROPRIATELY
*---------------------------------------------------------------------------------------------------------                
MSLONG          MOVE.B      #'$', (A2)+
                JSR         APPENDLONG
                JMP         RTN_APPSRC

*---------------------------------------------------------------------------------------------------------
*MOVE SOURCE WORD - ADDRESSING MODE IS ABSOLUTE WORD, APPEND APPROPRIATELY
*---------------------------------------------------------------------------------------------------------               
MSWORD          MOVE.B      #'$', (A2)+
                JSR         APPENDWORD
                JMP         RTN_APPSRC

*---------------------------------------------------------------------------------------------------------
*APPEND DATA REGISTER - APPENDS DN TO A2
*---------------------------------------------------------------------------------------------------------
APPENDSRCDREG       MOVE.B      #'D', (A2)+
                    ADDI.B      #48, D0
                    MOVE.B      D0, (A2)+
                    SUBI.B      #48, D0
                    RTS

*---------------------------------------------------------------------------------------------------------
*APPEND ADDRESS REGISTER - APPENDS AN TO A2
*---------------------------------------------------------------------------------------------------------                    
APPENDSRCAREG       MOVE.B      #'A', (A2)+
                    ADDI.B      #48, D0
                    MOVE.B      D0, (A2)+
                    SUBI.B      #48, D0
                    RTS

*---------------------------------------------------------------------------------------------------------
*APPEND ADDRESS REGISTER INDIRECT - APPENDS (AN) TO A2
*---------------------------------------------------------------------------------------------------------                    
APPENDSRCAIREG      MOVE.B      #'(', (A2)+
                    MOVE.B      #'A', (A2)+
                    ADDI.B      #48, D0
                    MOVE.B      D0, (A2)+
                    MOVE.B      #')', (A2)+
                    SUBI.B      #48, D0
                    RTS

*---------------------------------------------------------------------------------------------------------
*APPEND ADDRESS REGISTER POST INCREMENT - APPENDS (AN)+ TO A2
*---------------------------------------------------------------------------------------------------------                     
APPENDSRCAPIREG     MOVE.B      #'(', (A2)+
                    MOVE.B      #'A', (A2)+
                    ADDI.B      #48, D0
                    MOVE.B      D0, (A2)+
                    MOVE.B      #')', (A2)+
                    MOVE.B      #'+', (A2)+
                    SUBI.B      #48, D0
                    RTS
 
*---------------------------------------------------------------------------------------------------------
*APPEND ADDRESS REGISTER PRE DECREMENT - APPENDS -(AN) TO A2
*---------------------------------------------------------------------------------------------------------                    
APPENDSRCAPDREG     MOVE.B      #'-', (A2)+
                    MOVE.B      #'(', (A2)+
                    MOVE.B      #'A', (A2)+
                    ADDI.B      #48, D0
                    MOVE.B      D0, (A2)+
                    MOVE.B      #')', (A2)+
                    SUBI.B      #48, D0
                    RTS

*---------------------------------------------------------------------------------------------------------
*CLEA ALL D REG - CLEARS ALL DATA REGISTERS, EXCEPT D6....I NEED IT, DONT ASK
*--------------------------------------------------------------------------------------------------------- 
CLRALLDREG          CLR         D0
                    CLR         D1
                    CLR         D2
                    CLR         D3
                    CLR         D4
                    CLR         D5
                    RTS

*---------------------------------------------------------------------------------------------------------
*APPEND LONG - APPENDS THE LONG ABSOLUTE ADDRESS TO A2
*---------------------------------------------------------------------------------------------------------                 
APPENDLONG          JSR         APPENDWORD
                    JSR         APPENDWORD
                    RTS 
                   
*---------------------------------------------------------------------------------------------------------
*APPENDs address of machine code to be disassembled
*---------------------------------------------------------------------------------------------------------                 
APPENDADDRESS       MOVE.L      A6, D7
                    LSR.L       #8, D7
                    LSR.L       #8, D7
                    JSR         APPENDADD
                    MOVE.L      A6, D7
                    JSR         APPENDADD
                    RTS 
                    
*---------------------------------------------------------------------------------------------------------
*APPEND WORD - APPENDS THE WORD ABSOLUTE ADDRESS TO A2
*---------------------------------------------------------------------------------------------------------                 
APPENDADD       MOVEM.L     D0-D7, -(A7)
                JSR         CLRALLDREG
                MOVE.W      D7, D0
                MOVE.W      D7, D1
                MOVE.W      D7, D2
                MOVE.W      D7, D3
                LSR.W       #8, D0
                LSR.W       #4, D0
                LSL.W       #4, D1
                LSR.W       #8, D1
                LSR.W       #4, D1
                LSL.W       #8, D2
                LSR.W       #8, D2
                LSR.W       #4, D2
                LSL.W       #8, D3
                LSL.W       #4, D3
                LSR.W       #8, D3
                LSR.W       #4, D3
                JSR         CONVERT
                MOVE.B      D1, D0
                JSR         CONVERT
                MOVE.B      D2, D0
                JSR         CONVERT
                MOVE.B      D3, D0
                JSR         CONVERT
                JSR         CLRALLDREG        
                MOVEM.L     (A7)+, D0-D7
                RTS
 
*---------------------------------------------------------------------------------------------------------
*APPEND WORD - APPENDS THE WORD ABSOLUTE ADDRESS TO A2
*---------------------------------------------------------------------------------------------------------                 
APPENDWORD      MOVEM.L     D0-D7, -(A7)
                JSR         CLRALLDREG
                MOVE.W      (A6)+, D7
                MOVE.W      D7, D0
                MOVE.W      D7, D1
                MOVE.W      D7, D2
                MOVE.W      D7, D3
                LSR.W       #8, D0
                LSR.W       #4, D0
                LSL.W       #4, D1
                LSR.W       #8, D1
                LSR.W       #4, D1
                LSL.W       #8, D2
                LSR.W       #8, D2
                LSR.W       #4, D2
                LSL.W       #8, D3
                LSL.W       #4, D3
                LSR.W       #8, D3
                LSR.W       #4, D3
                JSR         CONVERT
                MOVE.B      D1, D0
                JSR         CONVERT
                MOVE.B      D2, D0
                JSR         CONVERT
                MOVE.B      D3, D0
                JSR         CONVERT
                JSR         CLRALLDREG        
                MOVEM.L     (A7)+, D0-D7
                RTS
                
*---------------------------------------------------------------------------------------------------------
*APPEND WORD - APPENDS THE WORD ABSOLUTE ADDRESS TO A2
*---------------------------------------------------------------------------------------------------------                 
APPENDDISPLACE  MOVE.B      #'$', (A2)+
                 MOVEM.L     D0-D7, -(A7)
                 MOVE.W      D0, D1
                 MOVE.W      D0, D2
                 MOVE.W      D0, D3
                 LSR.W       #8, D0
                 LSR.W       #4, D0
                 LSL.W       #4, D1
                 LSR.W       #8, D1
                 LSR.W       #4, D1
                 LSL.W       #8, D2
                 LSR.W       #8, D2
                 LSR.W       #4, D2
                 LSL.W       #8, D3
                 LSL.W       #4, D3
                 LSR.W       #8, D3
                 LSR.W       #4, D3
                 JSR         CONVERT
                 MOVE.B      D1, D0
                 JSR         CONVERT
                 MOVE.B      D2, D0
                 JSR         CONVERT
                 MOVE.B      D3, D0
                 JSR         CONVERT        
                 MOVEM.L     (A7)+, D0-D7
                 RTS


*---------------------------------------------------------------------------------------------------------
*ADD 55 - ADD 55 HEX TO VALUE IN D0 TO CONVERT TO LETTER
*---------------------------------------------------------------------------------------------------------                 
ADD55           ADDI.B      #55, D0
                JMP         RTN_ADD55

*---------------------------------------------------------------------------------------------------------
*ADD 48 - ADD 55 HEX TO VALUE IN D0 TO CONVERT TO NUMBER
*---------------------------------------------------------------------------------------------------------                 
ADD48           ADDI.B      #48, D0
                RTS
*---------------------------------------------------------------------------------------------------------
*CONVERT - CONVERTS VALUE AT D0 BY ADDING 55 OR 48 IF LETTER OR NUMBER
*---------------------------------------------------------------------------------------------------------                
CONVERT         CMPI.B      #$A, D0
                BGE         ADD55 
                JSR         ADD48 
RTN_ADD55       MOVE.B      D0, (A2)+  
                RTS
                


*-----------Output texts------------------------------------
WelcomeMsg  DC.b    'Welcome to EASy68K Instruction Disassembler!',CR,LF,0
WrtBy       DC.B    'Created by: Kunlakan Cherdchusilp, Nicolas Michael, Vuochly Ky',CR,LF,CR,LF,0
note1       DC.B    'Preconditions: ',CR,LF,0
note2       DC.B    '   -- The address inputs must be in hexadecimal number (without $)',CR,LF,0
note3       DC.B    '   -- Addresses must be in the range of 3000 ~ 00FFFFFE',CR,LF,0
note4       DC.B    '   -- Both starting and ending address must be even addresses',CR,LF,CR,LF,0
startLoc    DC.B    'Please enter your starting location in hexadecimal number: ',0
endLoc      DC.B    'Please enter your ending location in hexadecimal number: ',0
AskToCont   DC.B    'Would you like to start over? (y/n) :',0
enter       DC.B    'Press ENTER key to see more.',0
ThxMsg      DC.B    'Thank you for using our EASy68K Instruction Disassembler!',0
YN          DC.W    $880     ;WHERE THE YES/NO CHARACTER IS STORED
startAddr   DC.L    $890
endAddr     DC.L    $900
ent         DC.W    $820
error       DC.B    'The address you entered is whether invalid or out of range.',CR,LF,CR,LF,0
NOTNY       DC.B    'You did not enter n or y, Please enter again!',CR,LF,0

outData     DS.L     1

    END    START







*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~

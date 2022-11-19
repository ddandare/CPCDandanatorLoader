
;------------------------------------------------------------------------------------------------------------------------
; Load serial block of data at address specified by HL, BC contains size - Serial data is served NOT INVERTED
; WARNING, WHEN SERIAL OPS ARE ON, BUS IS HACKED ON LD A,(HL) (returns inverted serial bit on D0), others <= '0'
; Serial Data must be 115.200, N, 8, 2 (two stop bits)
;------------------------------------------------------------------------------------------------------------------------
LoadSerBlk: 
			
			; 115.200 = 8,68 instruction blocks (4ts) per bit
			
SerialON:	;PUSH HL
			;PUSH BC
			PUSH IY
			POP BC
			DDNTR_CONFIGURATION 5		; Enable Serial and Bus Hack -> LD A,(HL) does not fetch from memory, but from serial
			;POP BC
			;POP HL
			;LD E,0						; fast clear of D register during byte reception
			
BucSerial:	;LD D,E						; 1 - 1  Clear D (will hold the payload)
WaitStartb:	LD A,(HL)					; 2 - 3  Wait for Start bit
			RRCA						; 1 - 4  
CheckStart:	JR C, WaitStartb			; 2 - 6 if not jumping back, 3 - 7 if jumping back
										; at this point:
											; best case is 5,68 ahead of bit.
											; worst case is 0,32 behind bit
											; should move 6 ahead
											
			AND $FF 					; 2 - 2
			AND $FF						; 2 - 4						
			AND $FF						; 2 - 6


				
Payload:	; Should sample at 0, 8,68, 17,35, 26,04, 34,72, 43,40, 52,08 and 60,76 -  69,44 for stop bit - 78,13 start bit
			
bit0:       	                        ; {11, 14, 15} in [8.68 - 17.35]
    LD   A,(HL)                         ; (2)
    RRA                                 ; (1)
    RR   D                              ; (2)
    AND  $FF                            ; (2)
            
    ; Delay 1 extra NOP for fixing a possible race condition for the next bit
    NOP                                 ; (1)
bit1:	                                ; {18, 21, 22} in [17.35 - 26.04]
    LD   A,(HL)                         ; (2)
    RRA                                 ; (1)
    RR   D                              ; (2)
    AND  $FF                            ; (2)
    AND  $FF                            ; (2)
            
bit2:		                            ; {27 , 30, 31} in [26.04 - 34.72]
    LD   A,(HL)                         ; (2)
    RRA                                 ; (1)
    RR   D                              ; (2)
    AND  $FF                            ; (2)
    AND  $FF                            ; (2)
            
bit3:	                                ; {36, 39, 40} in [34.72 - 43.40]
    LD   A,(HL)                         ; (2)
    RRA                                 ; (1)
    RR   D                              ; (2)
    AND  $FF                            ; (2)
    AND  $FF                            ; (2)
            
bit4:                              		; {45, 48, 49} in [43.40 - 52.08]
    LD   A,(HL)                         ; (2)
    RRA                                 ; (1)
    RR   D                              ; (2)
    AND  $FF                            ; (2)
    NOP                                 ; (1)

bit5:                             		; {53, 56, 57} in [52.08 - 60.76]
    LD   A,(HL)                         ; (2)
    RRA                                 ; (1)
    RR   D                              ; (2)
    AND  $FF                            ; (2)
    AND  $FF                            ; (2)

bit6:                             		; {62, 65, 66} in [60.76 - 69.44]
    LD   A,(HL)                         ; (2)
    RRA                                 ; (1)
    RR   D                              ; (2)
    AND  $FF                            ; (2)
    AND  $FF                            ; (2)
            
bit7:                             		; {71, 74, 75} in [69.44 - 78.13]
    LD   A,(HL)                         ; (2)
    RRA                                 ; (1)
    RR   D                              ; (2)

    ; Save received byte to RAM
    LD   (HL),D                         ; (2) 78 81 82 Save received Byte to RAM
    INC  HL                             ; (2) 80 83 84 Increase destination pointer
    DEC  BC                             ; (2) 82 85 86 One byte less
    LD   A,C                            ; (1) 83 86 87 Check if zero bytes remaining
    OR   B                              ; (1) 84 87 88
    JR   NZ, BucSerial         ; (3) 87 90 91 Loop if some bytes remain    
			
SerialOFF:	DDNTR_CONFIGURATION 4		; Disable Serial ops and restore LD A,(HL) to normal operation (bushack=off)

	RET
;------------------------------------------------------------------------------------------------------------------------



;------------------------------------------------------------------------------------------------------------------------
; Send Serial Byte at 57.600bps
; Must be DI, Sends byte in A
; Start bit. bit 0.... bit 7. Stop bits (2, idle line)
;------------------------------------------------------------------------------------------------------------------------
SerialSendA:
			LD C,A						; Save A
			LD D,0						; 0 is a 0 to serial port -- Disables Serial reads.
			LD E,4						; 4 is a 1 to serial port -- Disables Serial reads.
			LD B,8						; Number of iterations
			LD IY, IYSCRATCH_ADDR		; Save 0xBFFF Contents no slot should be paged in in segment 3
			
Startbit:	LD A,D						; Load a 0
			TRIGGER			
			LD (IY),A					; Send Start bit



			AND 1						; 2
			AND 1						; 2
			AND 1						; 2
			AND 1						; 2	
			AND 1						; 2	
			AND 1						; 2	
			
Bits0_7:	RRC C						; (2) put next bit in Carry
			LD A,D						; (1) Assume a 0 bit
			JR NC, Bit_send				; (3 if jump, 2 if no jump) If no Carry, jump to bit_send with a 0
			LD A,E						; (1) Normalizing previous JR, Put 1 in bit
Bit_send:	TRIGGER						; (4)
			LD (IY),A					; (2)
			DJNZ Bits0_7				; (4 if jump, 3 if not)
										; Total 17
			
			AND 1						; 2
			AND 1						; 2
			AND 1						; 2
			AND 1						; 2	
			LD A, E						; Stop bits
			TRIGGER						; Trigger
			LD (IY),A					; Command
			RET
;------------------------------------------------------------------------------------------------------------------------


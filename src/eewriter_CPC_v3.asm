	ORG 	LOADER_RAM_ADDR	
	INCLUDE "ddntr_macros.asm"
	
	OUTPUT 	"loader_cpc.bin"	
	
; ----------------------------------------------------------------------------------------
; MAIN LOADER
;
; ----------------------------------------------------------------------------------------	
Loader:		DI							; Running with interrupts disabled
			LD SP, WSTACK_LOADER_ADDR	; Set Stack 

			DDNTR_CONFIGURATION $82		; ZoneAlloc 0, enable Zone0
			SLOTZONE0 2					; Set Slot 2 in Zone 0
			  
			LD HL, $0000				; Copy Contents of Slot 2 to RAM								
			LD DE, RX_DATA_ADDR
			LD BC, $100
			LDIR
			
			SLOTZONE0 32				; Disable SlotZone0		
			
			LD B,0						; Check 256 bytes
			LD HL, $0000				; From Not Paged Dandanator
			LD DE, RX_DATA_ADDR			; To copy of slot 2 paged Dandanator
CheckRomLp:	LD C, (HL)					; Check that internal rom is different from paged in Slot 2
			LD A, (DE)
			XOR C
			JR NZ, CheckRomOK			; If different at any point, we are good to go. Dandanator is detected
			INC HL
			INC DE
			DJNZ CheckRomLp				; Check All bytes

NoDandanator:							; No dandanator detected or dandanator is disabled	

	IF (1=0)
			; --------- *********** ERROR DEADLOCK
TosBomb:	LD E,PAL_BLACK				; Pal Black
			LD C,$05					; From Pen5 up
			LD D,$10					; to 16
			CALL ErrorCol
			LD E, PAL_BRIGHTRED			; Pal Red
			LD C,$09					; From Pen9 up ("E" Letter)
			LD D,$0E					; to 14
			CALL ErrorCol
			JR TosBomb
			
				
ErrorCol:	LD B,$7F					
			OUT (C),C
			OUT (C),E
			INC C
			LD A, D
			CP C
			JR NZ, ErrorCol		
			
PauseBlink: LD HL, $8000
PauseLoop:	DEC HL
			LD A,H
			OR L
			JR NZ, PauseLoop
			RET

	ELSE
			

TosBomb:
			LD	HL,#C000+(80*9)+(4*13)		;Row 9, Column 13 (MODE 0)
			LD  A,#FF
			CALL DrawDigit
TosBomb_Loop:			

			LD DE,TosOFF
			LD BC,$7F0C						;Change colours 12 to 15
			CALL ErrorCol
			
			INC DE
			LD BC,$7F0C						;Change colours 12 to 15
			CALL ErrorCol
			
			JR TosBomb_Loop
			
ErrorCol:	LD A,(DE)
			AND A
			JR Z,PauseBlink
			OUT (C),C
			OUT (C),A
			INC C
			INC DE
			JR ErrorCol
			
PauseBlink: LD HL, $A000
PauseLoop:	DEC HL
			LD A,H
			OR L
			JR NZ, PauseLoop
			RET
			
TosOFF:		DEFB	PAL_RED,PAL_RED,PAL_RED,PAL_WHITE,0
TosON:		DEFB	PAL_BRIGHTRED,PAL_PURPLE,PAL_RED,PAL_BRIGHTWHITE,0

	ENDIF
			
			
CheckRomOK: 

		
SyncF0Java: LD A, $F0
			CALL SerialSendA
			DDNTR_CONFIGURATION 5      	; Enable Serial In
			LD BC, $8000
WaitSync:	LD A,(HL)
			RRCA
			JR NC, StartTRF				; A start bit is detected -> Sync Byte
			DEC BC
			LD A,B
			OR C
			JR NZ, WaitSync
			JR SyncF0Java
			

StartTRF: DDNTR_CONFIGURATION 4      	;Disable Serial In

			XOR A						; First Slot
			LD (CURRENT_SLOT),A
			LD (CURRENT_DIGITS),A
			LD A, PAL_BRIGHTGREEN
			LD (CURRENT_DISP_COLOR),A
			
Prog_Lp:	
	IF (1=0)
			CALL Disp7Seg				; Put Sector Number 	
	ELSE
			LD A,(CURRENT_SLOT)		
			INC A
			LD HL,#C000+(80*9)+(4*13)+1	;Row 9, Column 13+1/4 (MODE 0)
			CALL DrawDigit
	ENDIF
			LD A, (CURRENT_SLOT)
	IF	(1=0)
			CALL PutBlock	
	ELSE
			LD	HL,#C000+(80*21)+(4*2)	;Row 21, Column 2 (MODE 0)
			ADD A,A
			LD  E,A
			LD  D,0
			ADD HL,DE					;Skipping columns
			CALL DrawBar	
	ENDIF
Prog_Lp2:	LD A,PAL_YELLOW				;PAL_BRIGHTBLUE
			CALL BorderA
			
			LD A,(CURRENT_SLOT)
			CALL SerialSendA			; Request Slot number
							
			LD HL, RX_DATA_ADDR			; Destination of data 
			LD IY, LOAD_SIZE			; Length of data (+1 for slot number + 2 for crc)
Load_Serial: CALL LoadSerBlk		    ; Load block using USB	
			
			LD HL,RX_DATA_ADDR+LOAD_SIZE-3	; Address of number of slot from file
			LD A,(CURRENT_SLOT)			; number of 16k slot to write to eeprom (0-31)
			CP (HL)						; check if slot loaded is correct
			JR NZ,Load_Err				; If not the correct, Manage Error
					

CRC_Check:	LD DE, RX_DATA_ADDR			; DE=Beginning of loaded area
			LD HL, $0000				; HL will have the sum of bytes for CRC
			LD BC, LOAD_SIZE-CRC_SIZE	; All Data - CRC Size to be checked
CRC_Lp:
			LD A,(DE)
			ADD A,L
			LD L,A
			JR NC, No_Carry_Lp
			INC H						; Add Carry when present
No_Carry_Lp:
			INC DE						; Next Data 
			DEC BC						; One byte less to process
			LD A,B
			OR C
			JR NZ, CRC_Lp				; Loop until all data is checked
			
			LD IX,DE
			LD DE,(IX)					; Load DE with CRC from file

			OR A						; Clear carry flag
			SBC HL,DE					; substract computed CRC
			JR Z, CRC_Good				; ok, continue with burning

Load_Err:	JR Prog_Lp2					; Signal Reload of Slot
			
CRC_Good:	LD A, PAL_BRIGHTGREEN		;PAL_BRIGHTGREEN
			CALL BorderA			
			DDNTR_CONFIGURATION 6		; Enable Writes
			SLOTZONE0 0					; Page in External ROM --> Needed for programming
			LD HL, RX_DATA_ADDR			; First address is scratch area
			CALL Program_Sector			; Erase and then burn 4* 4k eeprom Sectors
			LD A,(CURRENT_SLOT)			; Update Current Slot
			INC A
			LD (CURRENT_SLOT),A
			CP BURN_SLOTS						
			JP NZ, Prog_Lp				; Cycle all 32 Slots
			DDNTR_CONFIGURATION 4		; Disable Writes

End_Reboot:	LD A, $AA					; Signal end of transmission
			CALL SerialSendA
			JP DDNTRRESET				; Enable Dandanator and jump to menu


;------------------------------------------------------------------------------
;PROGRAMSECTOR - 
; (CURRENT_SLOT) = Number of slot (0..31)
; HL = Address of data (16k = 4 sectors x 4K)
; C will be counting from 0 to 3
; Number in screen will be 1 to 4
; Adding (CURRENT_SLOT) and C result in the sector number, range 0..127 stored in B register
; B will be copied to A before calling SSTSECERASE and SSTSECTPROG
; HL will begin with the address of first 4K sector and incremented 4k by 4k prior to calling SSTSECTPROG
;------------------------------------------------------------------------------
Program_Sector:
			LD C,0						; N.of sector in this programming area (0..3)
Prog_Sector_Lp:
			PUSH HL						; Save Initial address
			PUSH BC						; Save copy of C (0..3)
			LD A,(CURRENT_SLOT)			; N.slot (0..31), need to convert to sector (*4)
			OR A						; Make sure there is not Carry
			RLA							; * 2
			RLA							; * 4 -> stored in acummulator A
			POP BC						; Retrieve copy of C (0..3)
			ADD C						; Add sector subnumber(0..3) to acummulator A
			LD B,A						; Copy Sector (0-127) from A to B for next usage
			PUSH BC						; Save copy of B and C

		
			
			;POP BC
			;PUSH BC
			;LD A,B						; Get number of Sector
			CALL SSTSECERASE			; Tell Dandanator to erase sector in register A
			POP BC						; Retrieve copy of B and C
			POP HL						; Retrieve Address of data
			PUSH HL						; Save this Address of data (4 of 16k)
			PUSH BC						; Save copy of B and C
			LD A, B						; Sector (0.127) to write
			CALL SSTSECTPROG			; Tell Dandanator to write sector in register A with data begining HL
			;POP BC						; Retrieve copy of B and C (only C is needed this time, B is n.sector 0..127)
			;PUSH BC						; Save copy of B and C
			;LD A,B						; A = N.Sector
			;LD C,3						; 3 = FINISHED, A = N.SECTOR
			;CALL DISPBAR				; DISPBAR returns with A=N.SECTOR

			POP BC						; Retrieve copy of B and C (only C is needed this time, B is discarded now)
			POP HL						; Get Address of data

			LD DE, SECTOR_SIZE			; Length of sectors 
			ADD HL,DE					; Calculate next address
			INC C						; Next subsector 0..3
			LD A,C						; Copy the value of this sector to acumulator A
			CP SECTORS_SLOT				; Check A<4 (only 0..3 is valid)
			JR C, Prog_Sector_Lp		; REPEAT WHILE subsector<4
			
			RET


	IF (1=0)
Disp7Seg:	PUSH AF						; Save All regs
			PUSH BC
			PUSH DE
			PUSH HL
			
			LD A, (CURRENT_DIGITS)
			INC A
DigAdjust
			LD	(CURRENT_DIGITS),A
			AND $0F						; Num 0-9
			CP	#0A
			JR	C,DigNoAdjust
			LD A, (CURRENT_DIGITS)
			ADD	A,6						;Converts #xA to next tens
			JR	DigAdjust
DigNoAdjust
			LD D,0
			LD E,A						; Point to number
			LD HL, Units
			ADD HL,DE
			LD A,(HL)
			LD D,7
			LD BC,$7F09					; Pen 9
						
LoopDigUnit:OUT (C),C
			LD E, PAL_BLACK
			RRCA
			JR NC, UnitSegmentOff
			LD E, $52
UnitSegmentOff: 
			OUT (C),E	
		 	INC C
		 	DEC D
		 	LD H,A
		 	LD A,D
		 	OR A
		 	LD A,H
		 	JR NZ, LoopDigUnit 
		 	
		 	LD A, (CURRENT_DIGITS)
			AND $F0						; Num 0-9
			RRCA
			RRCA
			RRCA
			RRCA						; Move to low nibble
			LD D,0
			LD E,A						; Point to number
			LD HL, Tens
			ADD HL,DE
			LD A,(HL)
			LD D,4
			LD BC,$7F05					; Pen 5
						
LoopDigTens:OUT (C),C
			LD E, PAL_BLACK
			RRCA
			JR NC, TensSegmentOff
			LD E, $52	
TensSegmentOff: 
			OUT (C),E	
		 	INC C
		 	DEC D
		 	LD H,A
		 	LD A,D
		 	OR A
		 	LD A,H
		 	JR NZ, LoopDigTens
			
		 	POP HL
		 	POP DE
		 	POP BC
		 	POP AF
		 	
		 	RET
			 
			 
Units:		DEFB $7B, $60, $5D, $75, $66, $37, $3F, $61, $7F, $77	; Binary encoded (Palette 15 is bit 6 to Palette 9, bit 0) 
Tens:		DEFB $00, $0C, $0B, $0E									; Binary encoded (Palette 8 is bit 3 to palette 5, bit 0)

	ENDIF

	INCLUDE "sstwriter_CPC_v3.asm"
	INCLUDE "usbserial115.2k_CPC_v3.asm"
	INCLUDE "graphics_mode0.asm"
	INCLUDE "bigtext_12x32.asm"

LOADER_RAM_ADDR 	EQU $B200			; Origin of the code
WSTACK_LOADER_ADDR	EQU $BFFA			; Stack During Loader
RX_DATA_ADDR		EQU $6000			; Destination of received USB Data
CURRENT_SLOT		EQU $A003			; Current Slot
CURRENT_DIGITS		EQU	$A004			; Current Slot in #XY format		
CURRENT_DISP_COLOR	EQU $A005			; Display Digits Color
LOAD_SIZE			EQU $4003			; Size of each of the 32 blocks received by USB
CRC_SIZE			EQU $2				; CRC Size of received data
BURN_SLOTS			EQU 32				; Number of Slots to burn
SECTORS_SLOT		EQU 4				; Number of Sectors in Slot
SECTOR_SIZE			EQU $1000			; Size of SST39SF40 Sector : 4KB

IYSCRATCH_ADDR 		EQU $BFFF

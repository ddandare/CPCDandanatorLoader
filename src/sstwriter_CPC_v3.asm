; ----------------------------------------------------------------------------------------  
; CPC Dandanator! Mini HW v1.2/1.3 - Eeprom Write SST39SF040
;
; Typical Usage -> 	LD A, SectN					; Loop 128 sectors
;					CALL SSTSECTERASE			;   |
;					LD A, SectN					;	|
;					LD HL, RAMSOURCE4KBLOCK		;	|
;					CALL SSTSECTPROG			;	|
;					JP DDNTRRESET
;
; Dandare - May 2018
; ----------------------------------------------------------------------------------------  	

	
		
; ----------------------------------------------------------------------------------------
; ERASE SECTOR 
;     A  = Sector number (39SF040 has 128 4k sectors)
;
; 	****  MUST BE RUN FROM RAM, DI, AND WITH EXTERNAL EEPROM (ZONE0) PAGED IN in 0x0000
;	****  NO OTHER ZONE PAGED IN, Commands Enabled
;	****  Also Write Operations must be enabled and serial operations disabled
;
; ----------------------------------------------------------------------------------------
SSTSECERASE:PUSH AF						; Save Sector Number
			AND 3						; Get Sector within Page
			SLA A						; Move to A13,A12 in DE
			SLA A
			SLA A
			SLA A
			LD D,A		
			LD E,0
			
SE_Step1:	SLOTZONE0 1					; Set Slot 1
			LD BC, J5555				; Five Step Command to allow Sector Erase
			LD A, $AA
			LD (BC),A			
SE_Step2:	SLOTZONE0 0					
			LD BC, J2AAA				
			LD A, $55
			LD (BC),A	
SE_Step3:	SLOTZONE0 1
			LD BC, J5555				
			LD A, $80
			LD (BC),A
SE_Step4:	LD BC, J5555				
			LD A, $AA
			LD (BC),A
SE_Step5:	SLOTZONE0 0
			LD BC, J2AAA				
			LD A, $55
			LD (BC),A
SE_Step6:	POP AF						; Get Sector number back
			SRL A
			SRL A						; Get Slot from Sector
			SLOTZONE0REGA				; Change to slot contained in reg A
			LD A, $30					; Actual sector erase		
			LD (DE),A
			
			LD H,B						; Point HL to Zone 0: 0x0000-0x3FFF
			LD L,C
			
POLL_DQ6:	LD A,(HL)					; Loop until reads do not toggle
			XOR (HL)
			JR NZ, POLL_DQ6
ERASE_DONE:
	
			;SLOTZONE0 0					; Return to slot 0 - OPTIONAL
			
			RET							; 
; ----------------------------------------------------------------------------------------



; ----------------------------------------------------------------------------------------
; PROGRAM Sector
;    A  = Sector number (39SF040 has 128 4k sectors)
;	 HL = RAM Address of sector to program : Source of data
;
; 	****  MUST BE RUN FROM RAM, DI, AND WITH EXTERNAL EEPROM (ZONE0) PAGED IN in 0x0000
;	****  NO OTHER ZONE PAGED IN, Commands Enabled
;	****  Also Write Operations must be enabled and serial operations disabled
;
; ... Sector must be erased first
; ----------------------------------------------------------------------------------------
SSTSECTPROG:LD IXH,A					; Save Sector Number				
			AND 3						; Get two least significant bits of sector number
			SLA A						; Move these bits to A13-A12
			SLA A
			SLA A
			SLA A
			LD D,A						; DE is the beginning of the write area (4k sector aligned) within Slot.
			LD E,0
			LD A,IXH					; Adjust sector number to slot number (divide by 4)
			SRL A
			SRL A
			LD IXH,A					; Now ixh contains the slot number
SECTLP:									; Sector Loop 4096 bytes
			
PB_Step1:	SLOTZONE0 1					; Set Slot 1
			LD BC, J5555				; Three Step Command to allow byte-write
			LD A, $AA
			LD (BC),A
PB_Step2: 	SLOTZONE0 0					; Set Slot 0
			LD BC, J2AAA
			LD A, $55
			LD (BC),A
PB_Step3: 	SLOTZONE0 1					; Set Slot 1
			LD BC, J5555
			LD A, $A0
			LD (BC),A	
PB_Step4:	LD A,IXH					; Retrieve slot number
			SLOTZONE0REGA				; Change to slot contained in reg A

			LD A,(HL)					; Write actual byte
			LD (DE),A
										; Datasheet asks for 14us write time, but loop takes longer between actual writes
			INC HL						; Next Data byte
			INC DE						; Next Byte in sector
			LD A,D						; Check for 4096 iterations (D=0x_0, E=0x00)
			AND 15						; Get 4 lower bits
			OR E						; Now also check for a 0x00 in E
			JR NZ, SECTLP
			
			;SLOTZONE0 0					; Return to slot 0 - OPTIONAL
			
			RET
; ----------------------------------------------------------------------------------------



; ----------------------------------------------------------------------------------------
; RESET Dandanator to Slot 0
; 
; ----------------------------------------------------------------------------------------
DDNTRRESET: 
			SLOTZONE0 0					; Go to slot 0
			LD A,4						; Ensure Serial Operations and Write Enable are off
			TRIGGER
			LD (IY),A
			LD A,$82					; Disable Zone 1, Enable Zone 0 and Zone allocations to A15=0. 
			TRIGGER						
			LD (IY),A
RESET:		RST 0
; ----------------------------------------------------------------------------------------


J5555				EQU $1555			; Jedec $5555 with a15,a14=0 to force Zone0 - Change to slot 1 in advance is needed 
J2AAA				EQU	$2AAA			; Jedec $2AAA - Change to slot 0 in advance is needed




			
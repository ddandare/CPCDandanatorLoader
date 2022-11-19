; ----------------------------------------------------------------------------------------	
	MACRO TRIGGER
			defb $FD, $FD				; Trigger
	ENDM
	
; ----------------------------------------------------------------------------------------
	MACRO SLOTZONE0REGA
			LD IY, IYSCRATCH_ADDR		
		;	LD C,(IY)					; Save (IY) Data. no slot nor internal ROM should be paged in IYSCRATCH zone
			LD B, A
			TRIGGER						; Trigger
			LD (IY),B					; Command
		;	LD (IY),C					; Restore RAM contents
	ENDM

; ----------------------------------------------------------------------------------------
	MACRO SLOTZONE0 slotn
			LD A,slotn
			SLOTZONE0REGA
	ENDM
	
; ----------------------------------------------------------------------------------------
	MACRO SLOTZONE1REGA
			LD IY, IYSCRATCH_ADDR	
		;	LD B,(IY)					; Save (IY) Data. no slot nor internal ROM should be paged in IYSCRATCH zone
			LD C, A	
			TRIGGER						; Trigger
			LD (IY),C					; Command
		;	LD (IY),B					; Restore RAM contents
	ENDM

; ----------------------------------------------------------------------------------------
	MACRO SLOTZONE1 slotn
			LD A,slotn
			SLOTZONE1REGA
	ENDM
	
; ----------------------------------------------------------------------------------------
	MACRO DDNTR_CONFIGURATIONREGA
			
			LD IY, IYSCRATCH_ADDR
		;	LD C,(IY)					; Save (IY) Data. no slot nor internal ROM should be paged in IYSCRATCH zone
			TRIGGER						; Trigger
			LD (IY),A					; Command
		;	LD (IY),C					; Restore RAM contents
	ENDM

; ----------------------------------------------------------------------------------------	
	MACRO DDNTR_CONFIGURATION value 	; when b7=0: 	b4-b3:	FollowRomEnable Zone0 slot lower bits: slots 28,29,30 and 31
										;				bit 2:  Out bit to USB (Serial Bitbanging): "1" Idle.
										;				bit 1:  EEprom write enable "1" or disable "0"
										;				bit 0:  Serial port ena/dis - When enabled, LD A,(HL) returns serial RX in bit 0. 
										; when b7=1:	bit 6: 	Wait for "RET" (0xC9) to execute action
										;				bit 5:  Disable Dandanator commands until reset
										;				bit 4:  Enable FollowRomEn on RET (only read if bit 6 = 1)
										;				b3-b2: 	A15 values for zone 1 and zone 0. Zone 0 can be at 0x0000 or 0x8000, Zone 1 can be at 0x4000 or 0xC000
										;				b1-b0:  Status of EEPROM_CE for Zone 1 and zone 0. "0": Enabled, "1" Disabled.
		LD A, value
		DDNTR_CONFIGURATIONREGA
	ENDM	
	
; ----------------------------------------------------------------------------------------	

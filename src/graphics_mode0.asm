; All related to mode 0


;------------------------------------------------------------------------------------------------------------------------
; Sets Palette from list pointed by HL, Starts by border and goes backwards
;------------------------------------------------------------------------------------------------------------------------
SetPalette: LD BC, $7F10				; GateArray Border
			
SPLoop:		OUT (C),C					; Backwards starting with border color
			OUTI 						; OUTS (HL) to (BC), Incs HL and Decs B
			INC B						; Restore B
			DEC C						; Next iteration
			JP P, SPLoop				; Jump until C is negative
			RET
;------------------------------------------------------------------------------------------------------------------------



;------------------------------------------------------------------------------------------------------------------------
; Sets Black Palette
;------------------------------------------------------------------------------------------------------------------------
SetBlkPal:	LD HL, BLACKPAL
			JR SetPalette				; RET is done at SetPalette
;------------------------------------------------------------------------------------------------------------------------
BLACKPAL: 	DEFB PAL_BLACK, PAL_BLACK, PAL_BLACK, PAL_BLACK, PAL_BLACK, PAL_BLACK, PAL_BLACK, PAL_BLACK
			DEFB PAL_BLACK, PAL_BLACK, PAL_BLACK, PAL_BLACK, PAL_BLACK, PAL_BLACK, PAL_BLACK, PAL_BLACK, PAL_BLACK ; Black Palette



;------------------------------------------------------------------------------------------------------------------------
; Clear Screen - Sets Black Palette and clear all screen contents
;------------------------------------------------------------------------------------------------------------------------
ClrScr:  	CALL SetBlkPal				; Set Black Palette
			LD BC, $4000-1				; All Screen size -1
			LD HL, $C000				; Origin first screen byte
			LD DE, HL					; Destination, next byte
			INC E
			LD (HL),0					; Clear first screen byte
			LDIR						; Clear remaining screen	
			RET
;------------------------------------------------------------------------------------------------------------------------
			
			

;------------------------------------------------------------------------------------------------------------------------
; Gamusino Colour // old Border A
;------------------------------------------------------------------------------------------------------------------------
BorderA:	LD BC, $7F09 ;$7F10			;Colour 9	; GateArrayBorder
			OUT (C),C
			OUT (C),A
			RET					
;------------------------------------------------------------------------------------------------------------------------


	IF	(1=0)
;------------------------------------------------------------------------------------------------------------------------
; Put Square
;------------------------------------------------------------------------------------------------------------------------
PutBlock:	PUSH AF
			LD HL, 1608	+ $C000 + 8192				; first pixel of line
			CALL SemiBlock
			POP AF
			LD HL, 1688 + $C000
			CALL SemiBlock
			
			RET



SemiBlock:			
			RLCA						; A is Sector count
			LD D,0
			LD E,A
			ADD HL,DE					; Pointing at top left of current square
			LD B,4
			LD DE, $7FF
put4lines:	LD (HL), $CC
			INC HL
			LD (HL), $CC
			ADD HL,DE
			DJNZ put4lines
			
			ret		

	ENDIF

PAL_WHITE			EQU $40
PAL_SEAGREEN		EQU $42
PAL_PASTELYELLOW	EQU $43
PAL_BLUE			EQU $44
PAL_PURPLE			EQU $45
PAL_CYAN			EQU $46
PAL_PINK			EQU $47
PAL_BRIGHTYELLOW	EQU $4A
PAL_BRIGHTWHITE		EQU $4B
PAL_BRIGHTRED		EQU $4C
PAL_BRIGHTMAGENTA	EQU $4D
PAL_ORANGE			EQU $4E
PAL_PASTELMAGENTA	EQU $4F
PAL_BRIGHTGREEN		EQU $52
PAL_BRIGHTCYAN		EQU $53
PAL_BLACK			EQU $54
PAL_BRIGHTBLUE		EQU $55
PAL_GREEN			EQU $56
PAL_SKYBLUE			EQU $57
PAL_MAGENTA			EQU $58
PAL_PASTELGREEN		EQU $59
PAL_LIME			EQU $5A
PAL_PASTELCYAN		EQU $5B
PAL_RED				EQU $5C
PAL_MAUVE			EQU $5D
PAL_YELLOW			EQU $5E
PAL_PASTELBLUE		EQU $5F
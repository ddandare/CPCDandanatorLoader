	ORG 	LOADER_LAUNCHER_RAM_ADDR	
	
	OUTPUT 	"demo_launch_loader.bin"	
	
; ----------------------------------------------------------------------------------------
; MAIN LOADER LAUNCHER - Demo - Actual laucher is managed by the game menu
;
; ----------------------------------------------------------------------------------------	
	di
	ld sp,0
	LD BC, $7F8C	; Mode 0, Disable Roms, Disable VBL Interrupt generation
    OUT (C),C

	ld hl, screen 	; Move screen to visible area
	ld de, $C000
	ld bc, $4000
	ldir

	ld hl, loaderbin ; Move Loader to its position
	ld de, LOADER_RAM_ADDR
	ld bc, endloaderbin-loaderbin
	ldir


	ld iy, loaderbin-17
	call SetPalSNA

	jp LOADER_RAM_ADDR

SetPalSNA: 								; IY Points to SNA Params
			LD B, GA_PORT				; Gate Array Port
			LD C, 0						; Start with Pen 0
			LD D, GA_PAL_NUM			; Number of registers to write - Palette
SLPalLoop:	OUT (C),C					; Select Pen
			LD A,(IY)					; Get Pen
			ADD PAL_BASE				; Add Base Address
			OUT (C),A					; Set Pen
			INC IY						; Next Pen
			INC C						; Next Pen Register
			DEC D
			JR NZ, SLPalLoop			; Cycle all pens and border
			RET


screen:
	INCBIN  "loader_cpc.scr"
loaderbin:
	INCBIN	"loader_cpc.bin"
endloaderbin:

LOADER_RAM_ADDR 			EQU $B200			; Origin of the launcher code
LOADER_LAUNCHER_RAM_ADDR 	EQU $4000			; Origin of this code

GA_PORT						EQU $7F
PAL_BASE					EQU $40
GA_PAL_NUM					EQU 17				; Pen 0-15 and Border

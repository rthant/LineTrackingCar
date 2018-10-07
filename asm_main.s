SIM_SCGC5 EQU 0x40048038

;inputs
PORTD_PCR0 EQU 0x4004C000  ; pin D0 for LT1
PORTA_PCR4 EQU 0x40049010  ; pin A4 for LT2
PORTD_PCR4 EQU 0x4004C010  ; pin D4 for LT3

;outputs
PORTC_PCR8 EQU 0x4004B020  ; pin C8 for IN1 
PORTC_PCR9 EQU 0x4004B024  ; pin C9 for IN2
PORTA_PCR13 EQU 0x40049034 ; pin A13 for IN3
PORTD_PCR5 EQU 0x4004C014  ; pin D5 for IN4

PORTA_PCR5 EQU 0x40049014  ; pin A5 for ENA
PORTD_PCR2 EQU 0x4004C008  ; pin D2 for ENB

;port registers
;A: input and output
GPIOA_PDDR EQU 0x400FF014  ; A pin data
GPIOA_PDIR EQU 0x400FF010  ; A input data
GPIOA_PSOR EQU 0x400FF004  ; A set output
GPIOA_PCOR EQU 0x400FF008  ; A clear output
;C: output
GPIOC_PDDR EQU 0x400FF094  ; C pin data
GPIOC_PSOR EQU 0x400FF084  ; C set output
GPIOC_PCOR EQU 0x400FF088  ; C clear output
;D: input and output
GPIOD_PDDR EQU 0x400FF0D4  ; D pin data
GPIOD_PDIR EQU 0x400FF0D0  ; D input data
GPIOD_PSOR EQU 0x400FF0C4  ; D set output
GPIOD_PCOR EQU 0x400FF0C8  ; D clear output

;input masks
LT1 EQU 0x00000001  ; PTD0, 2^0 
LT2 EQU 0x00000010  ; PTA4, 2^4
LT3 EQU 0x00000010  ; PTD4, 2^4
	
;output masks
IN1 EQU 0x00000100  ; PTC8, 2^8
IN2 EQU 0x00000200  ; PTC9, 2^9
IN3 EQU 0x00002000  ; PTA13, 2^13
IN4 EQU 0x00000020  ; PTD5, 2^5
ENA EQU 0x00000020  ; PTA5, 2^5
ENB EQU 0x00000004  ; PTD2, 2^2
	
	AREA asm_area, CODE, READONLY
	EXPORT asm_main
	
asm_main
	
	BL init_gpio

status
	LDR r0,= GPIOA_PDIR
	LDR r1, [r0]			; obtain status of Port A inputs (only for LT2)
	LDR r0,= GPIOD_PDIR      
	LDR r2, [r0]			; obtain status of Port D inputs (for LT1 and LT3)
	
	LDR r3,= LT1
	LDR r4,= LT2
	LDR r5,= LT3
	
	TST r1, r4     ; check LT2 status
	BNE stateA     ; if off, go foward
	
	TST r2, r5     ; check LT3 status
	BEQ stopcheck  ; if on, stopcheck
	
	TST r2, r3  ; check LT1 status
	BL forward  ; reaction delay to counteract overcorrection
	BEQ stateC  ; if on, go right and recheck
	BNE stateD  ; if off, stop and recheck
	
stopcheck
	TST r2, r3  ; check LT1 status
	BEQ stateD  ; if on, stop and recheck
	BL forward  ; reaction delay to counteract overcorrection
	BNE stateB  ; if off, go left and recheck
	
stateA	
	BL forward ; call foward subroutine to run motors foward
	B status   ; recheck status
stateB
	BL left    ; call left subroutine to run motors left
	B status   ; recheck status
stateC
	BL right   ; call right subroutine to run motors right
	B status   ; recheck status
stateD
	BL stop    ; call stop subroutine to stop motors
	B status   ; recheck status
	
forward
	LDR r1,= GPIOA_PSOR  ; obtain PSOR addresses to set pins to on
	LDR r2,= GPIOC_PSOR
	LDR r3,= GPIOD_PSOR
	
	LDR r4,= GPIOA_PCOR  ; obtain PCOR addresses to set pins to off
	LDR r5,= GPIOC_PCOR
	
	LDR r0,= ENA
	STR r0, [r1]  ; ENA (pin A5) set pos in Port A to on
	LDR r0,= ENB
	STR r0, [r3]  ; ENB (pin D2) set pos in Port D to on
	LDR r0,= IN1
	STR r0, [r2]  ; IN1 (pin C8) set pos in Port C to on
	LDR r0,= IN2
	STR r0, [r5]  ; IN2 (pin C9) set pos in Port C to off
	LDR r0,= IN3
	STR r0, [r4]  ; IN3 (pin A13) set pos in Port A to off
	LDR r0,= IN4
	STR r0, [r3]  ; IN4 (pin D5) set pos in Port D to on	
	BX LR  ; return to calling address
	
left
	LDR r1,= GPIOA_PSOR  ; PSOR to set pins to on
	LDR r2,= GPIOC_PSOR
	LDR r3,= GPIOD_PSOR
	
	LDR r5,= GPIOC_PCOR  ; PCOR to set pins to off
	LDR r6,= GPIOD_PCOR
	
	LDR r0,= ENA
	STR r0, [r1]  ; ENA (pin A5) set pos in Port A to on
	LDR r0,= ENB
	STR r0, [r3]  ; ENB (pin D2) set pos in Port D to on
	LDR r0,= IN1
	STR r0, [r2]  ; IN1 (pin C8) set pos in Port C to on
	LDR r0,= IN2
	STR r0, [r5]  ; IN2 (pin C9) set pos in Port C to off
	LDR r0,= IN3
	STR r0, [r1]  ; IN3 (pin A13) set pos in Port A to on
	LDR r0,= IN4
	STR r0, [r6]  ; IN4 (pin D5) set pos in Port D to off
	BX LR  ; return to calling address

right
	LDR r1,= GPIOA_PSOR  ; PSOR to set pins to on
	LDR r2,= GPIOC_PSOR
	LDR r3,= GPIOD_PSOR
	
	LDR r4,= GPIOA_PCOR  ; PCOR to set pins to off
	LDR r5,= GPIOC_PCOR  
	
	LDR r0,= ENA
	STR r0, [r1]  ; ENA (pin A5) set pos in Port A to on
	LDR r0,= ENB
	STR r0, [r3]  ; ENB (pin D2) set pos in Port D to on
	LDR r0,= IN1
	STR r0, [r5]  ; IN1 (pin C8) set pos in Port C to off
	LDR r0,= IN2
	STR r0, [r2]  ; IN2 (pin C9) set pos in Port C to on
	LDR r0,= IN3
	STR r0, [r4]  ; IN3 (pin A13) set pos in Port A to off
	LDR r0,= IN4
	STR r0, [r3]  ; IN4 (pin D5) set pos in Port D to on
	BX LR  ; return to calling address

stop
	LDR r4,= GPIOA_PCOR  ; PCOR to set pins to off
	LDR r5,= GPIOC_PCOR 
	LDR r6,= GPIOD_PCOR	
	
	LDR r0,= ENA
	STR r0, [r4]  ; ENA (pin A5) set pos in Port A to off
	LDR r0,= ENB
	STR r0, [r6]  ; ENB (pin D2) set pos in Port D to off
	BX LR  ; return to calling address

init_gpio
	;initialize clock
	LDR r0,= SIM_SCGC5
	LDR r1, [r0]
	LDR r2,= 0x00003E00  ; mask to turn clock on
	ORRS r1, r2  ; setup clock to run
	STR r1, [r0]
	
	;input setup
	LDR r1,= 0x00000103  ; mask to set pins to input
	LDR r0,= PORTD_PCR0  
	STR r1, [r0]		 ; setup LT1 to input
	LDR r0,= PORTA_PCR4  
	STR r1, [r0]		 ; setup LT2 to input
	LDR r0,= PORTD_PCR4  
	STR r1, [r0]		 ; setup LT3 to input
	
	;output setup
	LDR r1,= 0x00000100  ; mask to set pins to output
	LDR r0,= PORTC_PCR8
	STR r1, [r0]		 ; setup IN1 to output
	LDR r0,= PORTC_PCR9
	STR r1, [r0]		 ; setup IN2 to output
	LDR r0,= PORTA_PCR13
	STR r1, [r0]		 ; setup IN3 to output
	LDR r0,= PORTD_PCR5
	STR r1, [r0]		 ; setup IN4 to output
	
	LDR r0,= PORTA_PCR5
	STR r1, [r0]		 ; setup ENA to output
	LDR r0,= PORTD_PCR2
	STR r1, [r0]		 ; setup ENB to output
	
	;input config
	LDR r1,= LT1  ; PTD0
	LDR r2,= LT2  ; PTA4
	LDR r3,= LT3  ; PTD4
	
	LDR r4,= GPIOA_PDDR
	LDR r0, [r4]
	BICS r0, r2   ; set LT2 (pin A4) to input (0)
	STR r0, [r4]  ; update PDDR A with input LT2
	
	LDR r4,= GPIOD_PDDR
	LDR r0, [r4]
	ADD r1, r1, r3  ; add LT1 and LT3 to create input mask D
	BICS r0, r1     ; set pins D0 and D4 to input (0)
	STR r0, [r4]	; update PDDR D with inputs LT1 and LT3
	
	;output config
	LDR r1,= IN1  ; PTC8
	LDR r2,= IN2  ; PTC9
	LDR r3,= IN3  ; PTA13
	LDR r4,= IN4  ; PTD5
	LDR r5,= ENA  ; PTA5
	LDR r6,= ENB  ; PTD2
	
	LDR r7,= GPIOA_PDDR
	LDR r0, [r7]
	ADD r3, r3, r5  ; add IN3 and ENA to create output mask A
	ORRS r0, r3     ; set pins A5 and A13 to output (1)
	STR r0, [r7]    ; update PDDR A with outputs A5 and A13
	
	LDR r7,= GPIOC_PDDR
	LDR r0, [r7]
	ADD r1, r1, r2  ; add IN1 and IN2 to create output mask C
	ORRS r0, r1     ; set pins C8 and C9 to output (1)
	STR r0, [r7]    ; update PDDR C with outputs C8 and C9
	
	LDR r7,= GPIOD_PDDR
	LDR r0, [r7]
	ADD r4, r4, r6  ; add IN4 and ENB to create output mask D
	ORRS r0, r4     ; set pins D2 and D5 to output (1)
	STR r0, [r7]    ; update PDDR D with outputs D2 and D5
	BX LR  ; return to calling address
	
	END
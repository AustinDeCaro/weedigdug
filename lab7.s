	AREA interrupts, CODE, READWRITE
	EXPORT lab7
	EXPORT FIQ_Handler
	EXPORT pin_connect_block_setup
	EXPORT interrupt_init
	EXPORT timer_init
	EXTERN uart_init
	EXTERN read_character
	EXTERN read_string
	EXTERN output_character
	EXTERN output_string
	EXTERN div_and_mod

intro_screen = "Welcome	to Wee Dig Dug!\r\nUse WASD keys to control movement\r\nPress spacebar to shoot air pump\r\nUser Interrupt Button pauses the game\r\nPress Enter to start: \r\n",0
score_total = "SCORE: 00000\r\n",0 			;Score
game_string = 			 	"ZZZZZZZZZZZZZZZZZZZZZ\r\n",0
game_string1 = 			  	"Z                   Z\r\n",0
game_string2 = 			  	"Z                   Z\r\n",0
game_string3 = 				"Z###################Z\r\n",0
game_string4 = 				"Z###################Z\r\n",0
game_string5 = 				"Z###################Z\r\n",0
game_string6 = 				"Z###################Z\r\n",0
game_string7 = 				"Z###################Z\r\n",0
game_string8 = 				"Z######## > ########Z\r\n",0
game_string9 = 				"Z###################Z\r\n",0
game_stringA = 				"Z###################Z\r\n",0
game_stringB = 				"Z###################Z\r\n",0
game_stringC =				"Z###################Z\r\n",0
game_stringD = 				"Z###################Z\r\n",0
game_stringE = 				"Z###################Z\r\n",0
game_stringF = 				"Z###################Z\r\n",0
game_stringG = 				"ZZZZZZZZZZZZZZZZZZZZZ\r\n",0
    
	ALIGN

lab7
		STMFD sp!, {lr}
		MOV r0, #0
		BL display_digit_on_7_seg
		MOV r0, #0x77
		BL illuminate_RGB_LED
		LDR r4, =intro_screen
		BL output_string

read_start
		BL read_character
		CMP r0, #0xD					;wait for player to hit enter to start
		BNE read_start										

		BL output_screen
		LDR r4, =0x40004000
		LDR r0, =0x7D0C
		STR r0, [r4], #4
		BL compute_enemy
		STR r0, [r4], #4
		BL compute_enemy
		STR r0, [r4], #4
		BL compute_enemy
		STR r0, [r4], #4

		LDR r4, =0x40004004
		MOV r6, #0
place_enemies
		LDR r2, [r4], #4
		LDR r3, =0xFFFFFE00				;Clear all but column row
		BIC r0, r2, r3
		MOV r1, #0x42
		BL insert_symbol
		MOV r1, #0x20
		LSR r5, r2 #9					;Get direction as lower bits
		CMP r5, #2
		BGE	horizontal_big
vertical_big
		ADD r0, r0, #0x20				;Add 1 to rows LSB
		BL insert_symbol
		SUB r0, r0, #0x30				;Subtract 2 from row, making it 1 less than original row
		BL insert_symbol
		B little_enemies
horizontal_big
		ADD r0, r0, #0x20				;Add 1 to rows LSB
		BL insert_symbol
		SUB r0, r0, #0x30				;Subtract 2 from row, making it 1 less than original row
		BL insert_symbol

little_enemies
		LDR r2, [r4], #4
		LDR r3, =0xFFFFFE00				;Clear all but column row
		BIC r0, r2, r3
		MOV r1, #0x78
		BL insert_symbol
		MOV r1, #0x20
		LSR r5, r2 #9					;Get direction as lower bits
		CMP r5, #2
		BGE	horizontal_little
vertical_little
		ADD r0, r0, #0x20				;Add 1 to rows LSB
		BL insert_symbol
		SUB r0, r0, #0x30				;Subtract 2 from row, making it 1 less than original row
		BL insert_symbol
		B game_begin
horizontal_little
		ADD r0, r0, #0x20				;Add 1 to rows LSB
		BL insert_symbol
		SUB r0, r0, #0x30				;Subtract 2 from row, making it 1 less than original row
		BL insert_symbol
		
game_begin
		CMP r6, #0
		ADD r6, r6, #1
		BEQ little_enemies				;If we need one more little enenmy, go back and do it again.
		
		MOV r0, #1						;Start level 1
		BL display_digit_on_7_seg
		MOV r0, #15						;Number of lives equals 4
		BL illuminateLEDs
		MOV r0, #0x67
		BL illuminate_RGB_LED			;Change RGB to green to say game is going
		
		BL interrupt_init		;Start Timers and such

		LDR r0, =0xE000401C		;Match Register value
		LDR r1, =0x00800000		;Clock will reset at this value
		STR r1, [r0]
		LDR r0, =0xE0004014		;Match Control Register 0
		LDR r1, [r0]
		ORR r1, r1, #0x18		;Change bits 4 and 3 to 1 (Bit 4 reset counter, Bit 3 generates interrupt)
		STR r1, [r0]
		LDR r0, =0xE0008014		;Match Control Register 1
		LDR r1, [r0]
		ORR r1, r1, #0x28		;Change bits 5 and 3 to 1 (Bit 5 stop counter, Bit 3 generates interrupt)
		STR r1, [r0]
		LDR r0, =0xE0004000
		LDR r1, [r0, #4]
		ORR r1, #2
		STR r1, [r0,#4]			;reset the clock 0
		BIC r1, r1, #2
		STR r1, [r0, #4]
		LDR r0, =0xE0008000
		LDR r1, [r0, #4]
		ORR r1, #2
		STR r1, [r0,#4]			;reset the clock 1
		BIC r1, r1, #2
		STR r1, [r0, #4]
		;Start the game here
game_loop
		B game_loop				;infinite loop to repeat while game is going on
done
		STMFD sp!, {lr}
		BX lr



compute_enemy					;creates and stores enemy locations to memory
		STMFD sp!, {r2-r4,lr}
		MOV r1, #11
compute_row
		BL rng							;Row
		ADD r2, r0 , #3					;Gives random row from 3-12
		;row # stored in r2
compute_column
		MOV r1, #15
		BL rng							;Repeat for column1
		ADD r3, r0 , #3					;Gives random column from 3-17
		
		CMP r3, #6
		BLE location_exit
		CMP r3, #14
		BGE location_exit
		   								;otherwise potentially too close to player
		CMP	r2, #5
		BLE location_exit
		CMP r2, #11
		BLT	compute_column
location_exit
		MOV r1, #4						;Compute initial direction (0 = up, 1 = down, 2 = left, 3 = right)
		BL rng
		MOV r0, r0, LSL #4
		ADD r0, r0, r2
		MOV r0, r0, LSL #5
		ADD r0, r0, r3					;puts direction bits in bits 9-10,row in upper bits 5-8, column in lower 5
		
		LDMFD sp!, {r2-r4, lr}
		BX lr

		 

timer_init
		STMFD SP!, {r0-r1, lr}   ; Save registers			
		LDR r0, =0xE0004004		;Timer 0 Control Register
		LDR r1, [r0]
		ORR r1, r1, #1
		STR r1, [r0]
		LDR r0, =0xE0008004		;Timer 1 Control Register
		LDR r1, [r0]
		ORR r1, r1, #1
		STR r1, [r0]
		LDMFD SP!, {r0-r1, lr}
		BX lr

interrupt_init       
		STMFD SP!, {r0-r1, lr}   ; Save registers 
		
		; Push button setup		 
		LDR r0, =0xE002C000
		LDR r1, [r0]
		ORR r1, r1, #0x20000000
		BIC r1, r1, #0x10000000		;PINSEL0 bits 29:28 = 10
		ORR r1, r1, #5
		BIC r1, r1, #0xA	 		;UART0 = 1010
		STR r1, [r0]
		
		;Enable UART0 Interrupts
		LDR r0, =0xE000C004
		LDR r1, [r0]
		ORR r1, r1, #1				;RDA enabled with 1
		STR r1, [r0]  

		; Classify sources as IRQ or FIQ
		LDR r0, =0xFFFFF000
		LDR r1, [r0, #0xC]
		ORR r1, r1, #0x8000 ; External Interrupt 1
		ORR r1, r1, #0x40	; UART0 Interrupt
		ORR r1, r1, #0x10	; Timer 0 Interrupt
		ORR r1, r1, #0x20	; Timer 1 Interrupt
		
		STR r1, [r0, #0xC]

		; Enable Interrupts
		LDR r0, =0xFFFFF000
		LDR r1, [r0, #0x10] 
		ORR r1, r1, #0x8000 ; External Interrupt 1
		ORR r1, r1, #0x40	; UART0 Interrupt
		ORR r1, r1, #0x10	; Timer 0 Interrupt
		ORR r1, r1, #0x20 	; Timer 1 Interrupt
		STR r1, [r0, #0x10]

		; External Interrupt 1 setup for edge sensitive
		LDR r0, =0xE01FC148
		LDR r1, [r0]
		ORR r1, r1, #2  ; EINT1 = Edge Sensitive
		STR r1, [r0]

		; Enable FIQ's, Disable IRQ's
		MRS r0, CPSR
		BIC r0, r0, #0x40
		ORR r0, r0, #0x80
		MSR CPSR_c, r0
 

		LDMFD SP!, {r0-r1, lr} ; Restore registers
		BX lr             	   ; Return



FIQ_Handler
		STMFD SP!, {r0-r12, lr}   ; Save registers 

EINT1			; Check for EINT1 interrupt
		LDR r0, =0xE01FC140
		LDR r1, [r0]
		TST r1, #2
		BEQ TIMER0
		
toggle_clock
		LDR r0, =0xE0004004		;Timer 0 Control Register
		LDR r2, =0xE0004008		;Timer 1 Control Register
		LDR r1, [r0]
		LDR r3, [r2]
		AND r1, r1, #1
		CMP r1, #1				;check if timer is on
		BEQ toggle_off
toggle_on
		;Remove PAUSE from score line
		ORR r1, r1, #1			;turn timer 0 on if off
		ORR r2, r2, #1			;turn timer 1 on if off
		B toggle_finish
toggle_off
		;Add PAUSE to score line
		BIC r1, r1, #1			;otherwise turn timer 0 off
		BIC r2, r2, #1			;otherwise turn timer 1 off
toggle_finish
		STR r1, [r0]
		STR r3, [r2]
		
		B FIQ_Exit
		
		LDR r0, =0xE01FC140
		LDR r1, [r0]
		ORR r1, r1, #2		; Clear Interrupt
		STR r1, [r0]
		B FIQ_Exit

TIMER0	LDR r0, =0xE0004000
		LDR r1, [r0]
		TST r1, #2
		BEQ TIMER1
		BL output_screen
		
		LDR r0, =0xE0004000
		LDR r1, [r0, #4]
		ORR r1, #2
		STR r1, [r0,#4]		;reset the clock
		BIC r1, r1, #2
		STR r1, [r0, #4]
		ORR r1, r1, #2		; Clear Interrupt
		STR r1, [r0]
		B FIQ_Exit

TIMER1	LDR r0, =0xE0008000
		LDR r1, [r0]
		TST r1, #2
		BEQ UART0
		;finish game code here
		LDR r0, =0xE0008000
		ORR r1, r1, #2		; Clear Interrupt
		STR r1, [r0]
		B FIQ_Exit

UART0	;UART0 code here
		LDR r0, =0xE000C008
		LDR r1, [r0]
		AND r1, #0		;Check for UART interupt
		BNE FIQ_Exit	;not the UART then exit
		BL read_character	;Otherwise read from buffer
		MOV r1, r0
		CMP r1, #0x77			;'w'
		MOV r0, #0x5E			;'^'
		BEQ update_direction
		CMP r1, #0x61			;'a'
		MOV r0, #0x3C			;'<'
		BEQ update_direction
		CMP r1, #0x73			;'s'
		MOV r0, #0x76			;'v'
		BEQ update_direction
		CMP r1, #0x64			;'d'
		MOV r0, #0x3E			;'>'
		BEQ update_direction
		CMP r1, #0x20			;' '
		BEQ fire_bullet
		CMP r1, #0x71			;'q'
		BEQ done
		B FIQ_Exit
		
fire_bullet
		;Do bullet calculation here
		B FIQ_Exit
		
update_direction
		LDR r4, =0x40004000		;location of character information
		LSL r1, r0 #9			;Move new direction/character to upper portion of register
		LDR r0, [r4]			
		BIC r0, r0, #0x7FE00		;Clear the current direction
		ORR r0, r0, r1			;Add new direction to character
		;Set movement flag somewhere in memory, so on next clock update we can move the character.
		STR r0, [r4]			;store new direction from input into memory
		B FIQ_Exit
		
clock_reset
		LDR r0, =0xE0004000
		LDR r1, [r0, #4]
		ORR r1, #2
		STR r1, [r0,#4]		;reset the clock
		BIC r1, r1, #2
		STR r1, [r0, #4]
		B FIQ_Exit
		
FIQ_Exit

		LDMFD SP!, {r0-r12, lr}
		SUBS pc, lr, #4

;BEGIN rng SUBROUTINE
rng		   						;random number generated from timer which will be less than the value stored in r1, returned in r0
	STMFD sp!, { r2, r4, lr}
	LDR	r4, =0xE0004008
	LDR r0, [r4] 				;get number from timer
	MOV r2, #-1
	LSL r2, #8
	BIC r0, r0, r2 				;clear everything but lower 4 bits
	BL div_and_mod
	MOV r0, r1					;return mod as the result of rng
	LDMFD sp!, {r2, r4, lr}
	BX lr

;END rng SUBROUTINE

insert_symbol
	STMFD sp!, {r2-r4,lr}			;r0 column and row lower 5 bits is column, upper 4 bits is row, r1 is symbol
	AND r2, r0, #0x1F		;extract column # into r2

	MOV r0, r0, LSR #5		;extract row # into r0
	AND r0, r0, #0xF
	LDR r4, =game_string
	MOV r3, r0, LSL #4		;offset for memory is equal to 24*#rows + # of columns
	ADD r3, r0, r3
	ADD r3, r0, r3
	ADD r3, r0, r3
	ADD r3, r0, r3
	ADD r3, r0, r3
	ADD r3, r0, r3
	ADD r3, r0, r3
	ADD r3, r0, r3			;Multiply # of rows by 24
	ADD r3, r2, r3			;Add # of columns
	STRB r1, [r4, r3]		;Store the ascii in memory

	LDMFD sp!, {r2-r4,lr}
	BX lr
	
output_screen
	STMFD sp!, {r0,r4, lr}
	MOV r0, #0xC
	BL output_character
	LDR r4, =score_total	;Output current bounce total
	BL output_string
	LDR r4, =game_string
	MOV r0, #0				;Counter initialized to 0
output_screen_loop
	BL output_string
	ADD r4, r4, #24
	CMP r0, #16
	ADD r0, r0, #1
	BLE output_screen_loop

	LDMFD sp!, {r0,r4, lr}
	BX lr
	
update_screen
	;code for moving the symbol to a new place on the board
	STMFD sp!, {lr}
	LDR r4, =0x40004000			;+8 is direction,  1 up, 2 right, 3 down, 4 left.
	LDR r1, [r4, #8]
	CMP r1, #1
	BEQ move_up
	CMP r1, #2
	BEQ move_right
	CMP r1, #3
	BEQ move_down
	CMP r1, #4
	BEQ move_left
move_up
	MOV r1, #0x20
	LDR r0, [r4]				;location of symbol
	BL insert_symbol			;clear symbol on board
	LDR r1, [r4, #4]			;load symbol to put back on the board location later
	
	AND r5, r0, #0xF0			;Clear lower bits which are columns location
	CMP r5, #0x10				;If row is 1, we need to bounce down
	BEQ bounce_down
	SUB r0, r0, #0x10			;Move the symbol location up otherwise
	STR r0, [r4]				;Store new address
	BL insert_symbol
	BL output_screen
	B update_done 
bounce_down
	ADD r0, r0, #0x10			;Move the symbol location down a row
	STR r0, [r4] 				;Store new address
	BL insert_symbol			;Update board display
	MOV r3, #3
	STR r3, [r4, #8]			;change direction to be down
	B bounce_increment
move_right
	LDR r0, [r4]				;location of symbol
	MOV r1, #0x20
	BL insert_symbol			;clear symbol on board
	LDR r1, [r4, #4]			;load symbol to put back on the board location later
	
	AND r5, r0, #0xF			;clear upper bits which are the row location
	CMP r5, #0xF				;If columnn is 15 we need to bounce left
	BEQ	bounce_left
	ADD r0, r0, #0x1			;Move the symbol location up otherwise
	STR r0, [r4]				;Store new address
	BL insert_symbol
	BL output_screen
	B update_done
bounce_left
	SUB r0, r0, #0x1			;Move the symbol location left
	STR r0, [r4] 				;Store new address
	BL insert_symbol			;Update board display
	MOV r3, #4
	STR r3, [r4, #8]			;change direction to left
	B bounce_increment	
move_down
	LDR r0, [r4]				;location of symbol
	MOV r1, #0x20
	BL insert_symbol			;clear symbol on board
	LDR r1, [r4, #4]			;load symbol to put back on the board location later
	
	AND r5, r0, #0xF0			;clear lower bits that containt the column location
	CMP r5, #0xF0				;if row is 15 we need to bounce up
	BEQ bounce_up
	ADD r0, r0, #0x10			;Move the symbol location down otherwise
	STR r0, [r4]				;store new location in memory
	BL insert_symbol
	BL output_screen
	B update_done
bounce_up
	SUB r0, r0, #0x10			;Move the symbol location down
	STR r0, [r4] 				;store new address
	BL insert_symbol			;update board display
	MOV r3, #1					
	STR r3, [r4, #8]			;change direction to up
	B bounce_increment
move_left
	LDR r0, [r4]				;location of symbol
	MOV r1, #0x20
	BL insert_symbol			;clear symbol on board
	LDR r1, [r4, #4]			;load symbol to put back on the board location later
	
	AND r5, r0, #0xF			;clear upper bits that contain the row location
	CMP r5, #0x1				;If column is 1 we need to bounce right
	BEQ bounce_right
	SUB r0, r0, #0x1			;Move the symbol location up otherwise
	STR r0, [r4]				;store new address in memory
	BL insert_symbol
	BL output_screen
	B update_done
bounce_right
	ADD r0, r0, #0x1			;Move the symbol location left
	STR r0, [r4] 				;store new address
	BL insert_symbol			;update board display
	MOV r3, #2			
	STR r3, [r4, #8]			;chnage direction to right
	B bounce_increment
bounce_increment
	LDR r4, =0x4000400C
	LDR r0, [r4]
	ADD r0, r0, #1
	STR r0, [r4]
	LDR r4, =score_total
	MOV r1, #100
	BL div_and_mod				;divide by 100 to get 100's place digit
	ADD r0, r0, #0x30
	STRB r0, [r4, #19]			;location of 100's place in counter text
	MOV r0, r1					;move remeinder into r0
	MOV r1, #10					;divide by 10 to get 10's and 1's place
	BL div_and_mod
	ADD r0, r0, #0x30
	ADD r1, r1, #0x30
	STRB r0, [r4, #20]			;location of 10's place in counter text
	STRB r1, [r4, #21]			;location of 1's place in counter text
	BL output_screen			;change to show results of increment
	
update_done
	LDMFD sp!,{lr}
	BX lr
	
pin_connect_block_setup
	STMFD sp!, {r0, r1, r2, lr}
	LDR r0, =0xE002C000  		;PINSEL0
	LDR r1, [r0]
	ORR r1, r1, #5
	BIC r1, r1, #0xA	 		;UART0
;	ORR r1, r1, #0x50
;	BIC r1, r1, #0xA0			;Match Timer 0 and Catch Timer 0
;	ORR r1, r1, #0x500
;	BIC r1, r1, #0xA00			;Match .1 Timer 0 and Catch Timer .1 0

	STR r1, [r0]
	LDMFD sp!, {r0, r1, r2, lr}
	BX lr
	END
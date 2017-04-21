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
	EXTERN illuminate_RGB_LED
	EXTERN illuminateLEDs
	EXTERN display_digit_on_7_seg

intro_screen = "Welcome	to Wee Dig Dug!\r\nUse WASD keys to control movement\r\nPress spacebar to shoot air pump\r\nUser Interrupt Button pauses the game\r\nPress Enter to start: \r\n",0
score_total = "SCORE: 00000      \r\n",0 			;Score
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
		LDR r0, =0x7D0A
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
		LSR r5, r2, #9					;Get direction as lower bits
		CMP r5, #2
		BGE	horizontal_big
vertical_big
		ADD r0, r0, #0x20				;Add 1 to rows LSB
		BL insert_symbol
		SUB r0, r0, #0x40				;Subtract 2 from row, making it 1 less than original row
		BL insert_symbol
		B little_enemies
horizontal_big
		ADD r0, r0, #1					;Add 1 to rows LSB
		BL insert_symbol
		SUB r0, r0, #2					;Subtract 2 from row, making it 1 less than original row
		BL insert_symbol

little_enemies
		LDR r2, [r4], #4
		LDR r3, =0xFFFFFE00				;Clear all but column row
		BIC r0, r2, r3
		MOV r1, #0x78
		BL insert_symbol
		MOV r1, #0x20
		LSR r5, r2, #9					;Get direction as lower bits
		CMP r5, #2
		BGE	horizontal_little
vertical_little
		ADD r0, r0, #0x20				;Add 1 to rows LSB
		BL insert_symbol
		SUB r0, r0, #0x40				;Subtract 2 from row, making it 1 less than original row
		BL insert_symbol
		B game_begin
horizontal_little
		ADD r0, r0, #1				;Add 1 to rows LSB
		BL insert_symbol
		SUB r0, r0, #2				;Subtract 2 from row, making it 1 less than original row
		BL insert_symbol
		
game_begin
		CMP r6, #0
		ADD r6, r6, #1
		BEQ little_enemies				;If we need one more little enenmy, go back and do it again.
		
		MOV r0, #0
		STR r0, [r4], #4				;Store all 0 flags at flag memory address
		STR r0, [r4]					;Store current score of 0
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

		BL output_screen
		;Start the game here
game_loop
		B game_loop				;infinite loop to repeat while game is going on
done
		LDMFD sp!, {r0-r12,lr}
		LDMFD sp!, {lr}
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
		LDR r1, =0xE000C000		
		LDRB r0, [r1]			;clears all characters waiting in UART0 before we enable interupts
		LDR r0, =0xE000C004
		LDR r1, [r0]
		ORR r1, r1, #1				;RDA enabled with 1
		STR r1, [r0]
		MOV r0, #0x67			;'g'
		BL illuminate_RGB_LED
		LDR r4, =score_total
		ADD r4, r4, #13			;Location of PAUSE text
		MOV r5, #0x20
		STRB r5, [r4], #1
		STRB r5, [r4], #1
		STRB r5, [r4], #1
		STRB r5, [r4], #1
		STRB r5, [r4], #1
		;Remove PAUSE from score line
		ORR r1, r1, #1			;turn timer 0 on if off
		ORR r3, r3, #1			;turn timer 1 on if off
		B toggle_finish
toggle_off
		LDR r0, =0xE000C004
		LDR r1, [r0]
		BIC r1, r1, #1				;RDA disabled with 0
		STR r1, [r0]
		MOV r0, #0x62			;'b'
		BL illuminate_RGB_LED
		ldr r4, =score_total
		ADD r4, r4, #13
		MOV r5, #0x50
		STRB r5, [r4], #1
		MOV r5, #0x41
		STRB r5, [r4], #1
		MOV r5, #0x55
		STRB r5, [r4], #1
		MOV r5, #0x53
		STRB r5, [r4], #1
		MOV r5, #0x45
		STRB r5, [r4], #1  		;ADD pause to score line
		BIC r1, r1, #1			;otherwise turn timer 0 off
		BIC r3, r3, #1			;otherwise turn timer 1 off
toggle_finish
		LDR r0, =0xE0004004
		LDR r2, =0xE0004008
		STR r1, [r0]
		STR r3, [r2]

		BL output_screen
		
		LDR r0, =0xE01FC140
		LDR r1, [r0]
		ORR r1, r1, #2		; Clear Interrupt
		STR r1, [r0]
		B FIQ_Exit

TIMER0	LDR r0, =0xE0004000
		LDR r1, [r0]
		TST r1, #2
		BEQ TIMER1
		LDR r4, =0x40004010	;Flag address
		LDR r1, [r4]
		AND r0, r1, #1
		CMP r0, #1
		BLEQ update_player
		;random chance of enemies changing direction
		
		BL update_big_enemy

		BL update_small_enemy
		BL update_small_enemy2

		
		
timer_clear
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
		LSL r1, r0, #9			;Move new direction/character to upper portion of register
		LDR r0, [r4]
		LDR r2, =0x7FE00			
		BIC r0, r0, r2			;Clear the current direction
		ORR r0, r0, r1			;Add new direction to character
		STR r0, [r4]			;store new direction from input into memory
		LDR r4, =0x40004010		;Set movement flag somewhere in memory, so on next clock update we can move the character.
		LDR r0, [r4]
		ORR r0, r0, #1
		STR r0, [r4]
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
	STMFD sp!, {r0,r2-r4,lr}			;r0 column and row lower 5 bits is column, upper 4 bits is row, r1 is symbol
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

	LDMFD sp!, {r0,r2-r4,lr}
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
	
monster_rng
	STMFD sp!, {r0-r4,lr}
	LDR r4, =0x40004004
monster_rng_loop
	MOV r1, #3
	BL rng
	LDR r2, [r4], #4
	MOV r3, r2, LSR #9		;extract current direction
	CMP r0, #1
	LDR r1, =0x1FF			;Used to extract current location
	BGT mons_rng_end
	CMP r3, #2
	BLT horizontal_change
vertical_change
	AND r0, r2, r1
	ADD r0, r0, #0x20
	BL get_symbol
	CMP r1, #0x23
	MOVNE r3, #1
	BNE mons_rng_end
	CMP r1, #0x5A
	MOVNE r3, #1
	BNE mons_rng_end
	SUB r0, r0, #0x40
	BL get_symbol
	CMP r1, #0x23
	MOVNE r3, #0
	BNE mons_rng_end
	CMP r1, #0x5A
	MOVNE r3, #0
	
	B mons_rng_end
horizontal_change
	AND r0, r2, r1
	ADD r0, r0, #1
	BL get_symbol
	CMP r1, #0x23
	MOVNE r3, #2
	BNE mons_rng_end
	CMP r1, #0x5A
	MOVNE r3, #2
	BNE mons_rng_end
	SUB r0, r0, #2
	BL get_symbol
	CMP r1, #0x23
	MOVNE r3, #3
	BNE mons_rng_end
	CMP r1, #0x5A
	MOVNE r3, #3
mons_rng_end
	ADD r0, r0, r3, LSL #9	;add the shifted new direction to monster location
	STR r0, [r4,-4]			;store back new monster information
	AND r3, r4, #0xC		;If we havent checked all three monsters, go back and do more rng for path finding
	BLE monster_rng_loop
	
	LDMFD sp!, {r0-r4,lr}
	BX lr
	
update_big_enemy
	STMFD sp!, {lr}
	LDR r4,= 0x40004004	;location of the big enemy		;0 up, 2 right, 1 down, 3 left.
	LDR r1, [r4]
	LSR r1, r1, #9		;Put direction as LSBs
	CMP r1, #0
	BEQ mov_up
	CMP r1, #2
	BEQ mov_right
	CMP r1, #1
	BEQ mov_down
	CMP r1, #3
	BEQ mov_left
update_player
	STMFD sp!, {lr}
	LDR r4, =0x40004010
	LDR r1, [r4]
	BIC r1, r1, #1
	STR r1, [r4]
	LDR r4, =0x40004000	;location of the player
	LDR r1, [r4]
	LSR r1, r1, #9
	CMP r1, #0x5E
	BEQ player_mov_up
	CMP r1, #0x3E
	BEQ player_mov_right
	CMP r1, #0x76
	BEQ player_mov_down
	CMP r1, #0x3C
	BEQ player_mov_left	
update_small_enemy	
	STMFD sp!, {lr}
	LDR r4, =0x40004008	;location of the small enemy		;0 up, 2 right, 1 down, 3 left.
	LDR r1, [r4]
	LSR r1, r1, #9
	CMP r1, #0
	BEQ mov_up
	CMP r1, #2
	BEQ mov_right
	CMP r1, #1
	BEQ mov_down
	CMP r1, #3
	BEQ mov_left
update_small_enemy2	
	STMFD sp!, {lr}
	LDR r4, =0x4000400C	;location of the small enemy		;0 up, 2 right, 1 down, 3 left.
	LDR r1, [r4]
	LSR r1, r1, #9
	CMP r1, #0
	BEQ mov_up
	CMP r1, #2
	BEQ mov_right
	CMP r1, #1
	BEQ mov_down
	CMP r1, #3
	BEQ mov_left
	
	
	
player_mov_up
	LDR r0, [r4]				;location of player
	LDR r1, =0xFFFFFE00
	BIC r0, r0, r1
	SUB r0, r0, #0x20			;check the next location were moving to for walls or dirt
	BL get_symbol				;returns in r1 the ascii of the symbol
	CMP r1, #0x5A				;Collide with wall
	BEQ update_player_done				;currently turn down only moves the enemy down and changes direction but randomization can be added easily
	CMP r1, #0x23				;this is to check if we should add score when moving
	MOVEQ r2, #10
	BLEQ increment_score
	CMP r1, #0x42				;VERY IMPORTANT,need multiple compares for each enemy symbol, easier then checking all three locaitons
	BEQ player_death
	CMP r1, #0x78
	BEQ player_death

	AND r5, r0, #0x1E0			;Clear lower bits which are columns location
	CMP r5, #0x40				;If row is 2, we dont want to go into that space
	BEQ update_player_done
	MOV r5, r0					;Store new location temporarily
	LDR r0, [r4]
	LSR r2, r0, #9				;Store symbol temporarily in r2
	LDR r1, =0xFFFFFE00
	BIC r0, r0, r1
	MOV r1, #0x20
	BL insert_symbol
	LSL r2, r2, #9
	ADD r2, r2, r5				;New player information
	STR r2, [r4]
	
	B update_player_done

player_mov_down
	LDR r0, [r4]				;location of player
	LDR r1, =0xFFFFFE00
	BIC r0, r0, r1
	ADD r0, r0, #0x20			;check the next location were moving to for walls or dirt
	BL get_symbol				;returns in r1 the ascii of the symbol
	CMP r1, #0x5A				;Collide with wall
	BEQ update_player_done		;
	CMP r1, #0x23				;this is to check if we should add score when moving
	MOVEQ r2, #10
	BLEQ increment_score
	CMP r1, #0x42				;VERY IMPORTANT,need multiple compares for each enemy symbol, easier then checking all three locaitons
	BEQ player_death
	CMP r2, #0x78
	BEQ player_death

	MOV r5, r0					;Store new location temporarily
	LDR r0, [r4]
	LSR r2, r0, #9				;Store symbol temporarily in r2
	LDR r1, =0xFFFFFE00
	BIC r0, r0, r1
	MOV r1, #0x20
	BL insert_symbol
	LSL r2, r2, #9
	ADD r2, r2, r5				;New player information
	STR r2, [r4]
	
	B update_player_done

player_mov_left
	LDR r0, [r4]				;location of player
	LDR r1, =0xFFFFFE00
	BIC r0, r0, r1
	SUB r0, r0, #1				;check the next location were moving to for walls or dirt
	BL get_symbol				;returns in r1 the ascii of the symbol
	CMP r1, #0x5A				;Collide with wall
	BEQ update_player_done				;currently turn down only moves the enemy down and changes direction but randomization can be added easily
	CMP r1, #0x23				;this is to check if we should add score when moving
	MOVEQ r2, #10
	BLEQ increment_score
	CMP r1, #0x42				;VERY IMPORTANT,need multiple compares for each enemy symbol, easier then checking all three locaitons
	BEQ player_death
	CMP r2, #0x78
	BEQ player_death

	MOV r5, r0					;Store new location temporarily
	LDR r0, [r4]
	LSR r2, r0, #9				;Store symbol temporarily in r2
	LDR r1, =0xFFFFFE00
	BIC r0, r0, r1
	MOV r1, #0x20
	BL insert_symbol
	LSL r2, r2, #9
	ADD r2, r2, r5				;New player information
	STR r2, [r4]
	
	B update_player_done

player_mov_right
	LDR r0, [r4]				;location of player
	LDR r1, =0xFFFFFE00
	BIC r0, r0, r1
	ADD r0, r0, #1				;check the next location were moving to for walls or dirt
	BL get_symbol				;returns in r1 the ascii of the symbol
	CMP r1, #0x5A				;Collide with wall
	BEQ update_player_done				;currently turn down only moves the enemy down and changes direction but randomization can be added easily
	CMP r1, #0x23				;this is to check if we should add score when moving
	MOVEQ r2, #10
	BLEQ increment_score
	CMP r1, #0x42				;VERY IMPORTANT,need multiple compares for each enemy symbol, easier then checking all three locaitons
	BEQ player_death
	CMP r2, #0x78
	BEQ player_death

	MOV r5, r0					;Store new location temporarily
	LDR r0, [r4]
	LSR r2, r0, #9				;Store symbol temporarily in r2
	LDR r1, =0xFFFFFE00
	BIC r0, r0, r1
	MOV r1, #0x20
	BL insert_symbol
	LSL r2, r2, #9
	ADD r2, r2, r5				;New player information
	STR r2, [r4]
	
	B update_player_done

update_player_done
	LDR r0, [r4]
	LSR r2, r0, #9
	LDR r1, =0xFFFFFE00
	BIC r0, r0, r1
	MOV r1, r2
	BL insert_symbol
	LDMFD sp!, {lr}
	BX lr
	
mov_up
	LDR r0, [r4]				;location of symbol
	LDR r1, =0xFFFFFE00
	BIC r0, r0, r1				;clear direction bits
	LDR r2, =0x40004000
overlap_up	
	LDR r3, =0x40004010
	CMP r2, r3
	BEQ delete_up 
	CMP r2, r4
	ADDEQ r2, r2, #4
	BEQ	overlap_up
	LDR r5, [r2]
	BIC r5, r5, r1
	CMP r0, r5
	BEQ	skip_up
	ADD r2, r2, #4
	B overlap_up

delete_up
	MOV r1, #0x20
	BL insert_symbol			;clear symbol on board
skip_up
	SUB r0, r0, #0x20			;check the next location were moving to for walls or dirt
	BL get_symbol				;returns in r1 the ascii of the symbol
	CMP r1, #0x23
	BEQ mov_down				;currently turn down only moves the enemy down and changes direction but randomization can be added easily
	CMP r1, #0x5A				;this is likely useless because of the restriction on moving into the air but may fix some bugs
	BEQ mov_down
	LDR r6, =0x40004000			
	LDR r2, [r6]
	LDR r1, =0xFFFFFE00
	BIC r2, r2, r1				;clear direction bits
	CMP r0, r2					;ASCII for player	;VERY IMPORTANT, if enemy runs into player we need to break out into a routine to handle player death, need multiple compares for each player symbol or maybe just compare locations?
	BEQ player_death
	

	AND r5, r0, #0x1E0			;Clear lower bits which are columns location
	CMP r5, #0x40				;If row is 3, we need to bounce down
	BEQ mov_down
up_or_down
	ADD r0, r0, #0x20			;returns r0 to original location
	SUB r0, r0, #0x20			;Move the symbol location up
	MOV r2, #0x0000				;Direction is still up
	LDR r5, =0x40004004
	CMP r4, r5					;If this address for monster, it is the big monster. Otherwise small monster
	MOVEQ r1, #0x42
	MOVNE r1, #0x78
	BL insert_symbol
	ADD r0, r0, r2				;Add direction to upper portion of register
	STR r0, [r4]
	B update_done 

mov_down
	LDR r0, [r4]				;location of symbol
	LDR r1, =0xFFFFFE00
	BIC r0, r0, r1				;clear direction bits
	LDR r2, =0x40004000
overlap_down	
	LDR r3, =0x40004010
	CMP r2, r3
	BEQ delete_down 
	CMP r2, r4
	ADDEQ r2, r2, #4
	BEQ	overlap_down
	LDR r5, [r2]
	BIC r5, r5, r1
	CMP r0, r5
	BEQ	skip_down
	ADD r2, r2, #4
	B overlap_down

delete_down
	MOV r1, #0x20
	BL insert_symbol			;clear symbol on board
skip_down	
	ADD r0, r0, #0x20			;check the next location were moving to for walls or dirt
	BL get_symbol				;returns in r1 the ascii of the symbol
	CMP r1, #0x23
	BEQ mov_up					;currently turn down only moves the enemy down and changes direction but randomization can be added easily
	CMP r1, #0x5A				;this is likely useless because of the restriction on moving into the air but may fix some bugs
	BEQ mov_up
	LDR r6, =0x40004000			
	LDR r2, [r6]
	LDR r1, =0xFFFFFE00
	BIC r2, r2, r1				;clear direction bits
	CMP r0, r2					;ASCII for player	;VERY IMPORTANT, if enemy runs into player we need to break out into a routine to handle player death, need multiple compares for each player symbol or maybe just compare locations?
	BEQ player_death
	
down_or_up
	SUB r0, r0, #0x20			;returns r0 to original location
	ADD r0, r0, #0x20			;Move the symbol location down 
	MOV r2, #0x0200				;Direction is still down
	LDR r5, =0x40004004
	CMP r4, r5					;If this address for monster, it is the big monster. Otherwise small monster
	MOVEQ r1, #0x42
	MOVNE r1, #0x78
	BL insert_symbol
	ADD r0, r0, r2				;Add direction to upper portion of register
	STR r0, [r4]
	B update_done

mov_left
	LDR r0, [r4]				;location of symbol
	LDR r1, =0xFFFFFE00
	BIC r0, r0, r1				;clear direction bits	
	LDR r2, =0x40004000
overlap_left	
	LDR r3, =0x40004010
	CMP r2, r3
	BEQ delete_left 
	CMP r2, r4
	ADDEQ r2, r2, #4
	BEQ	overlap_left
	LDR r5, [r2]
	BIC r5, r5, r1
	CMP r0, r5
	BEQ	skip_left
	ADD r2, r2, #4
	B overlap_left

delete_left		
	MOV r1, #0x20
	BL insert_symbol			;clear symbol on board
skip_left	
	SUB r0, r0, #1				;check the next location were moving to for walls or dirt
	BL get_symbol				;returns in r1 the ascii of the symbol
	CMP r1, #0x23
	BEQ mov_right				;currently turn down only moves the enemy down and changes direction but randomization can be added easily
	CMP r1, #0x5A				;this is likely useless because of the restriction on moving into the air but may fix some bugs
	BEQ mov_right
	LDR r6, =0x40004000			
	LDR r2, [r6]
	LDR r1, =0xFFFFFE00
	BIC r2, r2, r1				;clear direction bits
	CMP r0, r2					;ASCII for player	;VERY IMPORTANT, if enemy runs into player we need to break out into a routine to handle player death, need multiple compares for each player symbol or maybe just compare locations?
	BEQ player_death
	
left_or_right
	ADD r0, r0, #1				;returns r0 to original location
	SUB r0, r0, #1				;Move the symbol location left 
	MOV r2, #0x0600				;Direction is still left
	LDR r5, =0x40004004
	CMP r4, r5					;If this address for monster, it is the big monster. Otherwise small monster
	MOVEQ r1, #0x42
	MOVNE r1, #0x78
	BL insert_symbol
	ADD r0, r0, r2				;Add direction to upper portion of register
	STR r0, [r4]
	B update_done

mov_right
	LDR r0, [r4]				;location of symbol
	LDR r1, =0xFFFFFE00
	BIC r0, r0, r1				;clear direction bits
	LDR r2, =0x40004000
overlap_right	
	LDR r3, =0x40004010
	CMP r2, r3
	BEQ delete_right 
	CMP r2, r4
	ADDEQ r2, r2, #4
	BEQ	overlap_right
	LDR r5, [r2]
	BIC r5, r5, r1
	CMP r0, r5
	BEQ	skip_right
	ADD r2, r2, #4
	B overlap_right
	
delete_right	
	MOV r1, #0x20
	BL insert_symbol			;clear symbol on board
skip_right
	ADD r0, r0, #1				;check the next location were moving to for walls or dirt
	BL get_symbol				;returns in r1 the ascii of the symbol
	CMP r1, #0x23
	BEQ mov_left				;currently turn down only moves the enemy down and changes direction but randomization can be added easily
	CMP r1, #0x5A				;this is likely useless because of the restriction on moving into the air but may fix some bugs
	BEQ mov_left
	LDR r6, =0x40004000			
	LDR r2, [r6]
	LDR r1, =0xFFFFFE00
	BIC r2, r2, r1				;clear direction bits
	CMP r0, r2					;ASCII for player	;VERY IMPORTANT, if enemy runs into player we need to break out into a routine to handle player death, need multiple compares for each player symbol or maybe just compare locations?
	BEQ player_death
	
right_or_left
	SUB r0, r0, #1				;returns r0 to original location
	ADD r0, r0, #1				;Move the symbol location right otherwise
	MOV r2, #0x0400				;Direction is still right
	LDR r5, =0x40004004
	CMP r4, r5					;If this address for monster, it is the big monster. Otherwise small monster
	MOVEQ r1, #0x42
	MOVNE r1, #0x78
	BL insert_symbol
	ADD r0, r0, r2				;Add direction to upper portion of register
	STR r0, [r4]
	B update_done

update_done
	LDMFD sp!, {lr}
	BX lr

get_symbol
	STMFD sp!, {r0,r2-r4,lr}			;r0 column and row lower 5 bits is column, upper 4 bits is row, r1 is symbol
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
	LDRB r1, [r4, r3]		;Store the ascii in memory

	LDMFD sp!, {r0,r2-r4,lr}
	BX lr

player_death
	LDR r4, =0x40004000
	LDR r0, [r4]
	LDR r1, =0x1FF
	AND r0, r0, r1
	MOV r1, #0x20
	BL insert_symbol
	LDR r0, =0x7D0A
	STR r0, [r4]
	LSR	r1, r0, #9
	BL insert_symbol

	LDR r4, =0xE0028010
	LDR r0, [r4]
	MOV r2, #-1
	MOV r1, #0
	EOR r0, r0, r2					;flip all bits
	MOV r0, r0, LSR #16				;Right shift to get pin 20's value as LSB
   	AND r2, r0, #1
	ADD r1, r1, r2
	LSR r0, r0, #1
	AND r2, r0, #1
	ADD r1, r1, r2
	LSR r0, r0, #1
	AND r2, r0, #1
	ADD r1, r1, r2
	LSR r0, r0, #1
	AND r2, r0, #1
	ADD r1, r1, r2					;Get # of leds currently on
	CMP r1, #4
	MOVEQ r0, #7
	CMP r1, #3
	MOVEQ r0, #3
	CMP r1, #2
	MOVEQ r0, #1
	CMP r1, #1
	MOVEQ r0, #0

	BL illuminateLEDs
	CMP r1, #1
	LDMFD sp!, {lr}
	BEQ game_over
	B timer_clear

game_over
	B done	
	
increment_score
	STMFD sp!, {r0-r2,r4,lr}
	LDR r4, =0x40004014		;score location
	LDR r0, [r4]
	ADD r0, r0, r2
	STR r0, [r4]
	MOV r2, #0
	LDR r4, =score_total
	ADD r4, r4, #11
score_loop
	MOV r1, #10
	BL div_and_mod
	ADD r1, r1, #0x30
	STRB r1, [r4,-r2]
	ADD r2, r2, #1
	CMP r2, #5
	BLE score_loop
	
	LDMFD sp!, {r0-r2,r4,lr}
	BX lr
	
pin_connect_block_setup
	STMFD sp!, {r0, r1, r2, lr}
	LDR r0, =0xE002C000  		;PINSEL0
	LDR r1, [r0]
	ORR r1, r1, #5
	BIC r1, r1, #0xA	 		;UART0
	LDR r2, =0x0FFFC000	 ;sets 00 for pins p0.7-p0.13
	BIC r1, r1, r2
	STR r1, [r0]
	LDR r0, =0xE002C004	 ;PINSEL1
	LDR r1, [r0]
	LDR r2, =0x00000C3C	;sets 00 for pins p0.17, p0.18, and p0.21
	BIC r1, r1, r2
;	ORR r1, r1, #0x50
;	BIC r1, r1, #0xA0			;Match Timer 0 and Catch Timer 0
;	ORR r1, r1, #0x500
;	BIC r1, r1, #0xA00			;Match .1 Timer 0 and Catch Timer .1 0

	STR r1, [r0]
	LDR r4, =0xE0028008				;base address of IO0DIR	ie the direction register for port 0
	LDR r1, [r4]					;load the content that is currently there
	LDR r0, =0x00263F80				;load hex of bits that we want to make 1's here, for pins 7-13 and 17, 18, 21
	ORR r1, r1, r0					;Or in the bits we want to be 1 for setting those pins to outputs
	STR r1, [r4]					;store the result back into the direction register
	LDR r4, =0xE0028018				;base address of IO1DIR ie the direction register for port 1
	LDR r1, [r4]					;load the content that is currently there
	LDR r0, =0x000F0000				;load hex of bits that we want to make 1's here, for pins 16-19
	ORR r1, r1, r0					;or in the bits we want to be 1 for setting those pins to outputs
	LDR r0, =0x00F00000				;"  "
	BIC r1, r1, r0
	STR r1, [r4]					;"  "
	LDMFD sp!, {r0, r1, r2, lr}
	BX lr
	END
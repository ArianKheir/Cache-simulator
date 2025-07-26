.data
.align 2
inputarray: .byte 8, 5, 6, 6, 6, 6, 2, 7
.align 2
hitmissL1: .byte  0, 0, 0, 0, 0, 0, 0, 0
.align 2
hitmissL2: .byte  0, 0, 0, 0, 0, 0, 0, 0
.align 2
cacheL1:  .fill 4, 1, 0xFF
.align 2
cacheL2:  .fill 4, 1, 0xFF
.align 2
mode: .byte 1 @1 for 2-way set associative and 0 for direct mapped cache
.align 2
countL1: .fill 256, 1, 0
.align 2
countL2: .fill 256, 1, 0
.align 2
rand_seed: .byte 0x42
.align 2
rand_a: .byte 13
.align 2
rand_c: .byte 17
.align 2
.text
.global _start
_start:
	LDR R0, =cacheL1
	LDR R0, =cacheL2
	LDR R0, =inputarray @R0 = inputarray
	MOV R1, #1 @R1 = policy for L1 = 0 FIFO, 1 LRU, 2 MRU, 3 LFU, 4 MFU, 5 random *only in 2WSA
	MOV R2, #1 @R2 = policy for L2 = 0 FIFO, 1 LRU, 2 MRU, 3 LFU, 4 MFU, 5 random *only in 2WSA
	MOV R3, #8 @R3 = sizeof input addrs
	MOV R4, #0 @R4 = i (for traversing the input array)
	LDR R5, =mode
	LDRB R5, [R5] @R5= 1 for 2WSA, 0 for DMC
	MOV R6, #4 @size of L1
	MOV R7, #4 @size of L2
	LOOP:
		CMP R4, R3
		BGE end
		@search in L1
		PUSH {R0, R1}
		LDRB R0, [R0, R4] @find the place to search in cache
		MOV R1, R6
		BL mod_func
		MOV R8, R0 @R8 = mod answer (the memory % size of cache = the block(=1byte) in cache L1)
		POP {R0, R1}
		LDR R11, =mode
		LDRB R11, [R11]
		CMP R11, #1
		BEQ two_WSA
		@DMC:
		LDR R9, =cacheL1
		LDRB R9, [R9, R8] @R9 = the value in Cache L1 in the wanted block
		LDRB R10, [R0, R4] @R10 = the value we want
		CMP R9, R10
		BEQ hit_end_of_L1search
		BL missL1
		LDR R9, =cacheL1
		STRB R10, [R9, R8] @update the cache L1 with new value
		@search in L2
		PUSH {R0, R1}
		LDRB R0, [R0, R4] @find the place to search in cache
		MOV R1, R7
		BL mod_func
		MOV R8, R0 @R8 = mod answer (the memory % size of cache = the block(=1byte) in cache L2)
		POP {R0, R1}
		LDR R9, =cacheL2
		LDRB R9, [R9, R8]
		CMP R9, R10
		BEQ hit_end_of_L2search
		BL missL2
		LDR R9, =cacheL2
		STRB R10, [R9, R8] @update the cache L2 with new value
		B next_LOOP
		two_WSA:
			@search in L1
			LDR R9, =cacheL1
			LDRB R9, [R9, R8] @R9 = the value in Cache L1 in the wanted block
			LDRB R10, [R0, R4] @R10 = the value we want
			CMP R9, R10
			BEQ hit1_end_of_L1search
			LDR R9, =cacheL1
			LSR R5, R6, #1 
			ADD R9, R9, R5 @the second block with same block number in cache
			LDRB R9, [R9, R8] @R9 = the value in Cache L1 in the wanted block
			CMP R9, R10
			BEQ hit2_end_of_L1search
			BL missL1
			BL replacementL1
			@search in L2
			PUSH {R0, R1}
			LDRB R0, [R0, R4] @find the place to search in cache
			MOV R1, R7
			BL mod_func
			MOV R8, R0 @R8 = mod answer (the memory % size of cache = the block(=1byte) in cache L2)
			POP {R0, R1}
			LDR R9, =cacheL2
			LDRB R9, [R9, R8] @R9 = the value in Cache L2 in the wanted block
			LDRB R10, [R0, R4] @R10 = the value we want
			CMP R9, R10
			BEQ hit1_end_of_L2search
			LDR R9, =cacheL2
			LSR R5, R7, #1
			ADD R9, R9, R5 @the second block with same block number in cache
			LDRB R9, [R9, R8] @R9 = the value in Cache L2 in the wanted block
			CMP R9, R10
			BEQ hit2_end_of_L2search
			BL missL2
			BL replacementL2
			B next_LOOP
		hit_end_of_L1search:
			BL hitL1
			B next_LOOP
		hit_end_of_L2search:
			BL hitL2
			B next_LOOP
		hit1_end_of_L2search:
			BL hitL2
			CMP R2, #2
			BLEQ swapL2
			B next_LOOP
		hit2_end_of_L2search:
			BL hitL2
			CMP R2, #1
			BLEQ swapL2
			B next_LOOP
		hit1_end_of_L1search:
			BL hitL1
			CMP R1, #2
			BLEQ swapL1
			B next_LOOP
		hit2_end_of_L1search:
			BL hitL1
			CMP R1, #1
			BLEQ swapL1
			B next_LOOP
		next_LOOP:
			ADD R4, R4, #1
			B LOOP
end:
	B end
replacementL1:
	PUSH {LR, R9, R5}
	LDR R9, =cacheL1
	LDRB R9, [R9, R8]
	CMP R9, #0xFF
	BNE check_nextL1
	LDR R9, =cacheL1
	STRB R10, [R9, R8]
	LDR R9, =countL1
	LDRB R5, [R9, R10]
	ADD R5, R5, #1
	STRB R5, [R9, R10]
	B end_replacementL1
	check_nextL1:
		LDR R9, =cacheL1
		LSR R5, R6, #1
		ADD R9, R9, R5
		LDRB R9, [R9, R8]
		CMP R9, #0xFF
		BNE check_policyL1
		LDR R9, =cacheL1
		LSR R5, R6, #1
		ADD R9, R9, R5
		STRB R10, [R9, R8]
		LDR R9, =countL1
		LDRB R5, [R9, R10]
		ADD R5, R5, #1
		STRB R5, [R9, R10]
		B end_replacementL1
	check_policyL1:
	  CMP R1, #0
	  BEQ FIFOL1
	  CMP R1, #1
	  BEQ LRUL1
	  CMP R1, #2
	  BEQ MRUL1
	  CMP R1, #3
	  BEQ LFUL1
	  CMP R1, #4
	  BEQ MFUL1
	  CMP R1, #5
	  BEQ RANDL1
FIFOL1:
	PUSH {R9}
	LDR R9, =cacheL1
	STRB R10, [R9, R8]
	BL swapL1
	POP {R9}
	B end_replacementL1
LRUL1:
	PUSH {R9, R11, R5}
	LDR R9, =cacheL1
	LDRB R11, [R9, R8]
	STRB R10, [R9, R8]
	LDR R9, =cacheL1
	LSR R5, R6, #1
	ADD R9, R9, R5
	STRB R11, [R9, R8]
	POP {R9, R11, R5}
	B end_replacementL1
MRUL1:
	PUSH {R9, R5}
	LDR R9, =cacheL1
	LSR R5, R6, #1
	ADD R9, R9, R5
	STRB R10, [R9, R8]
	POP {R9, R5}
	B end_replacementL1
LFUL1:
	PUSH {R0, R1, R9, R5}
	LDR R9, =cacheL1
	LDRB R0, [R9, R8]
	LDR R9, =cacheL1
	LSR R5, R6, #1
	ADD R9, R9, R5
	LDRB R1, [R9, R8]
	LDR R9, =countL1
	LDRB R0, [R9, R0]
	LDRB R1, [R9, R1]
	CMP R0, R1
	BGE secondLFUL1
	LDR R9, =cacheL1
	STRB R10, [R9, R8]
	B end_LFUL1
secondLFUL1:
	LDR R9, =cacheL1
	LSR R5, R6, #1
	ADD R9, R9, R5 
	STRB R10, [R9, R8]
	B end_LFUL1
end_LFUL1:
	LDR R9, =countL1
	LDRB R0, [R9, R10]
	ADD R0, R0, #1
	STRB R0, [R9, R10]
	POP {R0, R1, R9, R5}
	B end_replacementL1
MFUL1:
	PUSH {R0, R1, R9, R5}
	LDR R9, =cacheL1
	LDRB R0, [R9, R8]
	LDR R9, =cacheL1
	LSR R5, R6, #1
	ADD R9, R9, R5
	LDRB R1, [R9, R8]
	LDR R9, =countL1
	LDRB R0, [R9, R0]
	LDRB R1, [R9, R1]
	CMP R0, R1
	BLE secondMFUL1
	LDR R9, =cacheL1
	STRB R10, [R9, R8]
	B end_MFUL1
secondMFUL1:
	LDR R9, =cacheL1
	LSR R5, R6, #1
	ADD R9, R9, R5 
	STRB R10, [R9, R8]
	B end_MFUL1
end_MFUL1:
	LDR R9, =countL1
	LDRB R0, [R9, R10]
	ADD R0, R0, #1
	STRB R0, [R9, R10]
	POP {R0, R1, R9, R5}
	B end_replacementL1
RANDL1:
	PUSH {R0-R3, R9, R5, LR}
	BL get_random
	MOV R1, #2 @for 2wsa
	BL mod_func
	CMP R0, #1
	BEQ secondRandL1
	LDR R9, =cacheL1
	STRB R10, [R9, R8]
	B end_RANDL1
secondRandL1:
	LDR R9, =cacheL1
	LSR R5, R6, #1
	ADD R9, R9, R5
	STRB R10, [R9, R8]
	B end_RANDL1
end_RANDL1:
	POP {R0-R3, R9, R5, LR}
	B end_replacementL1
end_replacementL1:
  POP {LR, R9, R5}
  BX LR	
  
replacementL2:
	PUSH {LR, R9, R5}
	LDR R9, =cacheL2
	LDRB R9, [R9, R8]
	CMP R9, #0xFF
	BNE check_nextL2
	LDR R9, =cacheL2
	STRB R10, [R9, R8]
	LDR R9, =countL2
	LDRB R5, [R9, R10]
	ADD R5, R5, #1
	STRB R5, [R9, R10]
	B end_replacementL2
	check_nextL2:
		LDR R9, =cacheL2
		LSR R5, R7, #1
		ADD R9, R9, R5
		LDRB R9, [R9, R8]
		CMP R9, #0xFF
		BNE check_policyL2
		STRB R10, [R9, R8]
		LDR R9, =countL2
		LDRB R5, [R9, R10]
		ADD R5, R5, #1
		STRB R5, [R9, R10]
		B end_replacementL2
	check_policyL2:
	  CMP R2, #0
	  BEQ FIFOL2
	  CMP R2, #1
	  BEQ LRUL2
	  CMP R2, #2
	  BEQ MRUL2
	  CMP R2, #3
	  BEQ LFUL2
	  CMP R2, #4
	  BEQ MFUL2
	  CMP R2, #5
	  BEQ RANDL2
FIFOL2:
	PUSH {R9}
	LDR R9, =cacheL2
	LDRB R10, [R9, R8]
	BL swapL2
	POP {R9}
	B end_replacementL2
LRUL2:
	PUSH {R9, R11, R5}
	LDR R9, =cacheL2
	LDRB R11, [R9, R8]
	STRB R10, [R9, R8]
	LDR R9, =cacheL2
	LSR R5, R7, #1
	ADD R9, R9, R5
	STRB R11, [R9, R8]
	POP {R9, R11, R5}
	B end_replacementL2
MRUL2:
	PUSH {R9, R5}
	LDR R9, =cacheL2
	LSR R5, R7, #1
	ADD R9, R9, R5
	STRB R10, [R9, R8]
	POP {R9, R5}
	B end_replacementL2
LFUL2:
	PUSH {R0, R1, R9, R5}
	LDR R9, =cacheL2
	LDRB R0, [R9, R8]
	LDR R9, =cacheL2
	LSR R5, R7, #1
	ADD R9, R9, R5
	LDRB R1, [R9, R8]
	LDR R9, =countL2
	LDRB R0, [R9, R0]
	LDRB R1, [R9, R1]
	CMP R0, R1
	BGE secondLFUL2
	LDR R9, =cacheL2
	STRB R10, [R9, R8]
	B end_LFUL2
secondLFUL2:
	LDR R9, =cacheL2
	LSR R5, R7, #1
	ADD R9, R9, R5 
	STRB R10, [R9, R8]
	B end_LFUL2
end_LFUL2:
	LDR R9, =countL2
	LDRB R0, [R9, R10]
	ADD R0, R0, #1
	STRB R0, [R9, R10]
	POP {R0, R1, R9, R5}
	B end_replacementL2
MFUL2:
	PUSH {R0, R1, R9, R5}
	LDR R9, =cacheL2
	LDRB R0, [R9, R8]
	LDR R9, =cacheL2
	LSR R5, R7, #1
	ADD R9, R9, R5
	LDRB R1, [R9, R8]
	LDR R9, =countL2
	LDRB R0, [R9, R0]
	LDRB R1, [R9, R1]
	CMP R0, R1
	BLE secondMFUL2
	LDR R9, =cacheL2
	STRB R10, [R9, R8]
	B end_MFUL2
secondMFUL2:
	LDR R9, =cacheL2
	LSR R5, R7, #1
	ADD R9, R9, R5 
	STRB R10, [R9, R8]
	B end_MFUL2
end_MFUL2:
	LDR R9, =countL2
	LDRB R0, [R9, R10]
	ADD R0, R0, #1
	STRB R0, [R9, R10]
	POP {R0, R1, R9, R5}
	B end_replacementL2
RANDL2:
	PUSH {R0-R3, R9, R5, LR}
	BL get_random
	MOV R1, #2 @for 2wsa
	BL mod_func
	CMP R0, #1
	BEQ secondRandL2
	LDR R9, =cacheL2
	STRB R10, [R9, R8]
	B end_RANDL2
secondRandL2:
	LDR R9, =cacheL2
	LSR R5, R7, #1
	ADD R9, R9, R5
	STRB R10, [R9, R8]
	B end_RANDL2
end_RANDL2:
	POP {R0-R3, R9, R5, LR}
	B end_replacementL2
end_replacementL2:
  POP {LR, R9, R5}
  BX LR
  
missL1:
  PUSH {R7, R8, LR}
  MOV R7, #0
  LDR R8, =hitmissL1
  STRB R7, [R8, R4]
  POP {R7, R8, LR}
  BX LR
hitL1:
  PUSH {R7, R8, LR}
  MOV R7, #1
  LDR R8, =hitmissL1
  STRB R7, [R8, R4]
  LDR R8, =countL1
  LDRB R7, [R8, R10]
  ADD R7, R7, #1
  STRB R7, [R8, R10]
  POP {R7, R8, LR}
  BX LR
missL2:
  PUSH {R7, R8, LR}
  MOV R7, #0
  LDR R8, =hitmissL2
  STRB R7, [R8, R4]
  POP {R7, R8, LR}
  BX LR
hitL2:
  PUSH {R7, R8, LR}
  MOV R7, #1
  LDR R8, =hitmissL2
  STRB R7, [R8, R4]
  LDR R8, =countL2
  LDRB R7, [R8, R10]
  ADD R7, R7, #1
  STRB R7, [R8, R10]  
  POP {R7, R8, LR}
  BX LR
mod_func:
	PUSH {R3, LR}
	MOV R3, R0
	CMP R3, R1
	BLT mod_done
	mod_loop:
		SUB R3, R3, R1
		CMP R3, R1
		BGE mod_loop
	mod_done:
		MOV R0, R3
		POP {R3, LR}
		BX LR
get_random:
	PUSH {R1-R3, LR}
	LDR R1, =rand_seed
	LDRB R2, [R1]
	LDR R3, =rand_a
	LDRB R3, [R3]
	MUL R2, R2, R3
	LDR R3, =rand_c
	LDRB R3, [R3]
	ADD R2, R2, R3
	AND R2, R2, #0x00FF
	STRB R2, [R1]
	MOV R0, R2
	POP {R1-R3, LR}
	BX LR
swapL1:
	PUSH {R0, R1, R9, R5, LR}
	LDR R9, =cacheL1
	LDRB R0, [R9, R8]
	LSR R5, R6, #1
	ADD R9, R9, R5 
	LDRB R1, [R9, R8]
	STRB R0, [R9, R8]
	LDR R9, =cacheL1
	STRB R1, [R9, R8]
	POP {R0, R1, R9, R5, LR}
	BX LR
swapL2:
	PUSH {R0, R1, R9, R5, LR}
	LDR R9, =cacheL2
	LDRB R0, [R9, R8]
	LSR R5, R7, #1
	ADD R9, R9, R5 
	LDRB R1, [R9, R8]
	STRB R0, [R9, R8]
	LDR R9, =cacheL2
	STRB R1, [R9, R8]
	POP {R0, R1, R9, R5, LR}
	BX LR	
	
	
	
	
	
	
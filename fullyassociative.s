.data
.align 2
inputarray: .byte 8, 5, 6, 6, 6, 6, 2, 7
.align 2
hitmissL1: .byte  0, 0, 0, 0, 0, 0, 0, 0
.align 2
hitmissL2: .byte  0, 0, 0, 0, 0, 0, 0, 0
.align 2
cacheL1:  .space 4
.align 2
cacheL2:  .space 4
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
.align 2
.global _start
_start:
  LDR R0, =cacheL1
  LDR R0, =cacheL2
  LDR R0, =inputarray @R0 = inputarray
  MOV R1, #5 @policy for L1 = 0 FIFO, 1 LRU, 2 MRU, 3 LFU, 4 MFU, 5 random
  MOV R2, #5 @policy for L2 = 0 FIFO, 1 LRU, 2 MRU, 3 LFU, 4 MFU, 5 random
  MOV R3, #8 @R3 = sizeof input addrs
  MOV R4, #0 @R4 = indexofLast free in L1
  MOV R5, #0 @R5 = indexofLast free in L2
  MOV R6, #0 @R6 = i (for traversing the input array)
  MOV R11, #4 @size of L1
  MOV R12, #4 @size of L2
  SUB R11, R11, #1 @R11 = Last available index in L1
  SUB R12, R12, #1 @R12 = Last available index in L2
  
  LOOP:
    CMP R6, R3
    BGE end
    @search in L1
    MOV R7, #0 @R7 = j for traversing the L1
    LDRB R8, [R0, R6] @R8 = address to be cheked in cache
    LOOP1:
      CMP R7, R4
      BGE miss_end_of_LOOP1
      LDR R9, =cacheL1
      ADD R9, R9, R7
      LDRB R10, [R9]
      CMP R10, R8
      BEQ hit_end_of_LOOP1
      ADD R7, R7, #1
      B LOOP1
    miss_end_of_LOOP1:
      BL missL1
        MOV R7, #0 @R7 = j for traversing the L2
        LOOP2:
          CMP R7, R5
          BGE miss_end_of_LOOP2
          LDR R9, =cacheL2
          ADD R9, R9, R7
          LDRB R10, [R9]
          CMP R10, R8
          BEQ hit_end_of_LOOP2
          ADD R7, R7, #1
          B LOOP2
        miss_end_of_LOOP2:
          BL missL2
          CMP R5, R12
          BLE save_new_L2
          BL replacementL2
          save_new_L2:
            LDR R9, =cacheL2
            ADD R9, R9, R5
            STRB R8, [R9]@update cache L2
            CMP R2, #1 @LRU
            BLEQ update_new_LRUL2
            CMP R2, #2 @MRU
            BLEQ update_new_MRUL2
            CMP R2, #3 @LFU
            BLEQ update_new_LFUL2
            CMP R2, #4 @MFU
            BLEQ update_new_MFUL2
            ADD R5, R5, #1 @update R5
            B handle_L1_miss
        hit_end_of_LOOP2:
          BL hitL2
          CMP R2, #1 @LRU
          BLEQ update_hit_LRUL2
          CMP R2, #2 @MRU
          BLEQ update_hit_MRUL2
          CMP R2, #3 @LFU
          BLEQ update_hit_LFUL2
          CMP R2, #4 @MFU
          BLEQ update_hit_MFUL2
      handle_L1_miss:
        CMP R4, R11
        BLE save_new_L1
        BL replacementL1
        B next_LOOP
        save_new_L1:
          LDR R9, =cacheL1
          ADD R9, R9, R4
          STRB R8, [R9]@update cache L1
          CMP R1, #1 @LRU
          BLEQ update_new_LRUL1
          CMP R1, #2 @MRU
          BLEQ update_new_MRUL1
          CMP R1, #3 @LFU
          BLEQ update_new_LFUL1
          CMP R1, #4 @MFU
          BLEQ update_new_MFUL1
          ADD R4, R4, #1 @update R4
          B next_LOOP
    hit_end_of_LOOP1:
      BL hitL1
      CMP R1, #1 @LRU
      BLEQ update_hit_LRUL1
      CMP R1, #2 @MRU
      BLEQ update_hit_MRUL1
      CMP R1, #3 @LFU
      BLEQ update_hit_LFUL1
      CMP R1, #4 @MFU
      BLEQ update_hit_MFUL1
      BL hitL2
    next_LOOP:
      ADD R6, R6, #1
      B LOOP
end:
  B end
replacementL1:
  PUSH {LR}
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
  PUSH {R6-R10}
  MOV R6, #0
  LDR R9, =cacheL1
  ADD R9, R9, R4
  STRB R8, [R9]
  LOOPFIFO1:
    CMP R6, R4
    BEQ end_FIFOL1
    LDR R9, =cacheL1
    ADD R9, R9, R6
    ADD R9, R9, #1
    LDRB R10, [R9]
    SUB R9, R9, #1
    STRB R10, [R9]
    ADD R6, R6, #1
    B LOOPFIFO1
end_FIFOL1:
  LDR R9, =cacheL1
  ADD R9, R9, R4
  STRB R8, [R9]
  POP {R6-R10}
  B end_replacementL1

LRUL1:
  PUSH {R6}
  LDR R6, =cacheL1
  ADD R6, R6, R4
  SUB R6, R6, #1
  STRB R8, [R6]
  POP {R6}
  B end_replacementL1
MRUL1:
  PUSH {R6}
  LDR R6, =cacheL1
  STRB R8, [R6]
  POP {R6}
  B end_replacementL1
LFUL1:
  PUSH {R5-R12}
  MOV R6, #0
  MOV R7, #0 @min index
  MOV R5, #255 @min count = initial biggest possible
  LDR R9, =cacheL1
  LDR R10, =countL1
  LOOPLFUL1:
    CMP R6, R4
    BEQ end_LOOP_LFUL1
    LDRB R11, [R9, R6]
    LDRB R12, [R10, R11]
    CMP R12, R5
    BLT changeLFUL1
    ADD R6, R6, #1
    B LOOPLFUL1
  changeLFUL1:
    MOV R5, R12
    MOV R7, R6
    ADD R6, R6, #1
    B LOOPLFUL1
  end_LOOP_LFUL1:
    CMP R5, #255
    BEQ end_LFUL1
    STRB R8, [R9, R7]
  end_LFUL1:
    POP {R5-R12}
    B end_replacementL1
MFUL1:
  PUSH {R5-R12}
  MOV R6, #0
  MOV R7, #0 @max index
  MOV R5, #-1 @max count = initial = -1
  LDR R9, =cacheL1
  LDR R10, =countL1
  LOOPMFUL1:
    CMP R6, R4
    BEQ end_LOOP_MFUL1
    LDRB R11, [R9, R6]
    LDRB R12, [R10, R11]
    CMP R12, R5
    BGT changeMFUL1
    ADD R6, R6, #1
    B LOOPMFUL1
  changeMFUL1:
    MOV R5, R12
    MOV R7, R6
    ADD R6, R6, #1
    B LOOPMFUL1
  end_LOOP_MFUL1:
    CMP R5, #-1
    BEQ end_MFUL1
    STRB R8, [R9, R7]
  end_MFUL1:
    POP {R5-R12}
	B end_replacementL1
  B end_replacementL1

RANDL1:
	PUSH {R0-R3, R9, LR}
	BL get_random
	MOV R1, R4
	BL mod_func
	LDR R9, =cacheL1
	STRB R8, [R9, R0]
	end_RANDL1:
	POP {R0-R3, R9, LR}
	B end_replacementL1

end_replacementL1:
  POP {LR}
  BX LR

replacementL2:
  PUSH {LR}
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
  PUSH {R6-R10}
  MOV R6, #0
  LDR R9, =cacheL2
  ADD R9, R9, R5
  STRB R8, [R9]
  LOOPFIFO2:
    CMP R6, R5
    BEQ end_FIFOL2
    LDR R9, =cacheL2
    ADD R9, R9, R6
    ADD R9, R9, #1
    LDRB R10, [R9]
    SUB R9, R9, #1
    STRB R10, [R9]
    ADD R6, R6, #1
    B LOOPFIFO2
end_FIFOL2:
  LDR R9, =cacheL2
  ADD R9, R9, R5
  STRB R8, [R9]
  POP {R6-R10}
  B end_replacementL2

LRUL2:
  PUSH {R6}
  LDR R6, =cacheL2
  ADD R6, R6, R5
  SUB R6, R6, #1
  STRB R8, [R6]
  POP {R6}
  B end_replacementL2

MRUL2:
  PUSH {R6}
  LDR R6, =cacheL2
  STRB R8, [R6]
  POP {R6}
  B end_replacementL2

LFUL2:
  PUSH {R4-R12}
  MOV R6, #0
  MOV R7, #0 @min index
  MOV R4, #255 @min count = initial biggest possible
  LDR R9, =cacheL2
  LDR R10, =countL2
  LOOPLFUL2:
    CMP R6, R5
    BEQ end_LOOP_LFUL2
    LDRB R11, [R9, R6]
    LDRB R12, [R10, R11]
    CMP R12, R4
    BLT changeLFUL2
    ADD R6, R6, #1
    B LOOPLFUL2
  changeLFUL2:
    MOV R4, R12
    MOV R7, R6
    ADD R6, R6, #1
    B LOOPLFUL2
  end_LOOP_LFUL2:
    CMP R4, #255
    BEQ end_LFUL2
    STRB R8, [R9, R7]
  end_LFUL2:
    POP {R4-R12}
    B end_replacementL2
MFUL2:
  PUSH {R4-R12}
  MOV R6, #0
  MOV R7, #0 @max index
  MOV R4, #-1 @max count = initial = -1
  LDR R9, =cacheL2
  LDR R10, =countL2
  LOOPMFUL2:
    CMP R6, R5
    BEQ end_LOOP_MFUL2
    LDRB R11, [R9, R6]
    LDRB R12, [R10, R11]
    CMP R12, R4
    BGT changeMFUL2
    ADD R6, R6, #1
    B LOOPMFUL2
  changeMFUL2:
    MOV R4, R12
    MOV R7, R6
    ADD R6, R6, #1
    B LOOPMFUL2
  end_LOOP_MFUL2:
    CMP R4, #-1
    BEQ end_MFUL2
    STRB R8, [R9, R7]
  end_MFUL2:
    POP {R4-R12}
    B end_replacementL2
  B end_replacementL2

RANDL2:
	PUSH {R0-R3, R9, LR}
	BL get_random
	MOV R1, R5
	BL mod_func
	LDR R9, =cacheL2
	STRB R8, [R9, R0]
	end_RANDL2:
	POP {R0-R3, R9, LR}
	B end_replacementL2

end_replacementL2:
  POP {LR}
  BX LR
update_new_MRUL1:
  PUSH {R9-R10, LR}
  LDR R9, =cacheL1
  LDRB R10, [R9]
  ADD R9, R9, R4
  LDRB R8, [R9]
  STRB R10, [R9]
  LDR R9, =cacheL1
  STRB R8, [R9]
  POP {R9-R10, LR}
  BX LR
update_new_MRUL2:
  PUSH {R9-R10, LR}
  LDR R9, =cacheL2
  LDRB R10, [R9]
  ADD R9, R9, R5
  LDRB R8, [R9]
  STRB R10, [R9]
  LDR R9, =cacheL2
  STRB R8, [R9]
  POP {R9-R10, LR}
  BX LR
update_new_LRUL1:
  PUSH {R7-R11, LR}
  MOV R7, R4
  SUB R7, R7, #1
  MOV R9, R8
  LDR R11, =cacheL1
  LOOPupdate_new_LRUL1:
    CMP R7, #0
    BLT end_LOOPupdate_new_LRUL1
    LDRB R10, [R11, R7]
    ADD R7, R7, #1
    STRB R10, [R11, R7]
    SUB R7, R7, #2 
    B LOOPupdate_new_LRUL1
  end_LOOPupdate_new_LRUL1:
    STRB R9, [R11]
    POP {R7-R11, LR}
    BX LR
update_new_LRUL2:
  PUSH {R7-R11, LR}
  MOV R7, R5
  SUB R7, R7, #1
  MOV R9, R8
  LDR R11, =cacheL2
  LOOPupdate_new_LRUL2:
    CMP R7, #0
    BLT end_LOOPupdate_new_LRUL2
    LDRB R10, [R11, R7]
    ADD R7, R7, #1
    STRB R10, [R11, R7]
    SUB R7, R7, #2  
    B LOOPupdate_new_LRUL2
  end_LOOPupdate_new_LRUL2:
    STRB R9, [R11]
    POP {R7-R11, LR}
    BX LR
update_new_LFUL1:
  PUSH {R6-R8, LR}
  LDR R6 , =countL1
  LDRB R7, [R6, R8]
  ADD R7, R7, #1
  STRB R7, [R6, R8]
  POP {R6-R8, LR}
  BX LR
update_new_LFUL2:
  PUSH {R6-R8, LR}
  LDR R6 , =countL2
  LDRB R7, [R6, R8]
  ADD R7, R7, #1
  STRB R7, [R6, R8]
  POP {R6-R8, LR}
  BX LR
update_new_MFUL1:
  PUSH {R6-R8, LR}
  LDR R6 , =countL1
  LDRB R7, [R6, R8]
  ADD R7, R7, #1
  STRB R7, [R6, R8]
  POP {R6-R8, LR}
  BX LR
update_new_MFUL2:
  PUSH {R6-R8, LR}
  LDR R6 , =countL2
  LDRB R7, [R6, R8]
  ADD R7, R7, #1
  STRB R7, [R6, R8]
  POP {R6-R8, LR}
  BX LR
update_hit_LRUL1:
  PUSH {R6-R11, LR}
  LDR R9, =cacheL1
  LDRB R11, [R9, R7]
  MOV R6, R7
  SUB R6, R6, #1
  LOOPupdate_hit_LRUL1:
    CMP R6, #0
    BLT end_LOOPupdate_hit_LRUL1
    LDRB R10, [R9, R6]
    ADD R6, R6, #1
    STRB R10, [R9, R6]
    B LOOPupdate_hit_LRUL1
  end_LOOPupdate_hit_LRUL1:
    STRB R11, [R9]
    POP {R6-R11, LR}
    BX LR
update_hit_LRUL2:
  PUSH {R6-R11, LR}
  LDR R9, =cacheL2
  LDRB R11, [R9, R7]
  MOV R6, R7
  SUB R6, R6, #1
  LOOPupdate_hit_LRUL2:
    CMP R6, #0
    BLT end_LOOPupdate_hit_LRUL2
    LDRB R10, [R9, R6]
    ADD R6, R6, #1
    STRB R10, [R9, R6]
    B LOOPupdate_hit_LRUL2
  end_LOOPupdate_hit_LRUL2:
    STRB R11, [R9]
    POP {R6-R11, LR}
    BX LR
update_hit_MRUL1:
  PUSH {R6-R11, LR}
  LDR R9, =cacheL1
  LDRB R11, [R9]
  STRB R8, [R9]
  STRB R11, [R9, R7]
  POP {R6-R11, LR}
  BX LR
update_hit_MRUL2:
  PUSH {R6-R11, LR}
  LDR R9, =cacheL1
  LDRB R11, [R9]
  STRB R8, [R9]
  STRB R11, [R9, R7]
  POP {R6-R11, LR}
  BX LR
update_hit_LFUL1:
  PUSH {R6-R8, LR}
  LDR R6 , =countL1
  LDRB R7, [R6, R8]
  ADD R7, R7, #1
  STRB R7, [R6, R8]
  POP {R6-R8, LR}
  BX LR
update_hit_LFUL2:
  PUSH {R6-R8, LR}
  LDR R6 , =countL2
  LDRB R7, [R6, R8]
  ADD R7, R7, #1
  STRB R7, [R6, R8]
  POP {R6-R8, LR}
  BX LR
update_hit_MFUL1:
  PUSH {R6-R8, LR}
  LDR R6 , =countL1
  LDRB R7, [R6, R8]
  ADD R7, R7, #1
  STRB R7, [R6, R8]
  POP {R6-R8, LR}
  BX LR
update_hit_MFUL2:
  PUSH {R6-R8, LR}
  LDR R6 , =countL2
  LDRB R7, [R6, R8]
  ADD R7, R7, #1
  STRB R7, [R6, R8]
  POP {R6-R8, LR}
  BX LR
missL1:
  PUSH {R7, R8, LR}
  MOV R7, #0
  LDR R8, =hitmissL1
  STRB R7, [R8, R6]
  POP {R7, R8, LR}
  BX LR
hitL1:
  PUSH {R7, R8, LR}
  MOV R7, #1
  LDR R8, =hitmissL1
  STRB R7, [R8, R6]
  POP {R7, R8, LR}
  BX LR
missL2:
  PUSH {R7, R8, LR}
  MOV R7, #0
  LDR R8, =hitmissL2
  STRB R7, [R8, R6]
  POP {R7, R8, LR}
  BX LR
hitL2:
  PUSH {R7, R8, LR}
  MOV R7, #1
  LDR R8, =hitmissL2
  STRB R7, [R8, R6]
  POP {R7, R8, LR}
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
	
	
	
	
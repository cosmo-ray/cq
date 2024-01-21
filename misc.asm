; Returns a random 8-bit number in A (0-255), clobbers Y (unknown).
prng:
	lda seed+1
	tay ; store copy of high byte
	; compute seed+1 ($39>>1 = %11100)
	lsr A ; shift to consume zeroes on left...
	lsr A
	lsr A
	sta seed+1 ; now recreate the remaining bits in reverse order... %111
	lsr A
	eor seed+1
	lsr A
	eor seed+1
	eor seed+0 ; recombine with original low byte
	sta seed+1
	; compute seed+0 ($39 = %111001)
	tya ; original high byte
	sta seed+0
	asl A
	eor seed+0
	asl A
	eor seed+0
	asl A
	asl A
	asl A
	eor seed+0
	sta seed+0
	rts

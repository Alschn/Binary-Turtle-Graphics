#-------------------------------------------------------------------------------
# MIPS Project - ARKO 20L
# Binary Turtle Graphics
# Adam Lisichin
#-------------------------------------------------------------------------------
.eqv HEADER_SIZE 122
.eqv BMP_FILE_SIZE 90122	# 600x50x3 + 122
.eqv BMP_IMG_SIZE 90000
.eqv BYTES_PER_ROW 1800		# 600x3
.eqv PROGR_FILE_SIZE 6000

.data
n_instr:		.asciiz "n_instr  "
text_00:		.asciiz "\nset pen  "
text_01:		.asciiz "\nmove  "
text_10:		.asciiz "\nset dir  "
text_11:		.asciiz "\nset pos  "
spacja:			.asciiz "\t"

dialog:		.asciiz "File not found"
f_input:  	.asciiz "input.bin"
f_output:	.asciiz "output.bmp"
.align 2
progr:		.space PROGR_FILE_SIZE
.align 2
			.space 2
image:		.byte 0x42,0x4d,0x0a,0x60,0x01,0,0,0,0,0,0x7a,0,0,0,0x6c,0,0,0,0x58,0x02,0,0,0x32,0,0,0,0x01,0,0x18,0,0,0,0,0,0x90,0x5f,0x01,0,0x13,0x0b,0,0,0x13,0x0b,0,0,0,0,0,0,0,0,0,0,0x42,0x47,0x52,0x73,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0x02,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
			.space BMP_IMG_SIZE

.text
# ============================================================================
main:
	# paint in white...
	li $t0, BMP_IMG_SIZE
	srl $t0, $t0, 2
	la $t1, image + HEADER_SIZE
	li $t2, 0xffffffff
imginit:
	sw $t2, ($t1)
	addi $t1, $t1, 4
	subi $t0, $t0, 1
	bgtz $t0, imginit
	
	
	# read program
	jal read_bin_file
	# $s0 - instr counter

	#----------------#	
	# CONSOLE OUTPUT #
	#----------------#
	li $v0, 4		# print str
	la $a0, n_instr
	syscall
	li $v0, 1		# print int
	move $a0, $s0
	syscall
	
	
	# program pointer init
	la $s6, progr

	
	
loop:
	blez $s0, end	# if no instr left..
	
	# get instr
	lbu $t0, ($s6)
	sll $t0, $t0, 8
	lbu $t1, 1($s6)
	or $t0, $t0, $t1
	
	addi $s6, $s6, 2	# next instr pointer
	subi $s0, $s0, 1	# instruction counter--
	
	
	andi $t2, $t0, 3	# instr code
	
	# select command
	beqz $t2, instr00		# set pen state
	beq $t2, 1, instr01		# move turtle
	beq $t2, 2, instr10		# set direction
	beq $t2, 3, instr11		# set position
	
	
instr00:	# set pen state
	# R
	andi $s5, $t0, 0xf000
	sll $s5, $s5, 8
	# G
	andi $t2, $t0, 0x0f00
	sll $t2, $t2, 4
	or $s5, $s5, $t2
	# B
	andi $t2, $t0, 0x00f0
	or $s5, $s5, $t2
	# U/D (D=8)
	andi $s4, $t0, 0x0008
	
	#----------------#	
	# CONSOLE OUTPUT #
	#----------------#
	li $v0, 4		# print str
	la $a0, text_00
	syscall
	li $v0, 34		# print int hex
	move $a0, $s5
	syscall
	li $v0, 4		# print str
	la $a0, spacja
	syscall
	li $v0, 34		# print int hex
	move $a0, $s4
	syscall
	
	j loop
	
	
instr01:	# move
	srl $t2, $t0, 6	# distance
	
	#----------------#	
	# CONSOLE OUTPUT #
	#----------------#
	li $v0, 4		# print str
	la $a0, text_01
	syscall
	li $v0, 1		# print int
	move $a0, $t2
	syscall

	# select direction
	beqz $s3, right
	beq $s3, 1, up
	beq $s3, 2, left
	beq $s3, 3, down	
		
right:
	beq $s1, 599, loop
	
	# limit
	addu $s7, $s1, $t2
	ble $s7, 599, goright
	li $s7, 599
	
goright:
	beqz $s4, skipright		# if pen up..
	
paintright:
	addiu $s1, $s1, 1	# x++
	move $a0, $s1
	move $a1, $s2
	move $a2, $s5
	jal put_pixel
	bltu $s1, $s7, paintright
	
skipright:
	move $s1, $s7
	
	j loop
	

up:
	beq $s2, 49, loop
	
	# limit
	addu $s7, $s2, $t2
	ble $s7, 49, goup
	li $s7, 49
	
goup:
	beqz $s4, skipup		# if pen up..
	
paintup:
	addiu $s2, $s2, 1	# y++
	move $a0, $s1
	move $a1, $s2
	move $a2, $s5
	jal put_pixel
	bltu $s2, $s7, paintup
	
skipup:
	move $s2, $s7
	
	j loop
	
	
left:
	beqz $s1, loop
	
	# limit
	subu $s7, $s1, $t2
	bgez $s7, goleft
	li $s7, 0
	
goleft:
	beqz $s4, skipleft		# if pen up..
	
paintleft:
	subiu $s1, $s1, 1	# x--
	move $a0, $s1
	move $a1, $s2
	move $a2, $s5
	jal put_pixel
	bgtu $s1, $s7, paintleft
	
skipleft:
	move $s1, $s7
	
	j loop
	
		
down:
	beqz $s2, loop
	
	# limit
	subu $s7, $s2, $t2
	bgez $s7, godown
	li $s7, 0
	
godown:
	beqz $s4, skipdown		# if pen up..
	
paintdown:
	subiu $s2, $s2, 1	# y--
	move $a0, $s1
	move $a1, $s2
	move $a2, $s5
	jal put_pixel
	bgtu $s2, $s7, paintdown
	
skipdown:
	move $s2, $s7
	
	j loop
	

instr10:	# set direction
	srl $s3, $t0, 14
	
	#----------------#	
	# CONSOLE OUTPUT #
	#----------------#
	li $v0, 4		# print str
	la $a0, text_10
	syscall
	li $v0, 1		# print int
	move $a0, $s3
	syscall
	
	j loop
	
		
instr11:	# set position
	# y
	andi $s2, $t0, 0x00fc
	srl $s2, $s2, 2
	# get next instr (2nd part)
	lbu $s1, ($s6)
	sll $s1, $s1, 8
	lbu $t1, 1($s6)
	or $s1, $s1, $t1
	addi $s6, $s6, 2	# wsk
	subi $s0, $s0, 1	# counter--
	# x
	andi $s1, $s1, 0x03ff
	
	
	
	li $v0, 4		# print str
	la $a0, text_11
	syscall
	li $v0, 1		# print int
	move $a0, $s1
	syscall
	li $v0, 4		# print str
	la $a0, spacja
	syscall
	li $v0, 1		# print int
	move $a0, $s2
	syscall
	
	j loop
	
	
	
end:
	jal save_bmp
	

exit:
	li $v0, 10		
	syscall
# ============================================================================	
# BELOW: reading binary files, saving bmp file, operations on pixels
# ============================================================================
read_bin_file:
	sub $sp, $sp, 4		# push $ra to the stack
	sw $ra, 4($sp)
	sub $sp, $sp, 4		# push $s1
	sw $s1, 4($sp)
	
	li $v0, 13			# open file
	la $a0, f_input
	li $a1, 0		# 0 = read
	li $a2, 0 		# ignored
	syscall	
	move $s1, $v0		# save the file descriptor to $s1
	
	bgtz $s1, read 
	
	lw $s1, 4($sp)
	add $sp, $sp, 4
	lw $ra, 4($sp)
	add $sp, $sp, 4
	li $v0, 4			# print string
	la $a0, dialog 		# if there is an error in reading file ($s1 < 0)
	syscall
	jr $ra
	
read:
	li $v0, 14			# read from file
	move $a0, $s1			# file descr.
	la $a1, progr			# destination
	li $a2, PROGR_FILE_SIZE	# max size
	syscall
	
	# zwrocic liczbe wczytanych 2-bajtow !!!!!!!!!!!!!!
#	move $s0, $v0
	sra $s0, $v0, 1
	
	
	li $v0, 16			# close file
	move, $a0, $s1			# file descr.
	syscall
	
	# finish
	lw $s1, 4($sp)
	add $sp, $sp, 4
	lw $ra, 4($sp)
	add $sp, $sp, 4
	jr $ra

# ============================================================================


save_bmp:
#description: 
#	saves bmp file stored in memory to a file
#arguments:
#	none
#return value: none
	sub $sp, $sp, 4		#push $ra to the stack
	sw $ra,4($sp)
	sub $sp, $sp, 4		#push $s1
	sw $s1, 4($sp)
#open file
	li $v0, 13
        la $a0, f_output		#file name 
        li $a1, 1		#flags: 1-write file
        li $a2, 0		#mode: ignored
        syscall
	move $s1, $v0      # save the file descriptor
	
	bgtz $s1, save_file 
	
	lw $s1, 4($sp)
	add $sp, $sp, 4
	li $v0, 4			# print string
	la $a0, dialog 		# if there is an error in reading file ($s1 < 0)
	syscall
	jr $ra
	

save_file:	#save file
	li $v0, 15
	move $a0, $s1
	la $a1, image
	li $a2, BMP_FILE_SIZE
	syscall

#close file
	li $v0, 16
	move $a0, $s1
        syscall
	
	lw $s1, 4($sp)		#restore (pop) $s1
	add $sp, $sp, 4
	lw $ra, 4($sp)		#restore (pop) $ra
	add $sp, $sp, 4
	jr $ra
	
# ============================================================================

put_pixel:
#description: 
#	sets the color of specified pixel
#arguments:
#	$a0 - x coordinate
#	$a1 - y coordinate - (0,0) - bottom left corner
#	$a2 - 0RGB - pixel color
#return value: none

	sub $sp, $sp, 4		#push $ra to the stack
	sw $ra,4($sp)

	la $t1, image + 10	#adress of file offset to pixel array
	lw $t2, ($t1)		#file offset to pixel array in $t2
	la $t1, image		#adress of bitmap
	add $t2, $t1, $t2	#adress of pixel array in $t2
	
	#pixel address calculation
	mul $t1, $a1, BYTES_PER_ROW #t1= y*BYTES_PER_ROW
	move $t3, $a0		
	sll $a0, $a0, 1
	add $t3, $t3, $a0	#$t3= 3*x
	add $t1, $t1, $t3	#$t1 = 3x + y*BYTES_PER_ROW
	add $t2, $t2, $t1	#pixel address 
	
	#set new color
	sb $a2,($t2)		#store B
	srl $a2,$a2,8
	sb $a2,1($t2)		#store G
	srl $a2,$a2,8
	sb $a2,2($t2)		#store R

	lw $ra, 4($sp)		#restore (pop) $ra
	add $sp, $sp, 4
	jr $ra
# ============================================================================

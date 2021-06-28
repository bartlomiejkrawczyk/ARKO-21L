	.data
.align 2
res1:	.space 2
header:	.space 6
size:	.space 4
copy:	.space 4
bytes_per_row: .space 4
imgpix:	.space 4
cppix: 	.space 4

fname:	.asciiz "Picture.bmp"
cpfname:.asciiz "Picture-Filtered.bmp"


	.text
	.globl main
main:
				# Load header
	
				# Open a file
	li $v0, 13		# System call for open file
        la $a0, fname		# File name
        li $a1, 0		# Open for reading: 0 -> read-only
        li $a2, 0		# Mode is ignored
        syscall			# Open a file (descriptor in $v0)
	move $t1, $v0      	# Save the file descriptor

				# Read the file
	li $v0, 14 		# System call for read file
	move $a0, $t1		# File descriptor
	la $a1, header		# Adress of header buffer
	li $a2, 6		# Hardcoded header length
	syscall			# Read file

				# Close the file
	li $v0, 16		# System call for close file
	move $a0, $t1		# File descriptor to close
        syscall			# Close file

				# Get size
	lw $t2, header+2	# File size
	sw $t2, size
	
				# Allocate memory for image and a copy
	li $v0, 9
	addiu $t3, $t2, 2	# Add 2 to align bmp file
	move $a0, $t3
	syscall
	
	move $t0, $v0		
	addiu $t0, $t0, 2	# Image address in $t0
	
	li $v0, 9
	move $a0, $t3
	syscall
	
	move $t1, $v0
	addiu $t1, $t1, 2	# Copy address in $t1
	sw $t1, copy
	
	
				# Load BMP File
				
				# Open a file
	li $v0, 13		# System call for open file
        la $a0, fname		# File name
        li $a1, 0		# Open for reading: 0 -> read-only
        li $a2, 0		# Mode is ignored
        syscall			# Open a file (descriptor in $v0)

				# Read the file
	move $a0, $v0		# File descriptor
	li $v0, 14 		# System call for read file
	move $a1, $t0		# Adress of image buffer
	move $a2, $t2		# File size
	syscall			# Read file

				# Close the file
	li $v0, 16		# System call for close file
				# File descriptor to close in $ a0
        syscall			# Close file
        
        
        
				# Copy the image
	lhu $t4, ($t0)
	sh $t4, ($t1)		# Copy first 2 bytes
	li $t3, 2		# Offset
cp_loop:
	addu $t5, $t0, $t3	# $t5 = img_address + offset
	lw $t4, ($t5)
	addu $t5, $t1, $t3	# $t5 = copy_address + offset
	sw $t4, ($t5)
	addiu $t3, $t3, 4
	blt $t3, $t2, cp_loop	# Branch if size < $t3
	
	
calculate_params:	
				# Calculate bmp params
				# Adress of bitmap in $t0
	lw $t3, 10($t0)		# File offset to pixel array in $t3
	addu $t2, $t0, $t3	# Adress of pixel array in $t2
	sw $t2, imgpix

				# Adress of bitmap copy in $t1
	addu $t2, $t1, $t3	# Adress of pixel array in $t2
	sw $t2, cppix

	lw $t1, 18($t0)		# Pixels per row
	move $s6, $t1		# Width


	andi $t5, $t1, 3	# Modulo 4
	sll $t2, $t1, 1		# $t2 = 2 * width
	addu $t1, $t2, $t1	# $t1 = 3 * width	
	addu $t1, $t1, $t5	# Bytes per row -> $t1 = 3 * pix + (pix % 4)
	sw $t1, bytes_per_row
		
	lw $s7, 22($t0)		# Pixels per column = pix
				# Height in $t7


				# Loop through every pixel and filter_pixel
	li $a1, 2		# y = 2
	addiu $s6, $s6, -2	# $s6 = width - 2
	addu $t0, $s6, $s6
	addu $s6, $s6, $t0	# $s6 = (width - 2) * 3
	addiu $s7, $s7, -2	# $s7 = height - 2
loop_y:
	li $a0, 6		# $a0 = 2 * 3
loop_x:
	move $a2, $zero
filter_pixel:			# $a0 = 3 * x coordinate
				# $a1 = y coordinate
				# $a2 = color offset: 0 - red, 1 - green, 2 - blue

				# Prepare registers
	move $s0, $zero		# Sum of color values
	
				# Max
	move $s1, $zero
	move $s2, $zero
	move $s3, $zero
	move $s4, $zero
	move $s5, $zero
				# Min
	li $t0, 0xFF
	li $t1, 0xFF
	li $t2, 0xFF
	li $t3, 0xFF
	li $t4, 0xFF

				# Loop
	move $t5, $a1		# y
	addiu $t5, $t5, -2	# current_y = y - 2
	li $t6, 5

loop:
				# Current row middle pixel address calculation
	lw $t7, bytes_per_row
	
	mul $t8, $t5, $t7	# $t8 = current_y * BYTES_PER_ROW
	addu $t9, $a0, $t8	# $t9 = 3x + current_y * BYTES_PER_ROW
	
	lw $t8, imgpix
	addu $t9, $t9, $t8	# pixel address
	
	addu $t9, $t9, $a2	# pixel address + color offset

		
	addiu $t9, $t9, -6	# first pixel address
	li $a3, 5		# $a3 - iterations
calc:					
	lbu $t8, ($t9)		# Load Color
	
	addu $s0, $t8, $s0	# Sum all values
	
	ble $t8, $s5, max_next	# Get 5 max values
	move $s5, $t8
	ble $t8, $s4, max_next
	move $s5, $s4
	move $s4, $t8
	ble $t8, $s3, max_next
	move $s4, $s3
	move $s3, $t8
	ble $t8, $s2, max_next
	move $s3, $s2
	move $s2, $t8
	ble $t8, $s1, max_next
	move $s2, $s1
	move $s1, $t8
max_next:
	bge $t8, $t4, min_next	# Get 5 min values
	move $t4, $t8
	bge $t8, $t3, min_next
	move $t4, $t3
	move $t3, $t8
	bge $t8, $t2, min_next
	move $t3, $t2
	move $t2, $t8
	bge $t8, $t1, min_next
	move $t2, $t1
	move $t1, $t8
	bge $t8, $t0, min_next
	move $t1, $t0
	move $t0, $t8
min_next:
	addiu $a3, $a3, -1	# Decrease loop counter
	addiu $t9, $t9, 3	# Next pixel color address
	bnez $a3, calc


	addiu $t5, $t5, 1	# y += 1
	addiu $t6, $t6, -1
	bnez $t6, loop
	
	
				# Calculate new value
	subu $s0, $s0, $s1
	subu $s0, $s0, $s2
	subu $s0, $s0, $s3
	subu $s0, $s0, $s4
	subu $s0, $s0, $s5
	
	subu $s0, $s0, $t0
	subu $s0, $s0, $t1
	subu $s0, $s0, $t2
	subu $s0, $s0, $t3
	subu $s0, $s0, $t4
	
	divu $s0, $s0, 15	# New Color Value	

				# Set Pixel Color
	lw $t5, bytes_per_row
				# pixel address calculation
	mul $t1, $a1, $t5	# $t1 = y * BYTES_PER_ROW
	add $t1, $a0, $t1	# $t1 = 3x + y * BYTES_PER_ROW
	add $t1, $t1, $a2	# $t1 = 3x + y * BYTES_PER_ROW + color_offset
	
	lw $t5, cppix
	add $t2, $t5, $t1	# pixel address
	
				# set new color
	sb $s0,($t2)		
	
	addiu $a2, $a2, 1
	bne $a2, 3, filter_pixel	# Filter pixel for every color 0, 1, 2 

	addiu $a0, $a0, 3
	blt $a0, $s6, loop_x	# Branch if 3x < 3(width - 2)
	
	addiu $a1, $a1, 1
	blt $a1, $s7, loop_y	# Branch if y < (height - 2) 


				# Write Modified file
				
				# Open a file
	li $v0, 13		# System call for open file
        la $a0, cpfname		# File name
        li $a1, 1		# Open for writing: 1 -> write-only
        li $a2, 0		# Mode is ignored
        syscall			# Open a file (descriptor in $v0)
	move $t0, $v0      	# Save the file descriptor
	
				# Write to file
	li $v0, 15		# system call for write to file
	move $a0, $t0		# File descriptor
	lw $a1, copy		# Adress of buffer from which to write

	lw $a2, size		# File size
	syscall			# Write to file

				# Close the file
	li $v0, 16		# System call for close file
	move $a0, $t0		# File descriptor to close
        syscall
	
exit:
	li $v0, 10		# System call for exit (terminate execution)
	syscall

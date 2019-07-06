# CSE 220 Programming Project #4
# Name: Christopher Wong
# Net ID: christwong
# SBU ID: 111386693

#################### DO NOT CREATE A .data SECTION ####################
#################### DO NOT CREATE A .data SECTION ####################
#################### DO NOT CREATE A .data SECTION ####################

.text

load_board:
	addi $sp, $sp, -12
	sw $s0, 0($sp)
	sw $s1, 4($sp)
	sw $s2, 8($sp)
	move $s0, $a0 # $s0 is the starting address of the board
	move $s1, $a1 # $s1 is the filename 
	move $a0, $a1 # puts file name to $a0
	li $a1, 0 # read only
	li $a2, 0 # ignore mode
	li $v0, 13 # open file opcode
	syscall # $v0 contains the file descriptor
	bltz $v0, file_not_found_or_error
	move $s2, $v0 # $s2 designated holder of file descriptor
	li $t0, 0 # initialize the value to be stored
	li $t2, 10 # used later to obtain double digits
find_num_rows:
	move $a0, $s2 # move file descriptor to $a0
	move $a1, $s0 # $s0 is the input buffer
	li $a2, 1 # max number of characters to read
	li $v0, 14 # read from file opcode
	syscall # $v0 is the number of characters read
	ble $v0, 0, file_not_found_or_error # or error
	lbu $t1, 0($s0) # loads the character placed in the input buffer
	beq $t1, '\n', finished_finding_num_rows
	mul $t0, $t0, $t2  # makes the first digit 10x the version
	addi $t1, $t1, -48 # turn ascii number into actual number 
	add $t0, $t0, $t1 # and add it to $t0
	j find_num_rows
finished_finding_num_rows:
	sw $t0, 0($s0) # stores the num of rows into 0($s0)
	addi $s0, $s0, 4 # moves to the start of where num of columns should be
	li $t0, 0 # resets $t0
find_num_cols:
	move $a0, $s2 # move file descriptor to $a0
	move $a1, $s0 # $s0 is the input buffer
	li $a2, 1 # max number of characters to read
	li $v0, 14 # read from file opcode
	syscall # $v0 is the number of characters read
	ble $v0, 0, file_not_found_or_error
	lbu $t1, 0($s0) # loads the character placed in the input buffer
	beq $t1, '\n', finished_finding_num_cols
	mul $t0, $t0, $t2  # makes the first digit 10x the version
	addi $t1, $t1, -48 # turn ascii number into actual number 
	add $t0, $t0, $t1 # and add it to $t0
	j find_num_cols
finished_finding_num_cols:
	sw $t0, 0($s0) # stores the num of rows into 0($s0)
	addi $s0, $s0, 4 # moves to the start of where the boards table should be
	move $t4, $s0 # retains the beginning of the rows and column structure (might not be needed)
	lb $t0, -8($s0) # grabs the num of rows 
	lb $t1, -4($s0) # grabs the num of cols
	mul $t3, $t0, $t1 # $t3 is now the number of slots
	li $t5, '.' # used later in case theres an invalid character
	li $t6, 0 # num of X's
	li $t7, 0 # num of O's
	li $t8, 0 # num of invalid chars
load_the_table_loop:
	beq $t3, 0, finished_loading_table
	move $a0, $s2 # move file descriptor to $a0
	move $a1, $s0 # $s0 is the input buffer
	li $a2, 1 # max number of characters to read
	li $v0, 14 # read from file opcode
	syscall # $v0 is the number of characters read
	ble $v0, 0, file_not_found_or_error
	lbu $t0, 0($s0) # $t0 is the character read
	beq $t0, '\n', skip_this # don't write the new line, skip it
	addi $t3, $t3, -1 # subtract the counter
	beq $t0, '.', passed
	beq $t0, 'X', x.passed
	beq $t0, 'O', o.passed
	addi $t8, $t8, 1 # increment num of invalid chars
	sb $t5, 0($s0) # if it's not a valid character, store the '.'
	j passed
x.passed:
	addi $t6, $t6, 1 # increment num of Xs
	j passed
o.passed:
	addi $t7, $t7, 1 # increment num of Os
passed:
	addi $s0, $s0, 1 # go to the next spot 
skip_this: # the \n will get overridden because $s0 was not incremented
	j load_the_table_loop
finished_loading_table: # gotta set up $v0
	move $a0, $s5 # file descriptor
	li $v0, 16 # close file
	sll $t6, $t6, 16 # shift X's over 
	sll $t7, $t7, 8 # shift O's over
	add $v0, $0, $t6
	add $v0, $v0, $t7
	add $v0, $v0, $t8 # puts it all together
	j load_board.finished
file_not_found_or_error:
	li $v0, -1
	j load_board.finished
load_board.finished:
	lw $s0, 0($sp)
	lw $s1, 4($sp)
	lw $s2, 8($sp)
	addi $sp, $sp, 12
    	jr $ra

get_slot: # $a1 is i, $a2 is j in a[i][j]
	lw $t0, 0($a0) # num_of_rows
	lw $t1, 4($a0) # num_of_cols
	bge $a1, $t0, invalid_slot
	bge $a2, $t1, invalid_slot
	bltz $a1, invalid_slot
	bltz $a2, invalid_slot
	addi $a0, $a0, 8 # bring to start of array
	# a[i][j] = base addr + elem size * (i * # col + j)
	mul $a1, $a1, $t1  # i * # col
	add $a1, $a1, $a2 # + j
	add $a0, $a0, $a1 # base addr + ____
	lb $v0, 0($a0)
    	jr $ra
invalid_slot:
	li $v0, -1 # invalid
	jr $ra
set_slot:
	lw $t0, 0($a0) # num_of_rows
	lw $t1, 4($a0) # num_of_cols
	bge $a1, $t0, invalid_slot
	bge $a2, $t1, invalid_slot
	bltz $a1, invalid_slot
	bltz $a2, invalid_slot
	addi $a0, $a0, 8 # bring to start of array
	# a[i][j] = base addr + elem size * (i * # col + j)
	mul $a1, $a1, $t1  # i * # col
	add $a1, $a1, $a2 # + j
	add $a0, $a0, $a1 # base addr + ____
	sb $a3, 0($a0)
	move $v0, $a3
    	jr $ra
place_piece:
	addi $sp, $sp, -16
	sw $ra, 0($sp)
	sw $s0, 4($sp)
	sw $s1, 8($sp)
	sw $s2, 12($sp)
	move $s0, $a0
	move $s1, $a1
	move $s2, $a2
	beq $a3, 'X', placable
	beq $a3, 'O', placable
	j invalid_player # player isn't 'X' or 'O'
placable:
	jal get_slot
	beq $v0, -1, invalid_placement
	bne $v0, '.', invalid_placement # already a player piece
	move $a0, $s0
	move $a1, $s1
	move $a2, $a2
	jal set_slot # if it makes it this far, set the slot to the player
	j exit_place_piece # v0 will be the character placed
invalid_player:
invalid_placement:
	li $v0, -1 # error
	j exit_place_piece
exit_place_piece:
	lw $ra, 0($sp)
	lw $s0, 4($sp)
	lw $s1, 8($sp)
	lw $s2, 12($sp)
	addi $sp, $sp, 16
    	jr $ra

game_status:
	lw $t0, 0($a0) # num rows
	lw $t1, 4($a0) # num columns
	mul $t2, $t0, $t1 # num times to iterate
	li $v0, 0 # initial counters, X
	li $v1, 0  # O
	addi $a0, $a0, 8 # brings to start of array
game_status_checker:
	beq $t2, 0, done_checking
	addi $t2, $t2, -1
	lbu $t3, 0($a0) # loads character
	beq $t3, 'X', count_x
	beq $t3, 'O', count_o
continue_counting:
	addi $a0, $a0, 1 # increment to next
	j game_status_checker
count_x:
	addi $v0, $v0, 1
	j continue_counting
count_o:
	addi $v1, $v1, 1
	j continue_counting
done_checking:
    	jr $ra

check_horizontal_capture:
	addi $sp, $sp, -32
	sw $ra, 0($sp)
	sw $s0, 4($sp)
	sw $s1, 8($sp)
	sw $s2, 12($sp)
	sw $s3, 16($sp)
	sw $s4, 20($sp)
	sw $s5, 24($sp)
	sw $s6, 28($sp) # s6 is player X or O
	move $s0, $a0
	move $s1, $a1 # target row
	move $s2, $a2 # target col
	move $s6, $a3
	lw $s4, 0($s0) # num rows
	lw $s5, 4($s0) # num cols
# Check for preconditions
	bge $a1, $s4, invalid_during_row_check
	bge $a2, $s5, invalid_during_row_check
	beq $s6, 'X', x_player_passed
	beq $s6, 'O', o_player_passed
	j invalid_during_row_check # player failed
x_player_passed:
	li $s3, 'O' # O is the enemy
	j player_passed
o_player_passed:
	li $s3, 'X' # X is the enemy
	j player_passed
player_passed:
	jal get_slot
	bne $s6, $v0, invalid_during_row_check # if player isn't in the slot
	li $v0, 0 # initialize $v0 to be the counter
	addi $s0, $s0, 8 # bring to start of array
	# a[i][j] = base addr + elem size * (i * # col + j)
	mul $t0, $s1, $s5  # i * # col
	add $t0, $t0, $s2 # + j
	add $s0, $s0, $t0 # base addr + ____
	blt $s2, 3, skip_checking_left # can't possibly be a capture
	addi $s4, $s4, -3 # valid cols = 3 -> #cols-3
	sgt $t9, $s2, $s4 # $t9 will be 1 if the desired row is greater than $s0, used to skip checking right <-- check this
check_left:
	lbu $t0, -1($s0) # X O O* X 
	bne $t0, $s3, check_right # if it's not the enemy
	lbu $t0, -2($s0) # X O* O X
	bne $t0, $s3, check_right
	lbu $t0, -3($s0) # X* O O X 
	bne $t0, $s6, check_right # if it's not the player
	li $t5, '.'
	sb $t5, -1($s0) # if it makes it this far, a row capture is completed turning the middle to '.'
	sb $t5, -2($s0) 
	addi $v0, $v0, 2 # increases # captured by 2
skip_checking_left:
check_right:
	beq $t9, 1, finished_checking_row_capture # can't check right
	lbu $t0, 1($s0) # X O* O X 
	bne $t0, $s3, finished_checking_row_capture # if it's not the enemy
	lbu $t0, 2($s0) # X O O* X
	bne $t0, $s3, finished_checking_row_capture
	lbu $t0, 3($s0) # X O O X*
	bne $t0, $s6, finished_checking_row_capture # if it's not the player
	li $t5, '.'
	sb $t5, 1($s0) # if it makes it this far, a row capture is completed turning the middle to '.'
	sb $t5, 2($s0) 
	addi $v0, $v0, 2 # increases # captured by 2
finished_checking_row_capture:
	j exit_row_check
invalid_during_row_check:
	li $v0, -1
	j exit_row_check
exit_row_check:
	lw $ra, 0($sp)
	lw $s0, 4($sp)
	lw $s1, 8($sp)
	lw $s2, 12($sp)
	lw $s3, 16($sp)
	lw $s4, 20($sp)
	lw $s5, 24($sp)
	lw $s6, 28($sp) # s6 will be the enemy this time
	addi $sp, $sp, 32
    	jr $ra
check_vertical_capture:
	addi $sp, $sp, -32
	sw $ra, 0($sp)
	sw $s0, 4($sp)
	sw $s1, 8($sp)
	sw $s2, 12($sp)
	sw $s3, 16($sp)
	sw $s4, 20($sp)
	sw $s5, 24($sp)
	sw $s6, 28($sp)
    	move $s0, $a0
    	move $s1, $a1 # target row
    	move $s2, $a2 #target col
    	move $s3, $a3
# Check for preconditions
	lw $s4, 0($s0) # num rows
	lw $s5, 4($s0) # num cols
	bge $s1, $s4, invalid_during_vert_check
	bge $s2, $s5, invalid_during_vert_check
	beq $s3, 'X', x_player_passed_vert
	beq $s3, 'O', o_player_passed_vert
	j invalid_during_vert_check # player failed
x_player_passed_vert:
	li $s6, 'O' # O is the enemy
	j player_passed_vert
o_player_passed_vert:
	li $s6, 'X' # X is the enemy
	j player_passed_vert
player_passed_vert:
	jal get_slot
	bne $s3, $v0, invalid_during_vert_check # if player isn't in the slot
	li $v0, 0 # initialize counter
	addi $s0, $s0, 8 # put to start of array
	mul $t0, $s1, $s5  # i * # col
	add $t0, $t0, $s2 # + j
	add $s0, $s0, $t0 # base addr + ____
	blt $s1, 3, skip_up_check
	addi $t0, $s4, -3 # valid row to check down
	sgt $t9, $s1, $t0 # t9 will be set to 1 if it can't reach downward
check_up: # to go up one row, it's current spot - # of cols
	li $t7, -1 # used to negate 
	mul $t8, $s5, $t7 # $t8 = - # col
	add $t0, $s0, $t8 # $t0 = 1 rows up
	lbu $t1, 0($t0) # check byte 
	bne $t1, $s6, check_down # if it aint the enemy, we done here
	add $t2, $t0, $t8 # $t2 = 2 rows up
	lbu $t1, 0($t2) # check byte 
	bne $t1, $s6, check_down # if it aint the enemy, we done here
	add $t3, $t2, $t8 # $t3 = 3 rows up
	lbu $t1, 0($t3) # check byte 
	bne $t1, $s3, check_down # if it aint the player, we done here
	li $t5, '.'
	sb $t5, 0($t0) # if it makes it this far, a row capture is completed turning the middle to '.'
	sb $t5, 0($t2) 
	addi $v0, $v0, 2 # increases # captured by 2
skip_up_check:
check_down:
	add $t0, $s0, $s5 # $t0 = 1 rows down
	lbu $t1, 0($t0) # check byte 
	bne $t1, $s6, finished_checking_vert_capture # if it aint the enemy, we done here
	add $t2, $t0, $s5 # $t2 = 2 rows down
	lbu $t1, 0($t2) # check byte 
	bne $t1, $s6, finished_checking_vert_capture # if it aint the enemy, we done here
	add $t3, $t2, $s5 # $t3 = 3 rows down
	lbu $t1, 0($t3) # check byte 
	bne $t1, $s3, finished_checking_vert_capture # if it aint the player, we done here
	li $t5, '.'
	sb $t5, 0($t0) # if it makes it this far, a row capture is completed turning the middle to '.'
	sb $t5, 0($t2) 
	addi $v0, $v0, 2 # increases # captured by 2
finished_checking_vert_capture:
	j exit_vert_check
invalid_during_vert_check:
	li $v0, -1
	j exit_vert_check	
exit_vert_check:
	lw $ra, 0($sp)
	lw $s0, 4($sp)
	lw $s1, 8($sp)
	lw $s2, 12($sp)
	lw $s3, 16($sp)
	lw $s4, 20($sp)
	lw $s5, 24($sp)
	lw $s6, 28($sp)
	addi $sp, $sp, 32
	jr $ra
	
check_diagonal_capture:
	addi $sp, $sp, -32
	sw $ra, 0($sp)
	sw $s0, 4($sp)
	sw $s1, 8($sp)
	sw $s2, 12($sp)
	sw $s3, 16($sp)
	sw $s4, 20($sp)
	sw $s5, 24($sp)
	sw $s6, 28($sp)
    	move $s0, $a0
    	move $s1, $a1 # target row
    	move $s2, $a2 #target col
    	move $s3, $a3 # $s3 is player
# Check for preconditions
	lw $s4, 0($s0) # num rows
	lw $s5, 4($s0) # num cols
	bge $s1, $s4, invalid_during_diag_check
	bge $s2, $s5, invalid_during_diag_check
	beq $s3, 'X', x_player_passed_diag
	beq $s3, 'O', o_player_passed_diag
	j invalid_during_diag_check # player failed
x_player_passed_diag:
	li $s6, 'O' # O is the enemy
	j player_passed_diag
o_player_passed_diag:
	li $s6, 'X' # X is the enemy
	j player_passed_diag
player_passed_diag:
	jal get_slot
	bne $s3, $v0, invalid_during_diag_check # if player isn't in the slot
    	li $v0, 0 # initialize counter
    	li $t8, '.' # used later
	addi $s0, $s0, 8 # put to start of array
	mul $t0, $s1, $s5  # i * # col
	add $t0, $t0, $s2 # + j
	add $s0, $s0, $t0 # base addr + ____, $s0 is now at the desired spot
	# Any of the following conditions must check if it's already checked. 
	# Because it is possible that a 1 is overridden to a 0 if a different condition doesn't match.
	# To remedy this, I skip if it's already checked past the first one.
	# If it's too far up. # $s1 is target row, $s2 is target col, # $t0 = skip_NE, $t1 = skip_SE, $t2 = skip_SW, $t3 = skip_NW
	li $t9, 3 # to be used here -v
	slt $t3, $s1, $t9 # if desired row is < 3, $t0 is flagged. $t0 = skip_NW
	slt $t0, $s1, $t9 # if the row is < 3 it also can skip_NE
	# If it's too far left
	beq $t3, 1, skip_here0
	slt $t3, $s2, $t9 # if desired col < 3, flag skip_NW
	skip_here0:
	slt $t2, $s2, $t9 # if col < 3, can also skip_SW
	# If it's too far right, # s4 is num rows # s5 is num cols
	addi $t9, $s5, -3 # # cols - 3
	beq $t0, 1, skip_here1
	sge $t0, $s2, $t9 # if col > #col-3, theres no room for a 4th so skip_NE
	skip_here1:
	sge $t1, $s2, $t9 # also if its too far right, skip_SE 
	# if it's too far down
	addi $t9, $s4, -3 # # rows-3
	beq $t1, 1, skip_here2
	sge $t1, $s1, $t9 # too low, skip_SE
	skip_here2:
	beq $t2, 1, skip_here3
	sge $t2, $s1, $t9 # too low, skip_SW
	skip_here3:
check_NE: # $t0 - $t3 reserved, $t4 for checking byte
	bnez $t0, skip_NE
	addi $t9, $s5, -1 # $t9 is now " #col-1" which is the location of the top right from current position when subtracted
	sub $t5, $s0, $t9  # $t4 is top right
	lbu $t4, 0($t5) # check whats there
	bne $t4, $s6, skip_NE # if its not enemy, go skip
	sub $t6, $t5, $t9 # top right from $t5
	lbu $t4, 0($t6)
	bne $t4, $s6, skip_NE # if its not enemy
	sub $t7, $t6, $t9
	lbu $t4, 0($t7)
	bne $t4, $s3, skip_NE # if it's not player, go skip, if it passes this its a capture
	sb $t8, 0($t5)
	sb $t8, 0($t6) # replace captured ones with '.' in $t8
	addi $v0, $v0, 2 # add 2 to amount captured
skip_NE:
check_SE:
	bnez $t1, skip_SE
	addi $t9, $s5, 1 # $t9 is now " #col+1" which is the location of the bottom right from current position when added
	add $t5, $s0, $t9  # $t4 is bottom right
	lbu $t4, 0($t5) # check whats there
	bne $t4, $s6, skip_SE # if its not enemy, go skip
	add $t6, $t5, $t9 # bottom right from $t5
	lbu $t4, 0($t6)
	bne $t4, $s6, skip_SE # if its not enemy
	add $t7, $t6, $t9
	lbu $t4, 0($t7)
	bne $t4, $s3, skip_SE # if it's not player, go skip, if it passes this its a capture
	sb $t8, 0($t5)
	sb $t8, 0($t6) # replace captured ones with '.' in $t8
	addi $v0, $v0, 2 # add 2 to amount captured
skip_SE:
check_SW:
	bnez $t2, skip_SW
	addi $t9, $s5, -1 # $t9 is now " #col-1" which is the location of the bottom left from current position when added
	add $t5, $s0, $t9  # $t4 is bottom left
	lbu $t4, 0($t5) # check whats there
	bne $t4, $s6, skip_SW # if its not enemy, go skip
	add $t6, $t5, $t9 # bottom left from $t5
	lbu $t4, 0($t6)
	bne $t4, $s6, skip_SW # if its not enemy
	add $t7, $t6, $t9
	lbu $t4, 0($t7)
	bne $t4, $s3, skip_SW # if it's not player, go skip, if it passes this its a capture
	sb $t8, 0($t5)
	sb $t8, 0($t6) # replace captured ones with '.' in $t8
	addi $v0, $v0, 2 # add 2 to amount captured
skip_SW:
check_NW:
	bnez $t3, skip_NW
	addi $t9, $s5, 1 # $t9 is now " #col+1" which is the location of the top left from current position when subtracted
	sub $t5, $s0, $t9  # $t4 is top left
	lbu $t4, 0($t5) # check whats there
	bne $t4, $s6, skip_NW # if its not enemy, go skip
	sub $t6, $t5, $t9 # top lef from $t5
	lbu $t4, 0($t6)
	bne $t4, $s6, skip_NW # if its not enemy
	sub $t7, $t6, $t9
	lbu $t4, 0($t7)
	bne $t4, $s3, skip_NW # if it's not player, go skip, if it passes this its a capture
	sb $t8, 0($t5)
	sb $t8, 0($t6) # replace captured ones with '.' in $t8
	addi $v0, $v0, 2 # add 2 to amount captured
skip_NW:
	j end_diag_check

invalid_during_diag_check:
	li $v0, -1
	j end_diag_check
end_diag_check:
	lw $ra, 0($sp)
	lw $s0, 4($sp)
	lw $s1, 8($sp)
	lw $s2, 12($sp)
	lw $s3, 16($sp)
	lw $s4, 20($sp)
	lw $s5, 24($sp)
	lw $s6, 28($sp)
    	addi $sp, $sp, 32
    	jr $ra
check_horizontal_winner:
	addi $sp, $sp, -36
	sw $ra, 0($sp)
	sw $s0, 4($sp)
	sw $s1, 8($sp)
	sw $s2, 12($sp)
	sw $s3, 16($sp)
	sw $s4, 20($sp)
	sw $s5, 24($sp)
	sw $s6, 28($sp)
	sw $s7, 32($sp)
	move $s0, $a0 # s0 is the board
	move $s1, $a1 # s1 is the player
	beq $s1, 'X', passed1
	beq $s1, 'O', passed1
	j no_row_win_found # if it gets here, the player is an invalid character
passed1:
	lw $s2, 0($s0) # num rows, not needed
	lw $s3, 4($s0) # num col
	mul $s2, $s2, $s3 # $s3 is the number of slots
	li $s5, 0 # counter of number of X or O in a row
	li $s6, 0 # rows traversed
	li $s7, 0 # column for when found
row_win_checker_loop: # t5 is the checker
	beq $s5, 5, row_win_found
	beq $s7, $s3, go_next_row
	beq $s2, 0, no_row_win_found
	move $a0, $s0
	move $a1, $s6 # current row
	move $a2, $s7 # current column
	jal get_slot
	addi $s7, $s7, 1 # increase column index
	addi $s2, $s2, -1 # decrement the total amount of iterations left
	bne $v0, $s1, not_playerSlot
	addi $s5, $s5, 1 # otherwise it is the playerSlot so increment this
	j row_win_checker_loop
not_playerSlot:
	li $s5, 0 # reset number found in a row
	j row_win_checker_loop
go_next_row:
	li $s5, 0
	addi $s6, $s6, 1 # increase the row that your on, this is a must know for the formula
	li $s7, 0
	j row_win_checker_loop
row_win_found:
	move $v0, $s6
	addi $v1, $s7, -5 # column of the 5th found - 5 = column of the 1st of the 5th
	j end_row_check
no_row_win_found: # no win found
	li $v0, -1
	li $v1, -1
	j end_row_check
end_row_check:
	lw $ra, 0($sp)
	lw $s0, 4($sp)
	lw $s1, 8($sp)
	lw $s2, 12($sp)
	lw $s3, 16($sp)
	lw $s4, 20($sp)
	lw $s5, 24($sp)
	lw $s6, 28($sp)
	lw $s7, 32($sp)
	addi $sp, $sp, 36
    	jr $ra

check_vertical_winner:
	addi $sp, $sp, -36
	sw $ra, 0($sp)
	sw $s0, 4($sp)
	sw $s1, 8($sp)
	sw $s2, 12($sp)
	sw $s3, 16($sp)
	sw $s4, 20($sp)
	sw $s5, 24($sp)
	sw $s6, 28($sp)
	sw $s7, 32($sp)
	move $s0, $a0 # a0 is board
	move $s1, $a1 # a1 is player X or O
	beq $s1, 'X', passed2
	beq $s1, 'O', passed2
	j no_vert_win_found # if it gets here, the player is an invalid character
passed2:
	lw $s2, 0($s0) # num rows
	lw $s3, 4($s0) # num col
	mul $s3, $s2, $s3 # $s3 is the number of slots
	li $s5, 0 # counter of number of X or O in a col
	li $s6, 0 # rows traversed
	li $s7, 0 # column traversed
vert_win_checker_loop:
	beq $s3, 0, no_vert_win_found
	beq $s5, 5, vert_win_found
	beq $s6, $s2, go_next_col
	move $a0, $s0
	move $a1, $s6 # current row
	move $a2, $s7 # current column
	jal get_slot
	addi $s6, $s6, 1 # increase row index
	addi $s3, $s3, -1 # decrement the total amount of iterations left
	bne $v0, $s1, not_playerSlot2
	addi $s5, $s5, 1 # otherwise it is the playerSlot so increment this
	j vert_win_checker_loop
not_playerSlot2:
	li $s5, 0 # reset number found in a row
	j vert_win_checker_loop
go_next_col:
	li $s5, 0 # reset count
	addi $s7, $s7, 1 # increase the col that your on, this is a must know for the formula
	li $s6, 0 # reset row# to 0
	j vert_win_checker_loop
no_vert_win_found:
	li $v0, -1
	li $v1, -1
	j end_vert_check
vert_win_found:
	addi $v0, $s6, -5 # 5 up from the row last one was found in
	move $v1, $s7
	j end_vert_check
end_vert_check:	
	lw $ra, 0($sp)
	lw $s0, 4($sp)
	lw $s1, 8($sp)
	lw $s2, 12($sp)
	lw $s3, 16($sp)
	lw $s4, 20($sp)
	lw $s5, 24($sp)
	lw $s6, 28($sp)
	lw $s7, 32($sp)
	addi $sp, $sp, 36
	jr $ra
check_sw_ne_diagonal_winner:
	addi $sp, $sp, -36
	sw $ra, 0($sp)
	sw $s0, 4($sp)
	sw $s1, 8($sp)
	sw $s2, 12($sp)
	sw $s3, 16($sp)
	sw $s4, 20($sp)
	sw $s5, 24($sp)
	sw $s6, 28($sp)
	sw $s7, 32($sp)
	move $s0, $a0 # a0 is board
	move $s1, $a1 # a1 is player X or O
	beq $s1, 'X', passed3
	beq $s1, 'O', passed3
	j no_sw_ne_win_found # if it gets here, the player is an invalid character
passed3:
	lw $s2, 0($s0) # num rows
	lw $s3, 4($s0) # num col
	mul $s7, $s2, $s3 # $s2 is the number of slots
	li $s4, 0 # current row
	li $s5, 0 # current col
	li $s6, 0 # # of consecutive X or O 
sw_ne_win_check_loop:
	beq $s7, 0, no_sw_ne_win_found # make sure this is the exact correct amount (70 times for 70 spots)
	beq $s6, 5, sw_ne_win_found # 5 found, I think this won't happen
	beq $s5, $s3, go_next_row1 # current col = max col
	addi $t0, $s2, -5 # if it's greater than 5 less than the max, it doesn't even have room to win downward
	bgt $s4, $t0, skip_cant_win # no room downward to win
	blt $s5, 4, skip_cant_win # no room leftward to win
real_sw_ne_check: # it's POSSIBLE that this one can win
	addi $sp, $sp, -12
	sb $s4, 0($sp) # save original row
	sb $s5, 4($sp) # save original col
	sb $s3, 8($sp) # i need another variable
real_sw_ne_check_loop:
	move $a0, $s0
	move $a1, $s4 # row
	move $a2, $s5 # col
	jal get_slot
	bne $v0, $s1, real_sw_ne_check_loop_FAILED
	addi $s6, $s6, 1
	li $t0, 5
	sge $s3, $s6, $t0
	#beq $s6, 5, real_sw_ne_check_loop_PASSED
	addi $s4, $s4, 1 # increase row by 1                    O  X*
	addi $s5, $s5, -1 # decrease column by 1 means          X* O
	j real_sw_ne_check_loop
real_sw_ne_check_loop_FAILED:
	beq $s3, 1, real_sw_ne_check_loop_PASSED # the saving grace, this is for 6 pattern wins
	lb $s4, 0($sp) # save original row
	lb $s5, 4($sp) # save original col
	lb $s3, 8($sp)
	addi $sp, $sp, 12
	addi $s5, $s5, 1 # move along the process
	li $s6, 0 # reset consecutive counter
	j sw_ne_win_check_loop
real_sw_ne_check_loop_PASSED:
	addi $s4, $s4, -1 # compensation bc the last one is actually wrong
	addi $s5, $s5 ,1
	move $v0, $s4
	move $v1, $s5 # move the starting one which caused a win back
	lb $s4, 0($sp) # save original row
	lb $s5, 4($sp) # save original col
	lb $s3, 8($sp)
	addi $sp, $sp, 12
	j sw_ne_win_found
skip_cant_win:
	addi $s5, $s5, 1 # increment # of cols
	addi $s7, $s7, -1 # decrement number needed 
	j sw_ne_win_check_loop
go_next_row1:
	li $s6, 0 # reset count
	li $s5, 0 # set current column to 0
	addi $s4, $s4, 1 # increment row we're on
	j sw_ne_win_check_loop
sw_ne_win_found: # needs more
	j end_sw_ne_diagonal_check 
no_sw_ne_win_found:
	li $v0, -1
	li $v1, -1
	j end_sw_ne_diagonal_check	
end_sw_ne_diagonal_check:
	lw $ra, 0($sp)
	lw $s0, 4($sp)
	lw $s1, 8($sp)
	lw $s2, 12($sp)
	lw $s3, 16($sp)
	lw $s4, 20($sp)
	lw $s5, 24($sp)
	lw $s6, 28($sp)
	lw $s7, 32($sp)
	addi $sp, $sp, 36
    	jr $ra

check_nw_se_diagonal_winner:
    	addi $sp, $sp, -36
	sw $ra, 0($sp)
	sw $s0, 4($sp)
	sw $s1, 8($sp)
	sw $s2, 12($sp)
	sw $s3, 16($sp)
	sw $s4, 20($sp)
	sw $s5, 24($sp)
	sw $s6, 28($sp)
	sw $s7, 32($sp)
	move $s0, $a0 # a0 is board
	move $s1, $a1 # a1 is player X or O
	beq $s1, 'X', passed4
	beq $s1, 'O', passed4
	j no_nw_se_win_found # if it gets here, the player is an invalid character
passed4:
	lw $s2, 0($s0) # num rows
	lw $s3, 4($s0) # num col
	mul $s7, $s2, $s3 # $s2 is the number of slots
	li $s4, 0 # current row
	li $s5, 0 # current col
	li $s6, 0 # # of consecutive X or O 
nw_se_win_check_loop:
	beq $s7, 0, no_nw_se_win_found # make sure this is the exact correct amount (70 times for 70 spots)
	beq $s6, 5, nw_se_win_found # 5 found, I think this won't happen
	beq $s5, $s3, go_next_row2 # current col = max col
	addi $t0, $s3, -5 # if it's greater than 5 less than the max cols, it doesn't even have room to win rightward
	bgt $s5, $t0, skip_cant_win1 # no room rightward to win
	addi $t0, $s2, -5 # # rows-5
	bgt $s4, $t0, skip_cant_win1 # no room downward to win
real_nw_se_check: # it's POSSIBLE that this one can win
	addi $sp, $sp, -12
	sb $s4, 0($sp) # save original row
	sb $s5, 4($sp) # save original col
	sb $s3, 8($sp) # i need another variable
real_nw_se_check_loop:
	move $a0, $s0
	move $a1, $s4 # row
	move $a2, $s5 # col
	jal get_slot
	bne $v0, $s1, real_nw_se_check_loop_FAILED
	addi $s6, $s6, 1
	li $t0, 5
	sge $s3, $s6, $t0
	#beq $s6, 5, real_sw_ne_check_loop_PASSED
	addi $s4, $s4, 1 # increase row by 1                    O*  X
	addi $s5, $s5, 1 # decrease column by 1 means          X   O* 
	j real_nw_se_check_loop
real_nw_se_check_loop_FAILED:
	beq $s3, 1, real_nw_se_check_loop_PASSED # the saving grace, this is for 6 pattern wins
	lb $s4, 0($sp) # save original row
	lb $s5, 4($sp) # save original col
	lb $s3, 8($sp)
	addi $sp, $sp, 12
	addi $s5, $s5, 1 # move along the process
	li $s6, 0 # reset consecutive counter
	j nw_se_win_check_loop
real_nw_se_check_loop_PASSED:
	lb $s4, 0($sp) # save original row
	lb $s5, 4($sp) # save original col
	lb $s3, 8($sp)
	addi $sp, $sp, 12
	move $v0, $s4
	move $v1, $s5 # move the starting one which caused a win back
	j sw_ne_win_found
skip_cant_win1:
	addi $s5, $s5, 1 # increment # of cols
	addi $s7, $s7, -1 # decrement number needed 
	j nw_se_win_check_loop
go_next_row2:
	li $s6, 0 # reset count
	li $s5, 0 # set current column to 0
	addi $s4, $s4, 1 # increment row we're on
	j nw_se_win_check_loop
nw_se_win_found: # needs more
	j end_nw_se_diagonal_check 
no_nw_se_win_found:
	li $v0, -1
	li $v1, -1
	j end_nw_se_diagonal_check	
end_nw_se_diagonal_check:
	lw $ra, 0($sp)
	lw $s0, 4($sp)
	lw $s1, 8($sp)
	lw $s2, 12($sp)
	lw $s3, 16($sp)
	lw $s4, 20($sp)
	lw $s5, 24($sp)
	lw $s6, 28($sp)
	lw $s7, 32($sp)
	addi $sp, $sp, 36
    	jr $ra
simulate_game:
	addi $sp, $sp, -36
	sw $ra, 0($sp)
	sw $s0, 4($sp)
	sw $s1, 8($sp)
	sw $s2, 12($sp)
	sw $s3, 16($sp)
	sw $s4, 20($sp)
	sw $s5, 24($sp)
	sw $s6, 28($sp)
	sw $s7, 32($sp)
	move $s0, $a0 # board
	move $s1, $a1 # file name
	move $s2, $a2 # a null terminated string representing turns
	move $s3, $a3 # max num of turns to simulate
	jal load_board
	beq $v0, -1, cannot_load_file
	move $a0, $s2
	jal strlen # len strlen(str)
	li $t0, 5
	div $v0, $t0
	mflo $s4 # $s4 is len(str) / 5, aka turns_length
	li $s5, 0 # number of turns actually played so far
	li $s6, 0 # number of turns ATTEMPTED to play
	# s3 is num_turns__to_play
	li $s7, 0 # GAME OVER? 0 for FALSE 1 for TRUE
pseudo_loop:
	beq $s7, 1, end_game #  the conditions
	bge $s5, $s3, max_turns_simulated
	bge $s6, $s4, out_of_turns
	addi $s6, $s6, 1 # a turn will be attempted to be played
	li $t1, 0 # to be desired row
	li $t2, 0 # to be desired col
	lb $t0, 0($s2) # loads character
	beq $t0, 'X', passed5
	beq $t0, 'O', passed5
	j invalid_player_found
passed5: # valid player
	lb $t9, 1($s2) # loads desired row 1st digit
	addi $t9, $t9, -48 # str digit -> digit
	li $t8, 10
	mul $t1, $t9, $t8
	lb $t9, 2($s2) # loads desired row 2nd digit
	addi $t9, $t9, -48
	add $t1, $t1, $t9 # puts it into t1
	lb $t9, 3($s2) # loads desired col 1st digit
	addi $t9, $t9, -48 # str digit -> digit
	mul $t2, $t9, $t8
	lb $t9, 4($s2) # loads desired col 2nd digit
	addi $t9, $t9, -48
	add $t2, $t2, $t9 # puts it into t2
	lw $t4, 0($s0) # if the row or column desired is not in range
	bge $t1, $t4, slot_invalid
	lw $t4, 4($s0)
	bge $t2, $t4, slot_invalid
	addi $sp, $sp, -12 # I NEED SPACE
	sw $t1, 0($sp) # row
	sw $t2, 4($sp) # col
	sw $t0, 8($sp)  # player
	move $a0, $s0
	move $a1, $t1
	move $a2, $t2
	move $a3, $t0
	jal place_piece
	beq $v0, -1, cant_place_piece
	addi $s5, $s5, 1 # increase amount of turns REALLY played
	# Load all necessary variables back
	lw $t1, 0($sp)
	lw $t2, 4($sp)
	lw $t0, 8($sp)
	move $a0, $s0
	move $a1, $t1
	move $a2, $t2
	move $a3, $t0
	jal check_horizontal_capture
	# Load all necessary variables back
	lw $t1, 0($sp)
	lw $t2, 4($sp)
	lw $t0, 8($sp)
	move $a0, $s0
	move $a1, $t1
	move $a2, $t2
	move $a3, $t0
	jal check_vertical_capture
	# Load all necessary variables back
	lw $t1, 0($sp)
	lw $t2, 4($sp)
	lw $t0, 8($sp)
	move $a0, $s0
	move $a1, $t1
	move $a2, $t2
	move $a3, $t0
	jal check_diagonal_capture
	# Load board and player
	lw $t0, 8($sp)
	move $a0, $s0
	move $a1, $t0
	jal check_horizontal_winner
	beq $s7, 1, skip123
	sge $s7, $v0, $0
	lw $t0, 8($sp)
	move $a0, $s0
	move $a1, $t0
	jal check_vertical_winner
	beq $s7, 1, skip123
	sge $s7, $v0, $0
	lw $t0, 8($sp)
	move $a0, $s0
	move $a1, $t0
	jal check_sw_ne_diagonal_winner
	beq $s7, 1, skip123
	sge $s7, $v0, $0
	lw $t0, 8($sp)
	move $a0, $s0
	move $a1, $t0
	jal check_nw_se_diagonal_winner
	beq $s7, 1, skip123
	sge $s7, $v0, $0
skip123:
cant_place_piece:
	lw $t1, 0($sp) # row
	lw $t2, 4($sp) # col
	lw $t0, 8($sp)  # player
	addi $sp, $sp, 12
	move $a0, $s0 # puts board into $a0
	jal game_status
	add $t0, $v0, $v1 # adds # of Xs and Os
	lw $t1, 0($s0)
	lw $t2, 4($s0)
	mul $t1, $t1, $t2 # $t1 is # of slots in the board
	beq $t0, $t1, game_tie
	addi $s2, $s2, 5 # move along the process
	j pseudo_loop
out_of_turns:
max_turns_simulated:
	move $v0, $s5
	li $v1, -1
	j end_simulation
end_game:
	move $v0, $s5
	lbu $t0, -5($s2) # the character of the most prev loop
	move $v1, $t0
	j end_simulation
slot_invalid:	
	addi $s2, $s2, 5 # move along the process to next turn
	j pseudo_loop
invalid_player_found:
	addi $s2, $s2, 5 # move along the process to next turn
	j pseudo_loop
cannot_load_file:
	li $v0, 0
	li $v1, -1
	j end_simulation
game_tie:
	move $v0, $s5
	li $v1, -1 # nobody won, 0
	j end_simulation
end_simulation:
	lw $ra, 0($sp)
	lw $s0, 4($sp)
	lw $s1, 8($sp)
	lw $s2, 12($sp)
	lw $s3, 16($sp)
	lw $s4, 20($sp)
	lw $s5, 24($sp)
	lw $s6, 28($sp)
	lw $s7, 32($sp)
	addi $sp, $sp, 36	
    	jr $ra
strlen: # int strlen (string str), helper function
	li $v0, 0 # intialize the counter
	addi $sp, $sp, -4
	sw $a0, 0($sp)
	strlen.loop:
	lbu $t0, 0($a0) # loads character from $a0
	beq $t0, $0, strlen.finished # return if its the null terminator
	addi $a0, $a0, 1 # increments to next spot
	addi $v0,$v0, 1 #increments the counter
	j strlen.loop # loop
strlen.finished:
	lw $a0, 0($sp)
	addi $sp, $sp, 4
    	jr $ra

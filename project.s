#####################################################################################
#
# project.s
#
# Author: Ryan Chiang
# Date: 04/15/2023
#
# Description:
# 	This program is the final project for the class. 
# 	This represents the "eliminate-invaders" game.
#	Russians have invaded Ukraine.
#	A total of 8 invaders are scattered across the screen.
#	'PT' stands for Putin. 'Z', 'theta', and 'stars' as Russian invaders. 
#	You start off at the top left corner as a 'hammer'.
#	At the bottom right of the screen is a comrade of yours that you are to safe.
#	You eliminate the enemies and safe your friend by simply going over the symbols.
#	You are to work your way around the map and eliminate ALL invaders
#	before you can safe your friend. In other words, going to your friend
#	prior to all enemies are eliminated will not work.
#	As an enemy is eliminated, a tomb stone with a cross will be placesd at the location.
#	The seven-segment will display the current number of invaders you have eliminated.
#	The LEDs will lit up as you successfully save your comrade.
#	The game is restarted upon a BTNC press or when you have saved your comrade.
#	You can control movement by pressing the four directional buttons.
#	
#	Number of instructions used: 142
#	Number of additional fonts created and used: 7 
#
# Memory Organization:
#   0x0000-0x1fff : text
#   0x2000-0x3fff : data
#   0x7f00-0x7fff : I/O
#   0x8000-0xbfff : VGA
#
# The stack will operate in the data segment and thus starts at 0x3ffc 
# and works its way down.
#
# Registers:
#  x1(ra):  Return address
#  x2(sp):  Stack Pointer
#  x3(gp):  Data segment pointer
#  x4(tp):  I/O base address
#  x8(s0):  VGA base address
#
######################################################################################
.globl  main

.text

# I/O address offset constants
    .eqv LED_OFFSET 0x0
    .eqv SWITCH_OFFSET 0x4
    .eqv SEVENSEG_OFFSET 0x18
    .eqv BUTTON_OFFSET 0x24
    .eqv CHAR_COLOR_OFFSET 0x34
    .eqv TIMER 0x30

# I/O mask constants
    .eqv BUTTON_C_MASK 0x01
    .eqv BUTTON_L_MASK 0x02
    .eqv BUTTON_D_MASK 0x04
    .eqv BUTTON_R_MASK 0x08
    .eqv BUTTON_U_MASK 0x10

# Game specific constants
	.eqv CHAR_WEIRD_STAR 0x41				# 'weird_star' character
	.eqv CHAR_PUTIN 0x42					# 'putin' character
	.eqv CHAR_THETA 0x43					# 'theta' character
	.eqv CHAR_STROKE_Z 0x44					# 'stroke_z' character
	.eqv CHAR_HANGMAN 0x45					# 'hangman' character
	.eqv CHAR_HAMMER 0x5A					# 'hammer' character
	.eqv CHAR_WEIRD_STAR_COLOR 0xff0f0041	# 'weird_star' character with red foreground, cyan background
	.eqv CHAR_PUTIN_COLOR 0x00ff0042		# 'putin' character with red foreground, cyan background
	.eqv CHAR_THETA_COLOR 0xff0f0043		# 'theta' character with red foreground, cyan background
	.eqv CHAR_STROKE_Z_COLOR 0x00ff0044		# 'stroke_z' character with red foreground, cyan background
	.eqv CHAR_HANGMAN_COLOR 0x0f0fff45		# 'hangman' character with white foreground, green background
	.eqv CHAR_HAMMER_COLOR 0xfff0005A		# 'hammer' character with magenta foreground, green background
	.eqv CHAR_CROSS_COLOR 0x000fff46		# 'cross' character with white foreground, black background
	
	.eqv INVADER_LOC_1 0xa8f0				# The VGA memory address where the one of the 'invader' characters is located.
											# 60, 20 or 0x8000+60*4+20*512=0xa8f0
	.eqv INVADER_LOC_2 0xb0b4				# The VGA memory address where the one of the 'invader' characters is located. 
											# 45, 24 or 0x8000+45*4+24*512=0xb0b4
	.eqv INVADER_LOC_3 0xa078				# The VGA memory address where the one of the 'invader' characters is located. 
											# 30, 16 or 0x8000+30*4+16*512=0xa078
	.eqv INVADER_LOC_4 0x983c				# The VGA memory address where the one of the 'invader' characters is located. 
											# 15, 12 or 0x8000+15*4+12*512=0x983c
	.eqv INVADER_LOC_5 0x912c				# The VGA memory address where the one of the 'invader' characters is located. 
											# 75, 08 or 0x8000+60*4+20*512=0x912c
	.eqv INVADER_LOC_6 0x8828				# The VGA memory address where the one of the 'invader' characters is located. 
											# 10, 04 or 0x8000+45*4+24*512=0x8828
	.eqv INVADER_LOC_7 0xb850				# The VGA memory address where the one of the 'invader' characters is located. 
											# 20, 28 or 0x8000+30*4+16*512=0xb850
	.eqv INVADER_LOC_8 0x8cc8				# The VGA memory address where the one of the 'invader' characters is located. 
											# 50, 06 or 0x8000+15*4+12*512=0x8cc8
													
	.eqv INVADER_COUNT 0x8					# The total number of invaders
    .eqv COLUMN_MASK 0x1fc              	# Mask for the bits in the VGA address for the column
    .eqv COLUMN_SHIFT 2                 	# Number of right shifts to determine VGA column
    .eqv ROW_MASK 0x3e00                	# Mask for the bits in the VGA address for the row
    .eqv ROW_SHIFT 9                    	# Number of right shifts to determine VGA row
    .eqv LAST_COLUMN 79                		# last column on screen
    .eqv LAST_ROW 31                    	# last row on screen
    .eqv ADDRESSES_PER_ROW 512				# number of addresses per row
    .eqv NEG_ADDRESSES_PER_ROW -512			# negative number of addresses per row
    .eqv STARTING_LOCATION 0x8204           # The VGA memory address wher ethe 'starting' character is located. 1,2 or 0x8000+1*4+2*512=0x8204
    .eqv HANGMAN_LOCATION 0xb700            # The VGA memory address where the 'ending character' is located.   64, 27 or 0x8000+64*4+27*512=0xb700


	
    # The purpose of this initial section is to setup the global registers that will be used for the entire program execution.
    # This setup portion will onlybe run once.
main:

    li sp, 0x3ffc							# Setup the stack pointer: sp = 0x3ffc
    lui gp, 2								# setup the global pointer to the data segment (2<<12 = 0x2000)
    li tp, 0x7f00							# Prepare I/O base address
    li s0, 0x8000							# Prepare VGA base address
    jal KILL_INVADERS_GAME					# Call main program procedure

    # End in infinite loop (should never get here)
END_MAIN:
    j END_MAIN


################################################################################
#
# KILL_INVADERS_GAME
#
#  This procedure contains the functionality of the game.
#
################################################################################
KILL_INVADERS_GAME:

    # Game initialization code that is only executed once.

    # setup stack frame and save return address
    addi sp, sp, -4	    				# Make room to save return address on stack
    sw ra, 0(sp)						# Put return address on stack

    # Initialize the default color (based on the value at the starting location)
    # The default color is needed for VGA memories that are not initialized with a default background.
    li t0, STARTING_LOCATION            # Address of starting location
    lw t1, 0(t0)                        # Read value at this address
    
    srli t1, t1, 8						# Shift right logical 8 bits (to bring the foreground and background for use by color offset)
    sw t1, CHAR_COLOR_OFFSET(tp)    	# Write the new color values
    
    sw x0, SEVENSEG_OFFSET(tp)			# Initialize the seven segment display with the default value (0x0000)
    sw x0, LED_OFFSET(tp)				# Initialize the seven segment display with the default value (0x0000)

    # This occurs when we want to prepare for another game.
    # We get here at power up, after a finished game, and after exiting a game with BTNC.
MCG_RESTART:
    addi t6, x0, 0						# reset killed-enemies counter
	addi s5, x0, 0						# reset first enemy-killed flag 
	addi s4, x0, 0						# reset second enemy-killed flag
    
    # Display all invader characters throughout the map
    li t0, INVADER_LOC_1
    li t1, CHAR_WEIRD_STAR_COLOR
    sw t1, 0(t0)
    li t0, INVADER_LOC_2
    li t1, CHAR_WEIRD_STAR_COLOR
    sw t1, 0(t0)
    li t0, INVADER_LOC_3
    li t1, CHAR_THETA_COLOR
    sw t1, 0(t0)
    li t0, INVADER_LOC_4
    li t1, CHAR_STROKE_Z_COLOR
    sw t1, 0(t0)
    li t0, INVADER_LOC_5
    li t1, CHAR_PUTIN_COLOR
    sw t1, 0(t0)
    li t0, INVADER_LOC_6
    li t1, CHAR_PUTIN_COLOR
    sw t1, 0(t0)
    li t0, INVADER_LOC_7
    li t1, CHAR_THETA_COLOR
    sw t1, 0(t0)
    li t0, INVADER_LOC_8
    li t1, CHAR_STROKE_Z_COLOR
    sw t1, 0(t0)

    lw t0, %lo(ENDING_CHARACTER)(gp)        # Load ending character to write
    lw t1, %lo(ENDING_CHARACTER_LOC)(gp)    # Load address of ending character location
    sw t0, 0(t1)							# Write ending character to the location

    li a0, STARTING_LOCATION				# Load starting location to a0
    jal MOVE_CHARACTER						# Go to MOVE_CHARACTER

    # Make sure no buttons are being pressed before looking for button to start game
    # (a previous button press to end the game or reset the game could lead to this
    #  code entry. Need to wait until this button press is let go before proceeding).
MCG_NO_BUTTON_START:
    lw t0, BUTTON_OFFSET(tp)
    bne t0, x0, MCG_NO_BUTTON_START 

    # Wait for a new button press to start the game
MCG_BUTTON_START:
    lw t0, BUTTON_OFFSET(tp)
    beq t0, x0, MCG_BUTTON_START 

    # A button has been pressed to start the game (t0)
    mv a0, t0								# Copy button press value
    sw x0, SEVENSEG_OFFSET(tp)				# Clear seven segment display
    sw x0, LED_OFFSET(tp)					# Clear LEDs
    	
    # At this point a button has been pressed and its value is in a0
MCG_PROC_BUTTONS:
    li t0, BUTTON_C_MASK					# Mask the button press with BTNC_MASK
    beq t0, a0, MCG_END_GAME_EARLY			# BTNC pressed, end game early

    jal UPDATE_CHAR_ADDR            		# BTNC not pressed, process other button. Returns new address in a0

    
    jal MOVE_CHARACTER						# Move the character (a0 has new address)
    
    # See if the new location is the end location
    lw t1, %lo(ENDING_CHARACTER_LOC)(gp)   	# Load address of end location
    bne t1, a0, MCG_CONTINUE				# Continue the game if we are not at end location
    addi t0, x0, INVADER_COUNT				# Load invader counter
    beq t6, t0, MCG_GAME_ENDED				# All invaders are cleared, game ends

    # Continue playing game
MCG_CONTINUE:
    # Wait for button release while updating the counter
    jal UPDATE_COUNTER
    lw t0, BUTTON_OFFSET(tp)
    bne x0, t0, MCG_CONTINUE

    # Now that the button has been released, wait for a new button while updating the counter
MCG_CONTINUE_BTN:
    jal UPDATE_COUNTER
    lw t0, BUTTON_OFFSET(tp)
    beq x0, t0, MCG_CONTINUE_BTN
    mv a0, t0               	# copy button value to a0
    j MCG_PROC_BUTTONS			# Go on to processing button presses

	# Game is over
MCG_GAME_ENDED:
    li t0, 0xffff				# Load values to later turn on LEDs
    sw t0, LED_OFFSET(tp)		# Turn on all LEDs
    j MCG_RESTART				# Restart the game

	# Game ended early
MCG_END_GAME_EARLY:
    sw x0, SEVENSEG_OFFSET(tp)	# When btnc is pressed, write a 0x0000 to Seven segment display
    sw x0, LED_OFFSET(tp)		# Initialize the LEDs with 0 
    jal MOVE_CHARACTER			# Move the current character to the start location
    j MCG_RESTART				# Restart game

    # Should never get here. Will play game indefinitely. This is exit game procedure.
MCG_EXIT:   
    # Restore stack
    lw ra, 0(sp)				# Restore return address
    addi sp, sp, 4				# Update stack pointer
    ret                 		# same as jalr x0, ra, 0


################################################################################
# UPDATE_CHAR_ADDR
#
#  This procedure will read the current location of the character and update
#  the address of the character based on the a0 parameter. The parameter is
#  the value of the buttons and the updating will depend on whether up, down,
#  left, or right is pressed. The new address will be returned in a0.
#
#  a0: button values
#  t0, t1: temporaries
#  t2: address of character (to be updated)
#  t3: current column
#  t4: current row
#
#  returns in a0: New address of character location. If BTNC is pressed,
#                 return 0 indicating an early end to the game.
#
################################################################################
UPDATE_CHAR_ADDR:

    lw t2, %lo(DISPLACED_CHARACTER_LOC)(gp)   # Load address of current character to t2

    # Compute the current column (t3) and row (t4) from the current character address
    li t0, COLUMN_MASK
    and t3, t0, t2                  	# Mask bits in address of column 
    srli t3, t3, COLUMN_SHIFT       	# Shift down to get column number
    li t0, ROW_MASK
    and t4, t0, t2                  	# Mask bits in address of row 
    srli t4, t4, ROW_SHIFT         		# Shift down to get column number

	# check for BTNR press
UCA_CHECK_BTNR:
    li t0, BUTTON_R_MASK
    bne t0, a0, UCA_CHECK_BTNL
    # Move pointer right (if not in last column)
    li t1, LAST_COLUMN
    beq t3, t1, UCA_DONE            	# Last column, do nothing
    addi t2, t2, 4                  	# Increment pointer
    j UCA_DONE

	# check for BTNL press
UCA_CHECK_BTNL:
    li t0, BUTTON_L_MASK
    bne t0, a0, UCA_CHECK_BTND
    # Move Pointer left (if not in first column)
    beq x0, t3, UCA_DONE            	# Too far left, skip
    addi t2, t2, -4                 	# Decrement pointer
    j UCA_DONE

	# check for BTND press
UCA_CHECK_BTND:
    li t0, BUTTON_D_MASK
    bne t0, a0, UCA_CHECK_BTNU
    # Move pointer down
    li t1, LAST_ROW
    bge t4, t1, UCA_DONE            	# Too far down, skip
    addi t2, t2, ADDRESSES_PER_ROW  	# Increment pointer
    j UCA_DONE

	# check for BTNU press
UCA_CHECK_BTNU:
    li t0, BUTTON_U_MASK
    bne t0, a0, UCA_DONE            	# Exit - no buttons matched
    # Move pointer up
    beq x0, t4, UCA_DONE                # Too far up, skip
    addi t2, t2, NEG_ADDRESSES_PER_ROW  # Increment pointer

	# check complete
UCA_DONE:
    lw t0, 0(t2)						# Load the character at the new location. 
    andi t0, t0 0x7f					# Mask the bottom 7 bits (only the ASCII value, not its color)
    lw t1, %lo(FIRST_INVADER)(gp)		# Load the first invader character
    beq t0, t1, UCA_INVADER_DETECED		# See if character at new position is same as the first invader character. If so, go to INVADER_DETECED section
    lw t1, %lo(SECOND_INVADER)(gp)		# Load the second invader character
    beq t0, t1, UCA_INVADER_DETECED		# See if character at new position is same as the second invader character. If so, go to INVADER_DETECED section
    lw t1, %lo(THIRD_INVADER)(gp)		# Load the third invader character    
    beq t0, t1, UCA_INVADER_DETECED		# See if character at new position is same as the third invader character. If so, go to INVADER_DETECED section
    lw t1, %lo(FOURTH_INVADER)(gp)		# Load the fourth invader character
    beq t0, t1, UCA_INVADER_DETECED		# See if character at new position is same as the fourth invader character. If so, go to INVADER_DETECED section
    beq x0, x0, UCA_RET					# No invader at this location, continue to UCA_RET section

	# indicate that an invader is at this location
UCA_INVADER_DETECED:
	addi s5, x0, 1 						# set invader detected flag to high

	# complete process, return
UCA_RET:	
    mv a0, t2                       	# Return updated character address
    ret


################################################################################
# UPDATE_COUNTER
#
#  This procedure will check the timer and update the seven segment display.
#  If the timer has reached another tick value, increment the display.
#  This procedure will return the current timer value.
#
################################################################################
UPDATE_COUNTER:
	sw t6, SEVENSEG_OFFSET(tp)			# Update the seven segment display with the current counter value
    ret             					# jalr x0, ra, 0

################################################################################
#
# MOVE_CHARACTER
#
# Moves the character to the new location and erases the character from the
# previous location. This function doesn't check for valid addresses.
#
# a0: memory address of new location of moving character
#
# a0 is not changed (returns the memory address provided as parameter)
#
################################################################################
MOVE_CHARACTER:
    # setup stack frame and save return address
    addi sp, sp, -4	    # Make room to save return address on stack
    sw ra, 0(sp)		# Put return address on stack

    lw t3, %lo(DISPLACED_CHARACTER_LOC)(gp)	# Load the address of the old character that was previously replaced
    beq t3, x0, MC_SAVE_DISPLACED_CHAR		# If this address is zero, no need to restore character

    lw t2, %lo(DISPLACED_CHARACTER)(gp)		# Load the value of the character that was previously displaced
    sw t2, 0(t3)								# restore the character that was displaced
    
    beq s4, x0, MC_UPDATE_INVADER_FLAG		# check if the second invader detected flag is low

	# clear killed invader by writing a space at the location
MC_CLEAR_INVADER:	
    li t2, CHAR_CROSS_COLOR					# Load cross charater
    sw t2, 0(t3)								# display blank character at the location
	addi s4, x0, 0							# lower second flag
	addi t6, t6, 1							# add 1 to the enemy counter
	
	# update invader detected flag
MC_UPDATE_INVADER_FLAG:
	add s4, s5, x0							# copy first flag to second flag
	addi s5, x0, 0							# lower first flag
	
	# Save the address and value of the displaced character
MC_SAVE_DISPLACED_CHAR:    
    lw t1, 0(a0)								# Load the value of the character that is going to be displaced (so it can be restored later)
    addi t0, gp, %lo(DISPLACED_CHARACTER)		# Load address of the displaced character location
    sw t1,0(t0)									# Save the value of the displaced character
    addi t0, gp, %lo(DISPLACED_CHARACTER_LOC)	# temporarily store the address to t0
    sw a0, 0(t0)								# Save the address of the displaced character
    
	# Write moving character to its new location
MC_UPDATE_MOVING_CHAR_BLUE:     
    lw t0, %lo(MOVING_CHARACTER)(gp)		# Load the character value to write into the new location
    sw t0, 0(a0)							# Write the new character (overwriting the old character)

	# Done with moving character
MC_EXIT:
    lw ra, 0(sp)							# Restore return address
    addi sp, sp, 4							# Update stack pointer
    ret                 					# same as jalr x0, ra, 0

    # You should always add three 'nop' instructions at the end of your program to 
    # make sure your pipeline always has a valid instruction. You should never get here.
    nop
    nop
    nop

################################################################################
# Data segment
#
#   The data segment is used to store global variables that are accessible by
#   any of the procedures.
#
################################################################################
.data

# This location stores the ASCII value of the character that will move around the screen
MOVING_CHARACTER:
    .word CHAR_HAMMER_COLOR

# This stores the value of the character that has been overwritten by the moved character.
# It will be restored when the moving character moves off of its spot.
DISPLACED_CHARACTER:
    .word 0

# This stores the ASCII value of the character that represents the destination location
ENDING_CHARACTER:
    .word CHAR_HANGMAN_COLOR

# This stores the memory address of the moving character.
# It is initialized to zero so that the first call will not restore a character
DISPLACED_CHARACTER_LOC:
    .word 0

# This stores the memory address of the ending character location
ENDING_CHARACTER_LOC:
    .word HANGMAN_LOCATION
    
# This is the first invader
FIRST_INVADER:
	.word CHAR_WEIRD_STAR
	
# This is the second invader
SECOND_INVADER:
	.word CHAR_PUTIN
	
# This is the third invader
THIRD_INVADER:
	.word CHAR_THETA
	
# This is the fourth invader
FOURTH_INVADER:
	.word CHAR_STROKE_Z

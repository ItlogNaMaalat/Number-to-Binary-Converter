.data
menuText:       .asciiz "\nSMART CONVERTER AND BITWISE ANALYZER\n\n1. Convert Decimal to Binary\n2. Convert Binary to Decimal\n3. Count 1s and 0s in a Binary Number\n4. Perform Bit Shift (Left or Right)\n5. Exit\n\nEnter your choice (1-5): "
inputPrompt:    .asciiz "\nYour choice: "
invalidInput:   .asciiz "\nInvalid input!\n"
askDec:         .asciiz "\nEnter a positive decimal number: "
binaryMsg:      .asciiz "\nBinary representation: "
newline:        .asciiz "\n"
askBinary:      .asciiz "\nEnter a binary number (only 0 and 1): "
decResultMsg:   .asciiz "\nDecimal equivalent: "
onesMsg:       .asciiz "\nNumber of 1s: "
zerosMsg:      .asciiz "Number of 0s: "
shiftDirMsg:    .asciiz "\nEnter shift direction (L or R): "
shiftAmtMsg:    .asciiz "Enter how many times to shift: "
resultShiftMsg: .asciiz "\nResult after shift (decimal): "

buffer:         .space 10          # space for user input
binArray:       .space 32          # space for binary result (max 32 bits)

.text
.globl main

# ================================
# MAIN MENU LOOP
# ================================
main:
    # Show the main menu
    li $v0, 4
    la $a0, menuText
    syscall
    
    # Prints "Your choice:"
    li $v0, 4
    la $a0, inputPrompt
    syscall

    # Read input as string
    li $v0, 8
    la $a0, buffer
    li $a1, 10
    syscall

    # Convert input string to integer
    jal validate_and_convert
    move $t0, $v0      # $t0 now contains user's choice as integer

    # Validate choice (should be 1 to 5)
    li $t1, 1
    blt $t0, $t1, invalid_choice
    li $t1, 5
    bgt $t0, $t1, invalid_choice

    # Branch to correct function
    li $t1, 1
    beq $t0, $t1, dec_to_bin
    li $t1, 2
    beq $t0, $t1, bin_to_dec
    li $t1, 3
    beq $t0, $t1, count_bits
    li $t1, 4
    beq $t0, $t1, shift_bits
    li $t1, 5
    beq $t0, $t1, exit_program

invalid_choice:
    li $v0, 4
    la $a0, invalidInput
    syscall
    j main

# ================================
# validate_and_convert: converts string to int
# if invalid, jumps to invalid_choice
# ================================
validate_and_convert:
    la $t1, buffer     # pointer to input string
    li $v0, 0          # result = 0

validate_loop:
    lb $t2, 0($t1)     # get current char
    beq $t2, 10, done_validate   # newline
    beqz $t2, done_validate      # null terminator

    li $t3, 48         # ASCII '0'
    li $t4, 57         # ASCII '9'
    blt $t2, $t3, invalid_choice
    bgt $t2, $t4, invalid_choice

    sub $t2, $t2, $t3        # convert char to digit
    mul $v0, $v0, 10         # result *= 10
    add $v0, $v0, $t2        # result += digit

    addi $t1, $t1, 1         # next char
    j validate_loop

done_validate:
    jr $ra

# ================================
# Option 1: Convert Decimal to Binary
# ================================
dec_to_bin:
    li $v0, 4
    la $a0, askDec
    syscall

    # Read input as string (buffer reused)
    li $v0, 8
    la $a0, buffer
    li $a1, 10
    syscall

    # Convert and validate input
    jal validate_and_convert
    move $t0, $v0        # $t0 now has the validated number

    # Edge case: input = 0
    beqz $t0, print_zero

    # Start conversion
    la $t1, binArray      # pointer to binary storage

convert_loop:
    li $t2, 2
    div $t0, $t2
    mfhi $t3         # remainder
    mflo $t0         # quotient

    addi $t3, $t3, 48    # convert 0/1 to ASCII
    sb $t3, 0($t1)       # store character
    addi $t1, $t1, 1     # move pointer forward

    bnez $t0, convert_loop

    # Print binary result
    li $v0, 4
    la $a0, binaryMsg
    syscall

    la $t2, binArray
    move $t4, $t1      # $t4 = end pointer

print_loop:
    subi $t4, $t4, 1
    lb $a0, 0($t4)
    li $v0, 11         # print char
    syscall

    bge $t2, $t4, end_bin_print
    j print_loop

print_zero:
    li $v0, 4
    la $a0, binaryMsg
    syscall
    li $v0, 11
    li $a0, 48         # ASCII '0'
    syscall
    j end_bin_print

end_bin_print:
    li $v0, 4
    la $a0, newline
    syscall
    j main


# ================================
# Option 2: Convert Binary to Decimal
# ================================
bin_to_dec:
    li $v0, 4
    la $a0, newline
    syscall

    li $v0, 4
    la $a0, askBinary
    syscall

    # Read binary input as string into buffer
    li $v0, 8
    la $a0, buffer
    li $a1, 34          # Allow up to 32-bit binary
    syscall

    # Validate & convert binary to decimal
    la $t1, buffer
    li $t2, 0           # $t2 = result

bin_convert_loop:
    lb $t3, 0($t1)      # Load char
    beq $t3, 10, bin_done      # Newline
    beqz $t3, bin_done         # Null terminator

    # Check if char is '0' or '1'
    li $t4, 48   # '0'
    li $t5, 49   # '1'
    beq $t3, $t4, is_0
    beq $t3, $t5, is_1

    # If not 0 or 1 → invalid
    j invalid_choice

is_0:
    mul $t2, $t2, 2     # result × 2
    j next_bit

is_1:
    mul $t2, $t2, 2     # result × 2
    addi $t2, $t2, 1    # +1
    j next_bit

next_bit:
    addi $t1, $t1, 1    # move to next char
    j bin_convert_loop

bin_done:
    # Print result
    li $v0, 4
    la $a0, decResultMsg
    syscall

    move $a0, $t2
    li $v0, 1
    syscall

    li $v0, 4
    la $a0, newline
    syscall
    j main


# ================================
# Option 3: Count 1s and 0s in Binary
# ================================
count_bits:
    li $v0, 4
    la $a0, askBinary
    syscall

    # Read binary string input
    li $v0, 8
    la $a0, buffer
    li $a1, 34      # allow up to 32 bits + newline + null
    syscall

    la $t0, buffer  # pointer to input
    li $t2, 0       # $t2 = count of 1s
    li $t3, 0       # $t3 = count of 0s

count_loop:
    lb $t1, 0($t0)       # load character
    beqz $t1, count_done # null terminator
    beq $t1, 10, count_done # newline

    li $t4, 48           # ASCII '0'
    li $t5, 49           # ASCII '1'
    beq $t1, $t4, count_zero
    beq $t1, $t5, count_one

    # Invalid character (not 0 or 1)
    j invalid_choice

count_zero:
    addi $t3, $t3, 1     # zero count++
    j next_char

count_one:
    addi $t2, $t2, 1     # one count++

next_char:
    addi $t0, $t0, 1     # next char
    j count_loop

count_done:
    # Print "Number of 1s: "
    li $v0, 4
    la $a0, onesMsg
    syscall

    move $a0, $t2
    li $v0, 1
    syscall

    # Newline
    li $v0, 4
    la $a0, newline
    syscall

    # Print "Number of 0s: "
    li $v0, 4
    la $a0, zerosMsg
    syscall

    move $a0, $t3
    li $v0, 1
    syscall

    # Newline and return to menu
    li $v0, 4
    la $a0, newline
    syscall
    j main


# ================================
# Option 4: Perform Bit Shift (Left/Right)
# ================================
shift_bits:
    # Ask for decimal number
    li $v0, 4
    la $a0, askDec
    syscall

    # Read input as string
    li $v0, 8
    la $a0, buffer
    li $a1, 12
    syscall

    # Convert to integer
    jal validate_and_convert
    move $s0, $v0       # $s0 = original number (preserved)

    # Ask for shift direction
    li $v0, 4
    la $a0, shiftDirMsg
    syscall

    li $v0, 8
    la $a0, buffer
    li $a1, 5
    syscall

    lb $s1, buffer      # read first char of direction (store in $s1)

    # Validate shift direction (must be L/l or R/r)
    li $t0, 'L'
    li $t1, 'l'
    li $t2, 'R'
    li $t3, 'r'
    beq $s1, $t0, get_shift_amount
    beq $s1, $t1, get_shift_amount
    beq $s1, $t2, get_shift_amount
    beq $s1, $t3, get_shift_amount
    j invalid_choice

get_shift_amount:
    li $v0, 4
    la $a0, shiftAmtMsg
    syscall

    li $v0, 8
    la $a0, buffer
    li $a1, 6
    syscall

    jal validate_and_convert
    move $s2, $v0       # $s2 = shift amount

    # Perform the shift
    li $t0, 'L'
    li $t1, 'l'
    beq $s1, $t0, do_left_shift
    beq $s1, $t1, do_left_shift

do_right_shift:
    srlv $s3, $s0, $s2   # $s3 = $s0 >> $s2
    j print_shift_result

do_left_shift:
    sllv $s3, $s0, $s2   # $s3 = $s0 << $s2

print_shift_result:
    # Show decimal result
    li $v0, 4
    la $a0, resultShiftMsg
    syscall

    move $a0, $s3
    li $v0, 1
    syscall

    # Show binary
    li $v0, 4
    la $a0, binaryMsg
    syscall

    move $t0, $s3
    la $t1, binArray
    beqz $t0, print_zero_shift

shift_convert_loop:
    li $t2, 2
    div $t0, $t2
    mfhi $t3
    mflo $t0
    addi $t3, $t3, 48
    sb $t3, 0($t1)
    addi $t1, $t1, 1
    bnez $t0, shift_convert_loop

    la $t2, binArray
    move $t4, $t1

print_shift_bin_loop:
    subi $t4, $t4, 1
    lb $a0, 0($t4)
    li $v0, 11
    syscall
    bge $t2, $t4, shift_bin_done
    j print_shift_bin_loop

print_zero_shift:
    li $v0, 11
    li $a0, 48
    syscall

shift_bin_done:
    li $v0, 4
    la $a0, newline
    syscall
    j main

# ================================
# Exit
# ================================
exit_program:
    li $v0, 10
    syscall

.data
    prompt_count: .asciiz "How many bytes: "
    prompt_bin:   .asciiz "8-bit binary: "
    msg_err:      .asciiz "Invalid count.\n"
    msg_bin:      .asciiz "Checksum (Bin): "
    msg_hex:      .asciiz "\nChecksum (Hex): 0x"
    hex_chars:    .asciiz "0123456789ABCDEF"
    buffer:       .space 16

.text
.globl main

##########################################
#	Main Program ask values
##########################################
main:
    li   $v0, 4
    la   $a0, prompt_count
    syscall

    li   $v0, 5
    syscall
    move $s0, $v0

    blez $s0, error_exit

    li   $s1, 0
    li   $t0, 0

##########################################
#	Loop binary and sum
##########################################
input_loop:
    bge  $t0, $s0, wrap_around

    li   $v0, 4
    la   $a0, prompt_bin
    syscall

    li   $v0, 8
    la   $a0, buffer
    li   $a1, 16
    syscall

    la   $t1, buffer
    li   $t2, 0

parse_loop:
    lb   $t3, 0($t1)
    blt  $t3, 48, end_parse
    bgt  $t3, 49, end_parse

    addi $t3, $t3, -48
    sll  $t2, $t2, 1
    add  $t2, $t2, $t3
    addi $t1, $t1, 1
    j    parse_loop

end_parse:
    add  $s1, $s1, $t2
    addi $t0, $t0, 1
    j    input_loop

##########################################
#	Warp around and one complement
##########################################
wrap_around:
    ble  $s1, 0xFF, complement
    andi $t3, $s1, 0xFF
    srl  $s1, $s1, 8
    add  $s1, $t3, $s1
    j    wrap_around

complement:
    not  $s2, $s1
    andi $s2, $s2, 0xFF

##########################################
#	Print binary and Hex
##########################################
    li   $v0, 4
    la   $a0, msg_bin
    syscall

    li   $t0, 7
print_bin:
    bltz $t0, print_hex
    srlv $t3, $s2, $t0
    andi $a0, $t3, 1
    li   $v0, 1
    syscall
    addi $t0, $t0, -1
    j    print_bin

print_hex:
    li   $v0, 4
    la   $a0, msg_hex
    syscall

    la   $t1, hex_chars

    srl  $t3, $s2, 4
    add  $t3, $t1, $t3
    lb   $a0, 0($t3)
    li   $v0, 11
    syscall

    andi $t3, $s2, 0x0F
    add  $t3, $t1, $t3
    lb   $a0, 0($t3)
    li   $v0, 11
    syscall

    j    exit

##########################################
#	End and error massage
##########################################
error_exit:
    li   $v0, 4
    la   $a0, msg_err
    syscall

exit:
    li   $v0, 10
    syscall

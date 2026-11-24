.data
    prompt_count: .asciiz "How many bytes: "
    prompt_bin:   .asciiz "8-bit binary: "
    msg_err:      .asciiz "Invalid count.\n"
    msg_bin:      .asciiz "Checksum (Bin): "
    msg_hex:      .asciiz "\nChecksum (Hex): 0x"
    hex_chars:    .asciiz "0123456789ABCDEF"
    buffer:       .space 16                 # พื้นที่สำหรับรับข้อความเลขฐาน 2 (เผื่อ '\n' และ '\0')

.text
.globl main

# ==========================================
# โปรแกรมหลัก (ถามจำนวนไบต์และรับค่าทีละชุด)
# ==========================================
main:
    li   $v0, 4                             # Syscall 4: แสดงข้อความ
    la   $a0, prompt_count                  # พิมพ์ถาม "How many bytes: "
    syscall

    li   $v0, 5                             # Syscall 5: รับตัวเลขจำนวนเต็มจากคีย์บอร์ด
    syscall
    move $s0, $v0                           # เก็บจำนวนไบต์ (count) ไว้ใน $s0

    blez $s0, error_exit                    # ถ้าจำนวน <= 0 ให้แจ้งเตือนและจบโปรแกรม

    li   $s1, 0                             # sum = 0 (ตัวแปรเก็บผลรวมทั้งหมด)
    li   $t0, 0                             # i = 0 (ตัวนับรอบการรับข้อมูล)

# ==========================================
# 1. วนลูปรับเลขฐาน 2 ทีละชุดและบวกรวมทันที
# ==========================================
input_loop:
    bge  $t0, $s0, wrap_around              # ถ้ารับครบตามจำนวน (i >= count) ให้ไปคำนวณต่อ

    li   $v0, 4                             # Syscall 4: แสดงข้อความ
    la   $a0, prompt_bin                    # พิมพ์ถาม "8-bit binary: "
    syscall

    li   $v0, 8                             # Syscall 8: รับข้อความ (String) จากคีย์บอร์ด
    la   $a0, buffer                        # กำหนดที่เก็บข้อความลงใน buffer
    li   $a1, 16                            # กำหนดความยาวสูงสุดที่รับได้
    syscall

    la   $t1, buffer                        # ให้ Pointer p ชี้ไปที่ตัวอักษรแรกใน buffer
    li   $t2, 0                             # value = 0 (ตัวแปรพักค่าเลขฐาน 10 ของชุดนี้)

parse_loop:
    lb   $t3, 0($t1)                        # อ่านตัวอักษรทีละตัว (*p)
    blt  $t3, 48, end_parse                 # ถ้าเจอ '\n' (10) หรือ '\0' (0) ให้จบการแปลงชุดนี้
    bgt  $t3, 49, end_parse                 # กันตัวอักษรอื่นที่ไม่ใช่ '0' (48) หรือ '1' (49)

    addi $t3, $t3, -48                      # แปลงรหัส ASCII เป็นตัวเลข 0 หรือ 1 (*p - '0')
    sll  $t2, $t2, 1                        # เลื่อนบิตซ้าย 1 ตำแหน่ง (value << 1)
    add  $t2, $t2, $t3                      # บวกบิตปัจจุบันเข้าไปใน value
    addi $t1, $t1, 1                        # เลื่อน Pointer ไปตัวถัดไป (p++)
    j    parse_loop                         # วนอ่านตัวอักษรถัดไป

end_parse:
    add  $s1, $s1, $t2                      # sum += value
    addi $t0, $t0, 1                        # i++
    j    input_loop                         # วนกลับไปถามชุดถัดไป

# ==========================================
# 2. คำนวณ Wrap-around และ 1's Complement
# ==========================================
wrap_around:
    ble  $s1, 0xFF, complement              # ถ้า sum <= 0xFF (ไม่เกิน 8 บิต) ให้ข้ามไปกลับบิต
    andi $t3, $s1, 0xFF                     # ดึง 8 บิตล่าง (sum & 0xFF)
    srl  $s1, $s1, 8                        # เลื่อนบิตที่ล้นมาทางขวา (sum >> 8)
    add  $s1, $t3, $s1                      # บวกทบกลับเข้าไป
    j    wrap_around                        # เช็กซ้ำเผื่อยังเกิน 8 บิต

complement:
    not  $s2, $s1                           # กลับบิตทั้งหมด (1's Complement)
    andi $s2, $s2, 0xFF                     # ตัดให้เหลือเฉพาะ 8 บิตล่าง (checksum)

# ==========================================
# 3. แสดงผลลัพธ์ (Binary และ Hex)
# ==========================================
    li   $v0, 4                             # Syscall 4: แสดงข้อความ
    la   $a0, msg_bin                       # พิมพ์ "Checksum (Bin): "
    syscall

    li   $t0, 7                             # ตัวนับตำแหน่งบิต i = 7 (เริ่มจากซ้ายสุด)
print_bin:
    bltz $t0, print_hex                     # ถ้า i < 0 ให้ไปพิมพ์เลขฐาน 16
    srlv $t3, $s2, $t0                      # เลื่อนบิตที่ต้องการมาขวาสุด (checksum >> i)
    andi $a0, $t3, 1                        # ดึงค่าบิตขวาสุด (& 1)
    li   $v0, 1                             # Syscall 1: แสดงตัวเลข (0 หรือ 1)
    syscall
    addi $t0, $t0, -1                       # i--
    j    print_bin                          # วนพิมพ์บิตถัดไป

print_hex:
    li   $v0, 4                             # Syscall 4: แสดงข้อความ
    la   $a0, msg_hex                       # พิมพ์ "\nChecksum (Hex): 0x"
    syscall

    la   $t1, hex_chars                     # โหลดตารางตัวอักษรฐาน 16

    srl  $t3, $s2, 4                        # ดึง 4 บิตบน (หลักแรกของ Hex)
    add  $t3, $t1, $t3                      # หาตำแหน่งตัวอักษรในตาราง
    lb   $a0, 0($t3)                        # โหลดตัวอักษรฐาน 16 ตัวแรก
    li   $v0, 11                            # Syscall 11: แสดงตัวอักษร 1 ตัว
    syscall

    andi $t3, $s2, 0x0F                     # ดึง 4 บิตล่าง (หลักที่สองของ Hex)
    add  $t3, $t1, $t3                      # หาตำแหน่งตัวอักษรในตาราง
    lb   $a0, 0($t3)                        # โหลดตัวอักษรฐาน 16 ตัวที่สอง
    li   $v0, 11                            # Syscall 11: แสดงตัวอักษร 1 ตัว
    syscall

    j    exit                               # จบการทำงาน

# ==========================================
# จบการทำงาน / แจ้งเตือน Error
# ==========================================
error_exit:
    li   $v0, 4                             # Syscall 4: แสดงข้อความแจ้ง Error
    la   $a0, msg_err
    syscall

exit:
    li   $v0, 10                            # Syscall 10: จบโปรแกรม
    syscall

  .data
in_pos: .quad 0
out_pos: .quad 0
in_buf: .space 32
out_buf: .space 32
buf_size: .quad 31

  .text
  .global inImage
  .global getInt
  .global getText
  .global getChar
  .global getInPos
  .global setInPos
  .global outImage
  .global putInt
  .global putText
  .global putChar
  .global getOutPos
  .global setOutPos


inImage:
  pushq %rax
  pushq %rbx
  pushq %rcx
  pushq %rdx
  pushq %rsi
  pushq %rdi
  pushq %r8
  pushq %r9
  pushq %r10
  pushq %r11

  subq $8, %rsp # Alignment

  leaq in_buf, %rdi # Load buffer address
  movq buf_size, %rsi # Load used buffer size
  movq stdin, %rdx    
  call fgets
  movl $0, in_pos # Reset posistion

  addq $8, %rsp

  popq %r11
  popq %r10
  popq %r9
  popq %r8
  popq %rdi
  popq %rsi
  popq %rdx
  popq %rcx
  popq %rbx
  popq %rax
  ret


getInt:
  pushq %r8
  pushq %rbx
  pushq %rdx
  pushq %rsi
  pushq %rdi
  pushq %r9
  movq $0, %rdi
  movq $0, %rdx
  movq in_pos, %rsi
  leaq in_buf, %rbx    # rbx = in_buf

.getIntLoop:
  movb (%rbx, %rsi), %r8b # r8b = *rbx
  incq %rsi

  cmpb $0x0, %r8b   # r8b == 0x0
  je .getIntBuffEmpty

  cmpb $0x2b, %r8b  # r8b == +
  je .getIntLoop

  cmpb $0x2d, %r8b  # r8b == -
  je .getIntNeg

  cmpb $0x30, %r8b  # r8b < 0x30
  jl .getIntLetter

  cmpb $0x39, %r8b  # r8b > 0x39
  jg .getIntLetter

.getIntNum:
  orb $0x2, %dil    # dil | 0b0000 0010
  subb $0x30, %r8b  # r8b - 0x30
  imulq $10, %rdx   # rdx * 10
  movsbq %r8b, %r8  # r8b -> r8
  addq %r8, %rdx    # rdx + r8
  jmp .getIntLoop

.getIntLetter:
  testb $0x2, %dil  # dil & 0b0000 0010
  je .getIntLoop
  testb $0x1, %dil  # dil & 0b0000 0001
  je .getIntNotNeg
  imulq $-1, %rdx   # Negate
.getIntNotNeg:
  jmp .getIntReturn

.getIntNeg:
  orb $0x1, %dil    # dil | 0b0000 0001
  jmp .getIntLoop

.getIntBuffEmpty:
  call inImage
  movq in_pos, %rsi
  jmp .getIntLoop

.getIntReturn: 
  movq %rsi, in_pos
  movq %rdx, %rax
  popq %r9
  popq %rdi
  popq %rsi
  popq %rdx
  popq %rbx
  popq %r8
  ret


getText:
# Get n characters from in.put_buffer
# Parameters:
#   rdi: buffer to store characters
#   rsi: number of characters to read
# Returns:
#   rax: number of characters read
  pushq %rbx
  pushq %rcx
  pushq %rdx

  movq $0x0, %rax
  movq $0x0, %rbx
  movq $0x0, %rdx

  leaq in_buf, %rcx # rcx = in_buf
  movq in_pos, %rdx # rdx = in_pos
  movb (%rcx, %rdx), %bl # dl = *(in_buf + in_pos)

  cmpb $0x0, %bl # dl == 0x0
  jne .getTextLoop
  call inImage

.getTextLoop:
  movb (%rcx, %rdx), %bl # dl = *(in_buf + in_pos)
  incq %rdx
  movb %bl, (%rdi, %rax) # *(rdi + rax) = dl
  incq %rax
  
  cmpb $0x0, %bl # bh == 0x0
  je .getTextEndLoop
  cmpq %rsi, %rax # rbx == rsi
  je .getTextEndLoop
  jmp .getTextLoop

.getTextEndLoop: 
  movq %rdx, in_pos
  popq %rdx
  popq %rcx
  popq %rbx
  ret


getChar:
# Gets one char from buffer
# Returns:
#   rax: the char
  pushq %rbx
  pushq %rcx
  pushq %rdx

  movq $0x0, %rbx
  leaq in_buf, %rcx # Buffer address

.getCharRetry:
  movq in_pos, %rdx
  movb (%rcx, %rdx), %bl # Load char from buffer

  cmpb $0x0, %bl
  jne .getCharReturn # Validate char
  call inImage
  jmp .getCharRetry

.getCharReturn:
  movq $0x0, %rax
  movb %bl, %al
  popq %rdx
  popq %rcx
  popq %rbx
  ret
  

setInPos:
# Sets in_pos to n
# Parameter:
#   %rdi: n
  pushq %rdi

  cmpq $0, %rdi
  jl .setInPosLow # Validate new pos
  cmpq buf_size, %rdi
  jg .setInPosHigh

.setInPosRet:
  movq %rdi, in_pos
  popq %rdi
  ret

.setInPosLow:
  movq $0, %rdi
  jmp .setInPosRet

.setInPosHigh:
  movq buf_size, %rdi
  jmp .setInPosRet


# In.put

outImage:
  pushq %rax
  pushq %rbx
  pushq %rcx
  pushq %rdx
  pushq %rsi
  pushq %rdi
  pushq %r8
  pushq %r9
  pushq %r10
  pushq %r11

  subq $8, %rsp # Alignment

  movq out_pos, %rax # Load buffer pos
  movq buf_size, %rbx # Load buffer size
  cmpq %rax, %rbx
  je .outImageNoEarly # If early call add \n (10) at end.

  movq $10, %rdi
  call putChar

.outImageNoEarly:

  leaq out_buf, %rdi # Load buffer address
  xor %rax, %rax # Reset rax for printf
  call printf
  movq $0, out_pos

  addq $8, %rsp

  popq %r11
  popq %r10
  popq %r9
  popq %r8
  popq %rdi
  popq %rsi
  popq %rdx
  popq %rcx
  popq %rbx
  popq %rax
  ret



putInt:
# Adds n to out_buf
# Parameter:
#   - %rdi: n
  pushq %rsi
  pushq %rax
  pushq %rdi
  pushq %rdx
  pushq %r8
  pushq %r9
  pushq %r10
  pushq %r11

  cmp $0, %rdi
  jge .putIntNotNeg
  imulq $-1, %rdi # If negative make positive and add
  movq %rdi, %rsi # '-' to out buffer
  movq $'-', %rdi
  call putChar
  movq %rsi, %rdi

.putIntNotNeg:
  movq $1, %rsi
  movq %rdi, %rax

# Find decimal size, by dividing rsi till
# the rest is 0 
.putIntFindSize:
  cmp $9, %rax
  jle .putIntFoundSize # if less than 10 we've found the needed decimal

  imulq $10, %rsi
  movq %rdi, %rax
  movq $0, %rdx
  idivq %rsi

  jmp .putIntFindSize

.putIntFoundSize:
  leaq out_buf, %r8
  movq out_pos, %r9
  movq $0, %r10
  movq $10, %r11

.putIntConvert:
  addq %rax, %r10       # m = m + n
  imulq $10, %r10       # m = m * 10
  addq $0x30, %rax      # n = n + 0x30

  movq %rax, (%r8, %r9) # n => (out_buf, out_pos)
  incq %r9

  movq %rsi, %rax
  movq $0, %rdx         # x = x / 10
  idivq %r11
  movq %rax, %rsi

  cmp $0, %rsi
  je .putIntRet

  movq %rdi, %rax
  movq $0, %rdx         # n = y / x
  idivq %rsi

  subq %r10, %rax
  
  cmp buf_size, %r9
  je .putIntFullBuff

  jmp .putIntConvert

.putIntRet:
  movq %r9, out_pos
  popq %r11
  popq %r10
  popq %r9
  popq %r8
  popq %rax
  popq %rdi
  popq %rdx
  popq %rsi
  ret

.putIntFullBuff:
  call outImage
  movq out_pos, %r9
  jmp .putIntConvert



putText:
# Moves chars from given buffer to the out buffer.
# If out buffer is full it'll print it.
# Parameter:
#   - %rdi: string pointer
  pushq %rdx
  pushq %rcx
  pushq %rbx
  pushq %rax

  movq $0, %rcx
  movq $0, %rdx
  movq $0, %rax
  leaq out_buf, %rbx
  movq out_pos, %rax

.putTextLoop:
  movb (%rdi, %rcx), %dl
  movb %dl, (%rbx, %rax)

  incq %rcx
  incq %rax

  cmpq buf_size, %rax # Check if out buffer is full
  je .putTextOutFull

  cmpb $0x0, %dl # check if in buffer is empty
  je .putTextRet
  
  jmp .putTextLoop

.putTextOutFull:
  # Print string
  movq %rax, out_pos
  call outImage
  movq out_pos, %rax
  jmp .putTextLoop

.putTextRet:
  movq %rax, out_pos
  popq %rax
  popq %rbx
  popq %rcx
  popq %rdx
  ret


putChar:
# add c to out_buf
# parameters:
#   - %rdi: char
  pushq %rcx
  pushq %rdx

  movq out_pos, %rcx
  leaq out_buf, %rdx

  movq %rdi, (%rdx, %rcx)
  incq %rcx

  cmpq buf_size, %rcx
  jne .putCharRet
  
  call outImage
  movq out_pos, %rcx

.putCharRet:
  movq %rcx, out_pos
  popq %rdx
  popq %rcx
  ret


getOutPos:
  movq out_pos, %rax
  ret


setOutPos:
  pushq %rdi

  cmpq $0, %rdi
  jl .setOutPosLess

  cmpq buf_size, %rdi
  je .setOutPosGreater

.setOutPosRet:
  movq %rdi, out_pos
  popq %rdi
  ret

.setOutPosLess:
  movq $0, %rdi
  jmp .setOutPosRet

.setOutPosGreater:
  movq $0, %rdi
  jmp .setOutPosRet

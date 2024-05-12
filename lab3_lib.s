  .data
in_pos: .byte 0
out_pos: .quad 0
in_buf: .space 20
out_buf: .asciz "xxxxx"
buf_size: .quad 5

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

  # Why is fgets so destructive
  leaq in_buf, %rdi
  movq $20, %rsi
  movq stdin, %rdx
  call fgets
  movw $0, in_pos

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
  movzwq in_pos, %rsi
getIntLoop:
  leaq in_buf, %rbx    # rbx = in_buf
  addq %rsi, %rbx   # rbx += in_pos
  movb (%rbx), %r8b # r8b = *rbx
  incq %rsi

  cmpb $0x0, %r8b   # r8b == 0x0
  je getIntBuffEmpty

  cmpb $0x2b, %r8b  # r8b == +
  je getIntLoop

  cmpb $0x2d, %r8b  # r8b == -
  je getIntNeg

  cmpb $0x30, %r8b  # r8b < 0x30
  jl getIntLetter

  cmpb $0x39, %r8b  # r8b > 0x39
  jg getIntLetter

getIntNum:
  orb $0x2, %dil    # dil | 0b0000 0010
  subb $0x30, %r8b  # r8b - 0x30
  imulq $10, %rdx   # rdx * 10
  movsbq %r8b, %r8  # r8b -> r8
  addq %r8, %rdx    # rdx + r8
  jmp getIntLoop

getIntLetter:
  testb $0x2, %dil  # dil & 0b0000 0010
  je getIntLoop
  testb $0x1, %dil  # dil & 0b0000 0001
  je getIntNotNeg
  imulq $-1, %rdx   # Negate
getIntNotNeg:
  jmp getIntReturn

getIntNeg:
  orb $0x1, %dil    # dil | 0b0000 0001
  jmp getIntLoop

getIntBuffEmpty:
  call inImage
  movzwq in_pos, %rsi
  jmp getIntLoop

getIntReturn: 
  movw %si, in_pos
  movq %rdx, %rax
  popq %r9
  popq %rdi
  popq %rsi
  popq %rdx
  popq %rbx
  popq %r8
  ret


getText:
# Get n characters from input_buffer
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

  leaq in_buf, %rcx            # rcx = in_buf
  movq in_pos, %rdx            # rdx = in_pos
  movb (%rcx, %rdx), %bl    # dl = *(in_buf + in_pos)

  cmpb $0x0, %bl            # dl == 0x0
  jne getTextLoop
  call inImage

getTextLoop:
  movb (%rcx, %rdx), %bl    # dl = *(in_buf + in_pos)
  incq %rdx
  movb %bl, (%rdi, %rax)    # *(rdi + rax) = dl
  incq %rax
  
  cmpb $0x0, %bl            # bh == 0x0
  je getTextEndLoop
  cmpq %rsi, %rax           # rbx == rsi
  je getTextEndLoop
  jmp getTextLoop

getTextEndLoop: 
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
  leaq in_buf, %rcx

getCharRetry:
  movq in_pos, %rdx
  movb (%rcx, %rdx), %bl

  cmpb $0x0, %bl
  jne getCharReturn
  call inImage
  jmp getCharRetry

getCharReturn:
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
  jl setInPosLow
  cmpq $19, %rdi
  jg setInPosHigh

setInPosRet:
  movq %rdi, in_pos
  popq %rdi
  ret

setInPosLow:
  movq $0, %rdi
  jmp setInPosRet

setInPosHigh:
  movq $19, %rdi
  jmp setInPosRet


# Input

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

  leaq out_buf, %rdi
  xor %rax, %rax
  call printf
  movq $0, out_pos

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

  movq $1, %rsi

 putIntFindSize:
  imulq $10, %rsi
  movq %rdi, %rax
  movq $0, %rdx
  idivq %rsi

  cmp $10, %rax
  jg putIntFindSize

  leaq out_buf, %r8
  movq out_pos, %r9
  movq $0, %r10
  movq $10, %r11

putIntConvert:
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
  je putIntRet

  movq %rdi, %rax
  movq $0, %rdx         # n = y / x
  idivq %rsi

  subq %r10, %rax
  
  cmp $5, %r9
  je putIntFullBuff

  jmp putIntConvert

putIntRet:
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

putIntFullBuff:
  call outImage
  movq out_pos, %r9
  jmp putIntConvert



putText:
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

putTextLoop:
  movb (%rdi, %rcx), %dl
  movb %dl, (%rbx, %rax)
 

  incq %rcx
  incq %rax

  cmpq $5, %rax
  je putTextOutFull

  cmpb $0x0, %dl
  je putTextRet
  
  jmp putTextLoop

putTextOutFull:
  movq %rax, out_pos
  call outImage
  movq out_pos, %rax
  jmp putTextLoop

putTextRet:
  movq %rax, out_pos
  popq %rax
  popq %rbx
  popq %rcx
  popq %rdx
  ret

putChar:
getOutPos:
setOutPos:


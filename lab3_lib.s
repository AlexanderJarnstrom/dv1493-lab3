  .data
buf: .space 20 
pos: .byte 0
  .text
  .global main

main:
  pushq $0
  movq $0, %rax
  movq $0, %rcx
  movq $0, %rdx
  movq $0, %rsi
  movq $0, %rdi
  movq $0, %r8
  movq $0, %r9
  movq $0, %r10
  movq $0, %r11   
  # Nice 0:s everywhere
  movq $16, %rdi
  call setInPos
  movq pos, %rdi
  ret

# Output

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
  leaq buf, %rdi
  movq $20, %rsi
  movq stdin, %rdx
  call fgets
  movw $0, pos

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
  movzwq pos, %rsi
getIntLoop:
  leaq buf, %rbx    # rbx = buf
  addq %rsi, %rbx   # rbx += pos
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
  movzwq pos, %rsi
  jmp getIntLoop

getIntReturn: 
  movw %si, pos
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

  leaq buf, %rcx            # rcx = buf
  movq pos, %rdx            # rdx = pos
  movb (%rcx, %rdx), %bl    # dl = *(buf + pos)

  cmpb $0x0, %bl            # dl == 0x0
  jne getTextLoop
  call inImage

getTextLoop:
  movb (%rcx, %rdx), %bl    # dl = *(buf + pos)
  incq %rdx
  movb %bl, (%rdi, %rax)    # *(rdi + rax) = dl
  incq %rax
  
  cmpb $0x0, %bl            # bh == 0x0
  je getTextEndLoop
  cmpq %rsi, %rax           # rbx == rsi
  je getTextEndLoop
  jmp getTextLoop

getTextEndLoop: 
  movq %rdx, pos
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
  leaq buf, %rcx

getCharRetry:
  movq pos, %rdx
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
# Sets pos to n
# Parameter:
#   %rdi: n
  pushq %rdi

  cmpq $0, %rdi
  jl setInPosLow
  cmpq $19, %rdi
  jg setInPosHigh

setInPosRet:
  movq %rdi, pos
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
putInt:
putText:
putChar:
getOutPos:
setOutPos:


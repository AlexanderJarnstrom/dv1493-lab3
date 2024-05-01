  .data
buf: .space 20 
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
  call inImage
  call getInt
  ret

# Output

inImage:
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

  popq %r11
  popq %r10
  popq %r9
  popq %r8
  popq %rdi
  popq %rsi
  popq %rdx
  popq %rcx
  popq %rbx
  ret


getInt:
  pushq %r8
  pushq %rbx
  pushq %rdx
  leaq buf, %rbx
getIntLoop:
  movb (%rbx), %r8b
  incq %rbx

  cmpb $0x0, %r8b
  je getIntReturn

  cmpb $0x2b, %r8b  # r8b == +
  je getIntPos

  cmpb $0x2d, %r8b
  je getIntNeg

  cmpb $0x30, %r8b
  jl getIntReturn
  cmpb $0x39, %r8b
  jg getIntReturn

getIntNum:
  movq $1, %rdx
  jmp getIntLoop

getIntPos:
  movq $2, %rdx
  jmp getIntLoop
  
getIntNeg:
  movq $3, %rdx
  jmp getIntLoop

getIntReturn: 
  popq %rdx
  popq %rbx
  popq %r8
  ret


getText:
getChar:
setInPos:

# Input

outImage:
putInt:
putText:
putChar:
getOutPos:
setOutPos:


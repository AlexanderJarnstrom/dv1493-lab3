.section.data
inbuf:    .space 128          # Input buffer
outBuf:   .space 128          # Output buffer
inpos:    .quad 0             # Current input position
outPos:   .quad 0             # Current output position
newline:  .asciz "\n"         
nullchar: .byte 0             # Null character
int_count: .quad 0           # Counter for the number of integers
int_stack: .space 40         
int_sum:   .quad 0          
zero:     .quad 0             # Zero
maxpos:   .quad 127           # Max position index (128 - 1)
stdout:   .quad 1             # Standard output

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
.global printf
.extern stdin
.extern fgets

# Ensure the input buffer is filled
checkInBuffer:
    movq inpos(%rip), %rax
    cmpq maxpos(%rip), %rax  
    jl .buffer_ok
    call inImage             
.buffer_ok:
    ret

inImage:
    subq $8, %rsp             
    leaq inbuf(%rip), %rdi   
    movq $128, %rsi          
    movq stdin(%rip), %rdx    
    call fgets                # Call fgets to read input
    addq $8, %rsp             
    movq $0, inpos(%rip)      
    ret

isDigit:
    cmpb $'0', %dil
    jb not_digit
    cmpb $'9', %dil
    ja not_digit
    movq $1, %rax
    ret

not_digit:
    movq $0, %rax
    ret

getInt:
    call    checkInBuffer          
    movq    inpos(%rip), %rsi      
    leaq    inbuf(%rip), %rdi
    addq    %rsi, %rdi              
    xor     %rax, %rax           
    mov     $1, %rbx                

.parse_loop:
    movb    (%rdi), %dl
    cmpb    $' ', %dl
    je      .skip_whitespace

    cmpb    $'+', %dl
    je      .check_digit

    cmpb    $'-', %dl
    je      .negate

    # Check if the character is a digit
    movb    %dl, %dil
    call    isDigit
    testq   %rax, %rax
    jz      .end_parse

    subb    $'0', %dl
    imulq   $10, %rax
    addq    %rdx, %rax

.update_pos:
    incq    %rsi
    incq    %rdi
    jmp     .parse_loop

.skip_whitespace:
    incq    %rsi
    incq    %rdi
    jmp     .parse_loop

.negate:
    mov     $-1, %rbx
    jmp     .update_pos

.check_digit:
    jmp     .update_pos

.end_parse:
    imulq   %rbx, %rax             
    # Store the integer in the stack
    movq    int_count(%rip), %rcx
    cmpq    $5, %rcx
    jge     .skip_store
    leaq    int_stack(%rip), %rdx
    movq    %rax, (%rdx, %rcx, 8)
    addq    %rax, int_sum(%rip)
    incq    int_count(%rip)

.skip_store:
    movq    %rsi, inpos(%rip)       # Update input position
    ret

printIntegers:
    pushq %rbp
    movq  %rsp, %rbp
    subq  $32, %rsp                

    movq  int_sum(%rip), %rdi      # Load sum into %rdi
    call  putInt                   # Print the sum

    # Load the address of newline directly into %rdi
    leaq  newline(%rip), %rdi
    call  putText                  

    leaq  int_stack(%rip), %rsi    
    movq  int_count(%rip), %rcx   
    movq  $0, %rdx                

.print_loop:
    cmpq  %rdx, %rcx
    jge   .end_print
    movq  (%rsi, %rdx, 8), %rdi    
    call  putInt                   
    movq  $' ', %rdi               
    call  putChar
    incq  %rdx
    jmp   .print_loop

.end_print:

    leaq  newline(%rip), %rdi
    call  putText                 

    # Reset count and sum directly
    movq  $0, int_count(%rip)      # Reset count
    movq  $0, int_sum(%rip)        # Reset sum
    addq  $32, %rsp
    popq  %rbp
    ret

getText:
    call    checkInBuffer           
    movq    %rdi, %r8               
    movq    %rsi, %rcx              # Max length to read
    movq    inpos(%rip), %rsi       # Current position
    leaq    inbuf(%rip), %rdi
    addq    %rsi, %rdi              
    xor     %rax, %rax              
    xor     %rdx, %rdx             

.read_loop:
    cmpq    %rcx, %rax
    je      .end_read               

    movb    (%rdi), %dl
    cmpb    $0, %dl
    je      .end_read              

    movb    %dl, (%r8)
    incq    %r8                     
    incq    %rdi                    
    incq    %rsi                    
    incq    %rax                    
    jmp     .read_loop

.end_read:
    movb    $0, (%r8)               
    movq    %rsi, inpos(%rip)       
    ret

getChar:
    call    checkInBuffer           # Ensure buffer is filled
    movq    inpos(%rip), %rsi       
    leaq    inbuf(%rip), %rdi
    addq    %rsi, %rdi             
    movb    (%rdi), %al             # Read character
    incq    %rsi
    movq    %rsi, inpos(%rip)      
    ret


exit:
    movq    $60, %rax               
    xor     %rdi, %rdi            
    syscall                         

setInPos:
    pushq %rdi

    cmpq $0, %rdi
    jl setInPosLow
    cmpq $127, %rdi
    jg setInPosHigh

setInPosRet:
    movq %rdi, inpos(%rip)
    popq %rdi
    ret

setInPosLow:
    movq $0, %rdi
    jmp setInPosRet

setInPosHigh:
    movq $127, %rdi
    jmp setInPosRet

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

    # Ensure stack alignment
    subq $8, %rsp

    leaq outBuf(%rip), %rdi
    movq $0, %rax
    call printf
    
    addq $8, %rsp  # Restore stack alignment
    
    movq $0, outPos(%rip)

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
    pushq %rsi
    pushq %rdi
    pushq %rdx
    pushq %rbx
    pushq %r10
    pushq %r11

    movq %rdi, %rax          
    xor %rbx, %rbx           
    movq $1, %rbx            
    movq $10, %r11          

putIntFindSize:
    movq %rax, %rdx
    xor %rdx, %rdx          
    divq %r11                
    testq %rax, %rax         
    jz putIntPrint          
    imulq $10, %rbx          
    jmp putIntFindSize      

putIntPrint:
    movq %rdi, %rax          

putIntLoop:
    xor %rdx, %rdx           
    divq %rbx                
    addb $'0', %dl           # Convert to ASCII
    movb %dl, %dil           
    call putChar             
    xor %rdx, %rdx           
    movq %rbx, %rax         
    movq $10, %rbx          
    divq %rbx               
    cmpq $1, %rax          
    jb putIntEnd             
    movq %rax, %rbx          
    movq %rdi, %rax         
    jmp putIntLoop         

putIntEnd:
    popq %r11
    popq %r10
    popq %rbx
    popq %rdx
    popq %rdi
    popq %rsi
    ret

putChar:
    pushq %rcx
    pushq %rdx

    movq outPos(%rip), %rcx
    leaq outBuf(%rip), %rdx

    movb %dil, (%rdx, %rcx)
    incq %rcx

    cmpq $127, %rcx
    jne putCharRet

    call outImage
    movq $0, %rcx

putCharRet:
    movq %rcx, outPos(%rip)
    popq %rdx
    popq %rcx
    ret

putText:
    pushq %rdx
    pushq %rcx
    pushq %rbx
    pushq %rax

    movq $0, %rcx
    movq $0, %rdx
    leaq outBuf(%rip), %rbx
    movq outPos(%rip), %rax

putTextLoop:
    movb (%rdi, %rcx), %dl
    testb %dl, %dl
    je putTextEnd
    movb %dl, (%rbx, %rax)
    incq %rcx
    incq %rax
    cmpq $128, %rax
    jne putTextLoop

putTextEnd:
    movb $0, (%rbx, %rax)    # Null-terminate the output buffer
    movq %rax, outPos(%rip)
    popq %rax
    popq %rbx
    popq %rcx
    popq %rdx
    ret


getOutPos:
    movq outPos, %rax
    ret


setOutPos:
    pushq %rdi

    cmpq $0, %rdi
    jl setOutPosLess

    cmpq inbuf, %rdi
    je setOutPosGreater

setOutPosRet:
    movq %rdi, outPos
    popq %rdi
    ret

setOutPosLess:
    movq $0, %rdi
    jmp setOutPosRet

setOutPosGreater:
    movq $0, %rdi
    jmp setOutPosRet

; Zakris Pierson and Nirjal Shakya 
; Copyright @ 2020  Zakris and Nirjal
; CS278 - Final Project
; source.asm for clearScreen function from irvine library for NASM
;
; Major Reference Section: 
;   <1> irvine32-nasm : https://github.com/kubistika/irvine32-nasm/blob/master/kobi.asm
;   <2> along32-nasm (Linux interpretation of nasm) - https://github.com/janka102/Along32
;
; Reference Section: 
;   Relevancy for printf 
    ;  <1> Understanding the formatting for printf:- https://community.unix.com/t/printf-c-d-df-0x1b-y-x/169554/3
    ;  <2> Hello World/printf integration - https://montcs.bloomu.edu/~bobmon/Code/Asm.and.C/Asm.Nasm/hello-printf-64.asm.html
    ;  <3> printf Stack/Format Explained - http://sevanspowell.net/posts/learning-nasm-on-macos.html
;   Relevancy for _strLen and _writeString
    ;  <4> EBP, ESP, and their relation - https://stackoverflow.com/questions/21718397/what-are-the-esp-and-the-ebp-registers
    ;  <5> ret-2/4 and how it works - https://stackoverflow.com/questions/17628881/the-meaning-of-ret-2-in-assembly#:~:text=ret%204%20just%20returns%20like,to%20pop%20the%20previous%20pushes.&text=As%20alex%20said%2C%20it%20means%20RETURN
    ;  <6>  macOS 64bit system call - https://stackoverflow.com/questions/48845697/macos-64-bit-system-call-table
;   

; to access the printf function from C library
extern _printf
global _main
segment .data
str_test db "ff",0
; to tell the printf function that we're calling escape characters
ESC				equ 27

section .text

_main:

;lea r9, [rel str_test]
; saving the memory of rax by pushing it onto the stack
push rax
; calling the _clearScreen function which clears the screen and returns the cursor to the (0,0) position on the screen
call _clearScreen
;   restores the saved memory from the stack into rax
pop rax

mov     rax, 0x2000001 ; exit
mov     rdi, 0
syscall

;_clearScreen
; saving the memory of rdx by pushing it onto the stack
; moving the string clrStr into rdx
; calls the _writeString function that uses clrStr to clear screen along with _strLen
; r11 and r14 holds the values of the coordinates for GoToXY
; r11 holds the x-coordinate ? 
; r14 holds the y-coordinate ?
; calls the _GoToXY function which puts the cursor in that coordinate
;   restores the saved memory from the stack into rdx
;   ret 8 - returns 8 bytes of free space from the stack
;       for better understanding, it pops off the last 8-bytes in the stack
_clearScreen:

segment .data
; clrStr stores the formatting to clear the screen
; ESC tells printf it's an escape character
clrStr db ESC, "[2J", 0

segment .text
    push rdx
    mov rdx, [rel clrStr]
    call _writeString
    
   ; xor rdx, rdx
    mov r11, 0
    mov r14, 0
    call _GoToXY
    pop rdx
    ret 8

; GoToXy function that sets the position for X and Y coordinate on the screen
; printf has parameters (format, current_number)
; rdi stores the format (1st parameter) i.e. it stores the string from locateStr, which contains a sequence of strings for escape character
; rsi stores the current_number (2nd parameter) i.e. stores the value from r11 (x-coordinates) 
; r11 and r14 (xy-coordinates) are stored into rsi and rdx respectively 
; we need to zero rax before we call printf
; <IMP NOTE> printf may destroy rax and rcx so if you're using either of these registers, save them using push
; calls _printf which sets the cursor to that particular coordinate on the screen
; <IMP NOTE> While calling printf, we need to pay attention to the stack
;   The stack should be 16-bit aligned (for 64-bit) i.e. it should be a multiple of 16 or 16 itself
;   ret 8 - returns 8 bytes of free space from the stack
;       for better understanding, it pops off the last 8-bytes in the stack
_GoToXY:

segment .data
; locateStr stores the formatting to print GoToXY
; ESC tells printf it's an escape character
locateStr db ESC, "[%d;%dH", 0

segment .text
    lea rdi, [rel locateStr]
    mov rsi, r11
    mov rdx, r14 
    xor rax, rax
    call _printf
  
    ret 8

; saves the base pointer of the stack (rbp) in the stack
; stores the current pointer in the stack into rbp
; [rbp + 16] stores the offset of string in memory
;   stores that offset into r8 
; saves r8 by pushing it onto the stack
; calls the _strLen function that returns the lenght of the string(str_test) in rdx
; rsi - stores the message location (to be printed/displayed)
;   r8 is stored in rsi accordingly
; rdx - stores the number of characters to be displayed
;   rdx stores itself (also works as a syscall)
; moving 0x02000004 to rax calls the write system call
; moving 1 to rdi, calls the stdout syscall
; returning the saved memory from stack back into rbp
; ret 8 - returns 8 bytes of free space from the stack
;   for better understanding, it pops off the last 8-bytes in the stack
_writeString:

    push rbp
    mov rbp, rsp

    mov r8, [rbp +16]
    push r8
    call _strLen
   ; mov rdi, rdx
    
    mov rsi, r8 ;; string to be printed 
    mov rdx, rdx ;; number of characters
   ; call _printf
    mov rax, 0x02000004 ; write system call
    mov rdi, 1 ; stdout sys call
    syscall
   
    pop rbp
    ret 8


;segment .text

;;Code for _strLen heavily influenced by this github project https://github.com/kubistika/irvine32-nasm/blob/master/kobi.asm

; saves the base pointer of the stack (rbp) in the stack
; stores the current pointer in the stack into rbp
; saves the register rdi in the stack
; [rbp + 16] stores the offset of string in memory
;   stores that offset into rdi
; rdx works as the counter for this case 
;   initializes rdx as 0
; .L1 
;   compares if rdi has reached the end of string 
;       the significance of declaring a 0 after the string variable can be shown here
;   if rdi == 0, then it jumps to the other loop .L2
;   increments the pointer location of rdi by 1
;   increments the value for rdx 
;       incrementing rdx tells us that a character has been found in the string
;   loops .L1 again
; .L2
;   restores the saved memory from the stack into rdi
;   restores the saved memory from the stack into rbp
;   ret 8 - returns 8 bytes of free space from the stack
;       for better understanding, it pops off the last 8-bytes in the stack
_strLen: 
    push rbp
    mov rbp, rsp
    push rdi
    
    mov rdi, [rel rbp +16]
    mov rdx, 0
.L1:
    cmp byte [rdi], 0
    je .L2 ; if 0 quit
    inc rdi
    inc rdx
    jmp .L1

.L2:

    pop rdi
    pop rbp

    ret 8



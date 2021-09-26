; Zakris Pierson and Nirjal Shakya 
; Copyright @ 2020  Zakris and Nirjal
; CS278 - Final Project
; source.asm for _setTextColor function from irvine library for NASM
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
;   Relevancy for ret 8 
    ;  <4> ret-2/4 and how it works - https://stackoverflow.com/questions/17628881/the-meaning-of-ret-2-in-assembly#:~:text=ret%204%20just%20returns%20like,to%20pop%20the%20previous%20pushes.&text=As%20alex%20said%2C%20it%20means%20RETURN
;   Relevancy for ColorCodes 
    ;   <5> Changing color of terminal - https://askubuntu.com/questions/558280/changing-colour-of-text-and-background-of-terminal
;

; to access the printf function from C library
extern _printf
global _main

section .data
; storing the string "hello world" in str_test
; the db signifies that the size is in byte 
; 0 signifies the end of a string
str_test db "hello world",0
; fmt provides the format for displaying hello world
; %s tells printf that the expected data is a string
fmt db "%s", 10, 0

section .text

_main:

;mov r8, 3739h ; value is reversed due to endianness so 97 is flipped to 79 in register
;mov r9, 3634h ; ; 46 once flipped
; <IMP NOTE> The number 97 translates to WHITE foreground color and stores two bytes worth of memory (9 & 7 are ints)
;       However, due to the endianness of variable and register, we reverse the hex codes from 3937h (97) to 3739h(79) 

; storing the value of the color hex-codes into rax
;   the two-byte hex codes are stored in al and ah inside rax, which gives us the feasibility to access color codes adjacent to it via 'inc'
;   here, rax stores 3739h(79) as 3937h(97)
mov rax, 3739h
;inc al
inc ah
; storing the value of the color hex-codes into rdx
;   the two-byte hex codes are stored in dl and dh inside rax, which gives us the feasibility to access color codes adjacent to it via 'inc'
;   here, rax stores 3634h(64) as 3436h(46 - CYAN)
mov rdx, 3634h
inc dh
; calls the _setTextColor function that sets the color of the displayed text 
call _setTextColor
; stores the first parameter for printf
;   which is the formatting for the string
; lea - load effective addressing 
; rel - relative address
lea rdi, [rel fmt]
; stores the second parameter for printf 
;   which is the string "hello world"
; lea - load effective addressing 
; rel - relative address
lea rsi, [rel str_test]
; we need to zero rax before we call printf
xor     rax, rax 
; <IMP NOTE> printf may destroy rax and rcx so if you're using either of these registers, save them using push
; calls _printf which sets the cursor to that particular coordinate on the screen
; <IMP NOTE> While calling printf, we need to pay attention to the stack
;   The stack should be 16-bit aligned (for 64-bit) i.e. it should be a multiple of 16 or 16 itself
call _printf
; exit
mov     rax, 0x2000001 ; exit
mov     rdi, 0
syscall

; <IMP NOTE> The collective string for printf will look like printf(ESC,"[00;00m") 
; strColor stores the hex-codes from ax (via [rel strColor2-2])
;   the 'word' pointer indicates that it's size is of word (2 bytes)
;   the [rel strColor2-2] location stores the hex-codes before the ';'
; strColor2 stores the hex-codes from dx (via [rel strColor2+1])
;   the 'word' pointer indicates that it's size is of word (2 bytes)
;   the [rel strColor2+1] location stores the hex-codes after the ';'
; <IMP NOTE> nasm works in a weird way. 
;   As the memories for the variables are right next to each other, strColor also has the values for strColor2 i.e we can access values from strColor from strColor2. 
;   Thus, it makes sense to store the first parameter as strColor as it also holds information from strColor2
; rdi stores the first parameter for printf
;   which is the formatting for the string
; lea - load effective addressing 
; rel - relative address 
; rsi stores the second parameter for printf, which in this case is nothing i.e. 0 
; we need to zero rax before we call printf
; calls _printf which sets the cursor to that particular coordinate on the screen
;   ret 8 - returns 8 bytes of free space from the stack
;       for better understanding, it pops off the last 8-bytes in the stack

_setTextColor:

section .data
; to tell the printf function that we're calling escape characters
ESC				equ 27
; strColor stores the initial formatting to set colors to the text
;   the 00 in strColor stores the Foregrund color
; ESC tells printf it's an escape character
strColor  db ESC, "[00"
; strColor2 stores background color for the text along with functionalities
;   ';' separates the Foreground color from Background color
;   '00' stores the hex-codes for Background color
;   'm' tells printf that it's the end of the statement
strColor2 db ";00m"

section .text

mov word [rel strColor2-2], ax ; flips 79 back to 97
mov word [rel strColor2+1], dx
lea rdi, [rel strColor]
mov rsi, 0
xor rax, rax
call _printf

ret 8





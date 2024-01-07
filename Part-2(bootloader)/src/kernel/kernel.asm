org 0x7C00
bits 16

%define ENDL 0x0D, 0x0A

start:
	jmp main
;printing a string
puts:
	;modifies the saved registers
	push si
	push ax
	
.loop:
	lodsb	;loads next character
	or al, al	;performs bitwise al to check if the next character is null
	jz .done	;conditional jump to the done lable if zero flag set
	mov ah, 0x0E        ; call bios interrupt
	mov bh, 0           ; set page number to 0
	int 0x10
	jmp .loop
	
.done:
	pop bx
	pop ax
	pop si
	ret

main:
	;setting up data segment
	
	mov ax, 0
	mov ds, ax
	mov es, ax
	
	;setting up stack
	mov ss, ax
	mov sp, 0x7C00
	
	mov si, msg
	call puts
	
	hlt
	
msg: db 'Hello', ENDL, 0

.halt:
	jmp .halt

times 510-($-$$) db 0
dw 0AA55h

org 0x7C00
bits 16

%define ENDL 0x0D, 0x0A

;Fat-12 headers

jmp short start
nop

bdb_oem:			db 'MSWIN4.1'		
bdb_bytes_per_sector:		dw 512			
bdb_sectors_per_cluster:	db 1
bdb_reserved_sectors:		dw 1
bdb_fat_count:			db 2
bdb_dir_entrcount:		dw 0E0h
bdb_total_sec:			dw 2880			;2880*512=1.44MB
bdb_media_desc_type:		db 0F0h
bdb_sec_per_fat:		dw 9
bdb_sec_per_track:		dw 18
bdb_head:			dw 2
bdb_hidden:			dd 0
bdb_large:			dd 0

;Extended Boot Record

ebr_drive_number:		db 0
				db 0
ebr_signature:			db 29h
ebr_volume_id:			db 12h, 34h, 56h, 78h
ebr_volume_lable:		db 'Prototype OS'
ebr_system_id:			db 'FAT-12'

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
	
	mov [ebr_drive_number], dl
	mov ax, 1
	mov cl, 1
	mov bx, 0x7E00
	call disk_read
	
	
	mov si, msg
	call puts
	cli
	hlt
	
msg: db 'Prototype OS', ENDL, 0
msg_fail: db 'Failed to read from the disk', ENDL, 0

floppy_error:
	mov si, msg_fail
	call puts
	jmp wait_key_reboot
	
wait_key_reboot:
	mov ah, 0
	int 16h
	jmp 0FFFFh:0

.halt:
	cli
	hlt
	
;disk routines

lba_to_chs:
	push ax
	push dx
	xor dx, dx
	div word [bdb_sec_per_track]
	inc dx
	mov cx, dx
	xor dx, dx
	div word [bdb_head]
	mov dh, dl
	mov ch, al
	shl ah, 6
	or al, ah
	pop ax
	mov dl, al
	pop ax
	ret
	
disk_read:
	push ax
	push bx
	push cx
	push dx
	push di
	
	push cx
	call lba_to_chs
	pop ax
	mov ah, 02h
	mov di, 3
	
.retry:
	pusha
	stc
	int 13h
	jnc .done
	
	popa
	call disk_reset
	
	dec di
	test di, di
	jnz .retry
	
.fail:
	jmp floppy_error
	
.done:
	popa
	pop di
	pop dx
	pop cx
	pop bx
	pop ax
	ret
	
disk_reset:
	pusha
	mov ah, 0
	stc
	int 13h
	jc floppy_error
	popa
	ret

times 510-($-$$) db 0
dw 0AA55h

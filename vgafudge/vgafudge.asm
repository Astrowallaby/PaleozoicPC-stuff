.8086 ; cpu type
.model tiny ; tiny
;=======================================
; Program: ems2umb.asm
;
; Based on Jeffrey L. Hayes' "VGAFIX", hacked by Eudimorphodon
; to run from either command line or config.sys.
; config.sys functionality based on skeleton code found on pastebin.com
; https://pastebin.com/w2Dh5SNZ
;
; This is a modification of
;====================================== Macros
;
disp_str macro  str_ofs
	mov     ah, 09h
	mov     dx, offset str_ofs
	int     21h
	endm


;========================================================== MAIN CODE
;
code    segment use16
	assume  cs:code, ds:code
	org     0000h


;====================================== Device driver header
;
header  dw      0ffffh, 0ffffh    ;Link to next driver
	dw      0000000000000000b ;Driver attribute
	dw      offset strategy   ;Pointer to strategy routine
				  ;(first called)
	dw      offset interrupt  ;Pointer to interrupt routine
				  ;(called after strategy)
	db      'EXESYS$$'        ;Driver name

db_ptr  dw      0000h, 0000h      ;Address of device request header


;====================================== SYS Strategy proc
;
strategy proc
	push    ax
	mov     cs:db_ptr, bx     ;Set data block address in
	mov     cs:db_ptr+02h, es ;the DB_PTR variable
;        mov     cs:rcs, cs
;        mov     cs:rss, ss
	mov     ax, sp
	add     ax, 0004h
;        mov     cs:rsp, ax
	pop     ax
	retf
strategy endp

;====================================== SYS Interrupt proc
;
interrupt proc
	pushf                               ;Save registers
	push    ax
	push    cx
	push    dx
	push    bx
	push    bp
	push    si
	push    di
	push    ds
	push    es
	push    cs                          ;Set data segment
	pop     ds
	les     di, dword ptr db_ptr        ;Data block address after ES:DI
	mov     ax, 8003h                   ;executed by error
	cmp     byte ptr es:[di+02h], 00h   ;Only INIT is permitted
	jne     intr_end                    ;Error --> Return to caller
	mov     word ptr es:[di+0eh], 0000h ;Set end address of driver
	mov     es:[di+10h], cs
	push    es
	push    di
	call    sys_start                   ;Can only be function 00H
	pop     di
	pop     es
intr_end:
	mov     ax, 0100h                   ;Return 'Operation Complete'
	mov     es:[di+03h], ax             ;Set status field
	pop     es                          ;Restore registers
	pop     ds
	pop     di
	pop     si
	pop     bp
	pop     bx
	pop     dx
	pop     cx
	pop     ax
	popf
	retf
interrupt endp

;====================================== SYS proc
;
sys_start proc
	disp_str dd_msg
	push dx
	MOV     AX,40h
	      MOV       DS,AX
	MOV   BP,8Ah
	MOV     BYTE PTR [BP],08h
	MOV     AX,1A01h
	MOV     BX,8
	INT     10h
	pop dx
	ret
sys_start endp

;====================================== EXE proc
;
exe_start proc
	push    cs
	pop     ds
	disp_str exe_msg
	MOV     AX,40h
	      MOV       DS,AX
	MOV   BP,8Ah
	MOV   BYTE PTR [BP],08h
	MOV     AX,1A01h
	MOV     BX,8
	INT     10h
	mov     ax, 4C00h
	int     21h
exe_start endp


;====================================== Data section
;
dd_msg  db      'Paleozoic PCs Tandy 1000 VGA Fudger. Running from config.sys...', 0dh, 0ah, '$'
exe_msg db      'Paleozoic PCs Tandy 1000 VGA Fudger. Running from command prompt...', 0dh, 0ah, '$'

code    ends



	end     exe_start

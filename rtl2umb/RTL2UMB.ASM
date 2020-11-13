.8086 ; cpu type
;=======================================
; Program: rtl2umb.asm
;
; By Davide Bresolin
; based on Eudimorphodon's ems2umb.asm, originally
; based on skeleton code found on pastebin.com
; https://pastebin.com/w2Dh5SNZ
; ParseToken and HexToStr functions based on atoh2/hextoa functions from 
; the UCR Standard Library for 80x86 Assembly Language Programmers
; plantation-production.com/Webster/www.artofasm.com/DOS/Software.html
;
; The program enables memory write operations for the RTL8019AS
; "flash ROM" chip and exits. With a SRAM chip placed in the socket
; with the correct wiring this adds 16-64Kb UMB.
; No testing is performed; verify card works first.
; Set the size and position of the UMB with RSET8019.EXE
;
;====================================== Macros
;
disp_str	macro  	str_ofs		; Print $-terminated string at str_ofs
        	mov     ah, 09h
        	mov     dx, offset str_ofs
        	int     21h
        	endm

;==================================================== MAIN CODE
;
code    segment use16
        assume  cs:code, ds:code
        org     0000h

; Equates into command line
CmdLnLen	equ		byte ptr es:[80h]	; Command line length
CmdLn		equ		word ptr es:[81h]	; Command line data
tab			equ		09h					
cr			equ		0Dh

;====================================== Device driver header
;
header  dw      0ffffh, 0ffffh    	;Link to next driver
        dw      0000000000000000b 	;Driver attribute
        dw      offset strategy   	;Pointer to strategy routine
                                  	;(first called)
        dw      offset interrupt  	;Pointer to interrupt routine
                                  	;(called after strategy)
        db      'EXESYS$$'        	;Driver name

db_ptr  dd      0000h     			;Address of device request header


;====================================== SYS Strategy proc
;
strategy proc
        mov     word ptr cs:db_ptr, bx     	; Set data block address in
        mov     word ptr cs:db_ptr+02h, es 	; the DB_PTR variable
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
        push    cs                       ;Set data segment
        pop     ds
        les     di, dword ptr db_ptr        ;Data block address after ES:DI
        mov     ax, 8103h                   ;executed by error
        cmp     byte ptr es:[di+02h], 00h   ;Only INIT is permitted
        jne     intr_end                    ;Error --> Return to caller
		mov		word ptr es:[di+0dh], 0h	;Say zero units
        mov     word ptr es:[di+0eh], 0000h ;Set end address of driver
        mov     es:[di+10h], cs
        push    es
        push    di
        call    sys_start                   ;Can only be function 00H
        pop     di
        pop     es
        mov     ax, 0100h                   ;Return 'Operation Complete'
intr_end:
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

;===================== RTLEnableWrite ============================
; This procedure enables the "flash write operation" of RTL8019AS
; by writing the magic sequence 057h 0A8h to the FMWP register.
; The base I/O address of the card is in regbase
RTLEnableWrite proc
        push dx
        mov dx,regbase      ; Read Configuration Register
        in  al,dx
        or  al,0C0h         ; Select register page 3
        out dx,al
        inc dx              ; Read Command Register (regbase + 1)
        in  al,dx
        or  al,0C0h         ; Set Config register write enable
        out dx,al
        add dx,0Bh          ; Select Flash Memory Write Protect Register
        mov al,057h
        out dx,al           ; write magic bytes to enable write operations
        mov al,0A8h
        out dx,al
        mov dx,regbase      ; Read Command Register (regbase + 1)
        inc dx
        in  al,dx
        and al,03Fh         ; Disable Config register write enable
        out dx,al
        mov dx,regbase      ; Read Configuration Register
        in  al,dx
        and al,03Fh         ; Select register page 0
        out dx,al
        pop dx
		ret
RTLEnableWrite endp

;====================================== SkipBlanks proc ==================
; Skips over leading blanks on the command line. It does not, however,
; skip the carriage return at the end of the line since this character
; is used as the terminator of the command line.
; 
SkipBlanks	proc 	near
			dec		bx				; to offset inc bx below
sbLoop:		inc		bx				; move to next character
			mov		al, es:[bx]	   	; get next character
			cmp		al, ' '			; repeat if space
 			jz		sbLoop			
			cmp		al, tab			; repeat if tab
			jz		sbLoop
			ret
SkipBlanks	endp

;====================================== NextBlank proc ==================
; Moves to the first non-blank character in the string at ES:BX. 
; It does not, however, skip the carriage return at the end of the line 
; since this character is used as the terminator of the command line.
; 
NextBlank	proc 	near
			dec		bx				; to offset inc bx below
nbLoop:		inc		bx				; move to next character
			mov		al, es:[bx]	   	; get next character
			cmp		al, ' '			; return if space
 			jz		nbQuit			
			cmp		al, tab			; return if tab
			jz		nbQuit
			cmp		al, cr			; return if carriage return
			jnz		nbLoop
nbQuit:		ret
NextBlank	endp


;====================================== ParseToken proc	==================
; Parse a token in the command line to get the base I/O address.
; The I/O address is returned in the register CX. 
; Returns with the carry flag clear if no error, set if overflow.
;
ParseToken	proc	near
			pushf
			cld
			xor	cx, cx
			dec	bx
CnvrtLp:	inc	bx
			mov	al, es:[bx]
			cmp	al, 'a'
			jb	SkipCnvrt
			and	al, 5fh
;
SkipCnvrt:	xor	al, '0'
			cmp	al, 10
			jb	GotDigit
			add	al, 89h				;A->0fah.
			cmp	al, 0fah
			jb	Done
			and	al, 0fh				;0fa..0ff->a..f
GotDigit:	shl	cx, 1				;Make room for new
			jc	Overflow			; nibble.
			shl	cx, 1
            jc	Overflow
			shl	cx, 1
            jc	Overflow
			shl	cx, 1
			jc	Overflow
			or	cl, al				;Add in new nibble.
			jmp	CnvrtLp
;
Overflow:	stc
			jmp	short WasError
;
Done:		clc
WasError:	popf
			ret
ParseToken	endp
			

;====================================== ParseCmdLn proc	==================
; Parse the command line at ES:BX. Returns the base address in regbase 
; if found. Sets the carry flag if error.
;
ParseCmdLn	proc	near
			call	SkipBlanks		; skip over leading blanks
			mov		al, es:[bx]		; get next character
			cmp		al, cr			; Carriage return?
			je		parseErr		; terminate with a message error if cr 
			call	ParseToken		; parse command line token
			jc		parseErr		; terminate if parse error
			mov		regbase, cx		; save I/O address
 			call	SkipBlanks		; skip over trailing blanks
			cmp		al, cr			; Carriage return?
			je		parseQuit		; terminate with no error if cr
parseErr:	stc						; set carry flag to report error
parseQuit:	ret
ParseCmdLn	endp			 


;====================================== HexToStr proc	==================
; Converts value in AL to a string of length two containing two
; hexadecimal characters. Stores result into string at address DI.
; At return DI points to the next character in the string.
; 
HexToStr	proc	near
			push	ax
			mov	ah, al
			shr	al, 1
			shr	al, 1
			shr	al, 1
			shr	al, 1
			cmp	al, 0ah		;Magic sequence to convert 0-F to
			sbb	al, 69h		; "0"-"F".  By DGH
			das
			mov	[di], al
			inc	di
			mov	al, ah
			and	al, 0fh
			cmp	al, 0ah		;See above comment
			sbb	al, 69h
			das
			mov	[di], al
			inc	di
			pop	ax
			ret
HexToStr	endp



;====================================== SYS proc
;
sys_start 	proc
        	disp_str dd_msg
			les		bx, [db_ptr]	; set ES:BX to device request header
			les		bx, es:[bx+18]	; set ES:BX to command line
			call	NextBlank		; Skip the filename in the command line
			call	ParseCmdLn		; Parse command line
			jc		sysUsage		; show usage message if parse error
			call	RTLEnableWrite	
			mov		ax, regbase		; put I/O address in AX
			xchg	ah, al			; swap bytes
			mov		di, offset cs_msg2	; points to address in message string
			call	HexToStr		; convert high byte to text
			xchg	ah, al			; swap bytes
			call	HexToStr		; convert low byte to text
			disp_str cs_msg			; display success message
			jmp		sysQuit
sysUsage:	disp_str usage_msg
sysQuit: 	ret
sys_start 	endp

;====================================== EXE proc
;
exe_start 	proc
			push	ds				; save PSP value
        	mov		ax, cs			; point DS at the code segment
	        mov		ds, ax	
	        disp_str exe_msg
			pop		es				; store PSP value into es
			lea		bx, CmdLn		; point at command line
			call	ParseCmdLn		; Parse command line
			jc		exeUsage		; show usage message if parse error
			call	RTLEnableWrite	
			mov		ax, regbase		; put I/O address in AX
			xchg	ah, al			; swap bytes
			mov		di, offset cs_msg2	; points to address in message string
			call	HexToStr		; convert high byte to text
			xchg	ah, al			; swap bytes
			call	HexToStr		; convert low byte to text
			disp_str cs_msg			; display success message
			jmp		exeQuit
exeUsage:	disp_str usage_msg
exeQuit:    mov		ax, 4C00h
	        int     21h
exe_start 	endp


;====================================== Data section
;
regbase 	dw      0000h

dd_msg  	db      'RTL8019AS Handy Dandy SRAM enabler. Running from config.sys...', 0dh, 0ah, '$'
exe_msg 	db      'RTL8019AS Handy Dandy SRAM enabler. Running from command prompt...', 0dh, 0ah, '$'
usage_msg	db		'Usage: RLT2UMB.EXE IO_Address', 0dh, 0ah, '$'
cs_msg  	db      'Write operations enabled for RTL8019AS @'
cs_msg2		db		'$$$$h. Enjoy your RAM!', 0dh, 0ah, '$'
code    ends



        end     exe_start

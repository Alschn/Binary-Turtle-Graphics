;---------------------------------------------------------------------------------
; x86 32bit Project - ARKO 20L
; Binary Turtle Graphics - works on linux servers with NASM and gcc (see makefile)
; Adam Lisichin
;---------------------------------------------------------------------------------
section .text

; extern int exec_turtle_cmd(unsigned char *dest_bitmap, unsigned char *command, TurtleContextStruct *tc);
global exec_turtle_cmd
exec_turtle_cmd:
        ; prolog
        push ebp
        mov ebp, esp

        push ebx
        push edi
        push esi

        ; return code
        mov eax, 0

       ;  if middle of set pos cmd, do nothing
        mov esi, DWORD [ebp+16] ; address of *tc to ESI //
        mov bl, BYTE [esi+13]   ; load tc->is_setpos into BL
        cmp bl, 0
        jz not_setpos
        mov BYTE [esi+13], 0    ; reset tc->is_setpos
        or eax, 32              ; return code += inside set position
        jmp finish

not_setpos:
        ;  load command
        mov ecx, DWORD [ebp+12]     ;address of *command to ECX
        xor ebx, ebx            ; ebx clear
        mov bx, WORD [ecx]      ; load command into BX
        rol bx, 8               ; byte swap

        ; instr extraction
        mov edx, ebx
        and edx, 0x00000003

        ; instr switch
        cmp edx, 0          ; set pen state?
        jz instr_00
        cmp edx, 1          ; move?
        jz instr_01
        cmp edx, 2          ; set_direction?
        jz instr_10
        cmp edx, 3          ; set_position?
        jz instr_11

;===============COMMAND SET_PEN_STATE========================;
instr_00:
        ; tc->up/down
        mov dl, bl
        shr dl, 3
        and dl, 1
        mov [esi+11], dl
        ; tc->blue
        and bl, 0xF0
        mov [esi+8], bl
        ; tc->green
        shr bx, 4
        and bl, 0xF0
        mov [esi+9], bl
        ; tc->red
        shr bx, 4
        and bl, 0xF0
        mov [esi+10], bl

        jmp finish


;===============COMMAND: MOVE===============================;
instr_01:
        ; dist
        shr ebx, 6
        mov ecx, ebx

        ; dir switch
        mov dl, BYTE [esi+12]
        cmp dl, 2           ; go left
        jz go_left
        cmp dl, 1           ; go up
        jz go_up
        cmp dl, 3           ; go down
        jz go_down
        ; else go_right

        ; dist verification
        mov edi, DWORD [ebp+8]      ; address of *dest_bitmap to EDI
        mov edx, DWORD [edi+18]     ; get width from BMP header
        dec edx
        sub edx, DWORD [esi]
        cmp ecx, edx
        jbe go_right_dist_LE_max    ; LE = less or equal
        mov ecx, edx
        or eax, 5                   ; return code += go right dist too big
go_right_dist_LE_max:
        ; pen up/down ?
        mov dl, BYTE [esi+11]
        cmp dl, 1
        jz go_right_paint
        ; pen up
        add [esi], ecx      ; new tc->x
        jmp finish

go_right_paint:
        ; pixel address determination
        mov ebx, DWORD [edi+18]
        lea ebx, [ebx + 2 * ebx + 3]
        and ebx, 0xFFFFFFFC
        push eax
        mov eax, DWORD [esi+4]
        mul ebx
        add edi, 54
        add edi, eax
        pop eax
        mov edx, DWORD [esi]
        lea edx, [edx + 2 * edx]
        add edi, edx

        add [esi], ecx      ; new tc->x

        ; line painting
        mov esi, DWORD [esi+8]      ; pen state (colors)
        inc ecx
go_right_paint_loop:
        mov edx, esi
        mov BYTE [edi], dl
        shr edx, 8
        mov BYTE [edi+1], dl
        shr edx, 8
        mov BYTE [edi+2], dl
        add edi, 3
        loop go_right_paint_loop

        jmp finish


go_left:
        ; dist verification
        mov edx, DWORD [esi]

        cmp ecx, edx
        jbe go_left_dist_LE_max
        mov ecx, edx
        or eax, 9                   ; return code += go left dist too big

go_left_dist_LE_max:
        ; pen up/down ?
        mov dl, BYTE [esi+11]
        cmp dl, 1
        jz go_left_paint
        ; pen up
        sub [esi], ecx      ; new tc->x
        jmp finish

go_left_paint:
        ; pixel address determination
        mov edi, DWORD [ebp+8]      ; address of *dest_bitmap to EDI

        mov ebx, DWORD [edi+18]
        lea ebx, [ebx + 2 * ebx + 3]
        and ebx, 0xFFFFFFFC
        push eax
        mov eax, DWORD [esi+4]
        mul ebx
        add edi, 54
        add edi, eax
        pop eax
        mov edx, DWORD [esi]
        lea edx, [edx + 2 * edx]
        add edi, edx

        sub [esi], ecx      ; new tc->x

        ; line painting
        mov esi, DWORD [esi+8]      ; pen state (colors)
        inc ecx
go_left_paint_loop:
        mov edx, esi
        mov BYTE [edi], dl
        shr edx, 8
        mov BYTE [edi+1], dl
        shr edx, 8
        mov BYTE [edi+2], dl
        sub edi, 3
        loop go_left_paint_loop

        jmp finish


go_up:
        mov edi, DWORD [ebp+8]      ; address of *dest_bitmap to EDI
        mov edx, DWORD [edi+22]     ; get height from BMP header
        dec edx
        sub edx, DWORD [esi+4]

        cmp ecx, edx
        jbe go_up_dist_LE_max
        mov ecx, edx
        or eax, 6                   ; return code += go up dist too big
go_up_dist_LE_max:
        mov dl, BYTE [esi+11]
        cmp dl, 1
        jz go_up_paint
        add [esi+4], ecx      ; new tc->y
        jmp finish
go_up_paint:
        mov ebx, DWORD [edi+18]
        lea ebx, [ebx + 2 * ebx + 3]
        and ebx, 0xFFFFFFFC
        push eax
        mov eax, DWORD [esi+4]
        mul ebx
        add edi, 54
        add edi, eax
        pop eax
        mov edx, DWORD [esi]
        lea edx, [edx + 2 * edx]
        add edi, edx

        add [esi+4], ecx      ; new tc->y

        mov esi, DWORD [esi+8]
        inc ecx
go_up_paint_loop:
        mov edx, esi
        mov BYTE [edi], dl
        shr edx, 8
        mov BYTE [edi+1], dl
        shr edx, 8
        mov BYTE [edi+2], dl
        add edi, ebx
        loop go_up_paint_loop

        jmp finish

go_down:
        mov edx, DWORD [esi+4]

        cmp ecx, edx
        jbe go_down_dist_LE_max
        mov ecx, edx
        or eax, 10                   ; return code += go down dist too big
go_down_dist_LE_max:
        mov dl, BYTE [esi+11]
        cmp dl, 1
        jz go_down_paint
        sub [esi+4], ecx      ; new tc->y
        jmp finish
go_down_paint:
        mov edi, DWORD [ebp+8]      ; address of *dest_bitmap to EDI

        mov ebx, DWORD [edi+18]
        lea ebx, [ebx + 2 * ebx + 3]
        and ebx, 0xFFFFFFFC
        push eax
        mov eax, DWORD [esi+4]
        mul ebx
        add edi, 54
        add edi, eax
        pop eax
        mov edx, DWORD [esi]
        lea edx, [edx + 2 * edx]
        add edi, edx

        sub [esi+4], ecx      ; new tc->y

        mov esi, DWORD [esi+8]
        inc ecx
go_down_paint_loop:
        mov edx, esi
        mov BYTE [edi], dl
        shr edx, 8
        mov BYTE [edi+1], dl
        shr edx, 8
        mov BYTE [edi+2], dl
        sub edi, ebx
        loop go_down_paint_loop

         jmp finish


;===============COMMAND SET_DIRECTION========================;
instr_10:
        ; tc->dir
        shr bx, 14
        mov [esi+12], bl
        jmp finish

;===============COMMAND SET_POSITION========================;
instr_11:       ; set_position
        mov BYTE [esi+13], 1        ; set tc->is_setpos

        ; new y verification
        mov edi, DWORD [ebp+8]      ; address of *dest_bitmap to EDI
        mov edx, DWORD [edi+22]     ; get height from BMP header
        dec edx
        shr bx, 2
        and ebx, 0x0000003F
        cmp ebx, edx
        jbe y_LE_h
        mov ebx, edx
        or eax, 2                   ; return code += Y too big
y_LE_h:
        mov DWORD [esi+4], ebx      ; new tc->y

        ; new x get and verification
        mov edx, DWORD [edi+18]     ; get width from BMP header
        dec edx
        mov bx, WORD [ecx+2]        ; load 2nd part of SETPOS command into BX
        rol bx, 8                   ; byte swap
        and ebx, 0x000003FF
        cmp ebx, edx
        jbe x_LE_w
        mov ebx, edx
        or eax, 1                   ; return code += X too big
x_LE_w:
        mov DWORD [esi], ebx        ; new tc->x


;===================FINISH========================;
finish:
        ; epilog
        pop esi
        pop edi
        pop ebx

        pop ebp
        ret

; Krawczyk Bartłomiej
; ARKO - projekt x86_64
; Skalowanie obrazu wykorzystując interpolację dwuliniową

; scale(void *img, int width, int height, void *scaledImg, int newWidth, int newHeight);

; img - rdi
; width - rsi
; height - rdx
; scaledImg - rcx
; newWidth - r8
; newHeight - r9
;=======================
; widthBytes - [rbp-4]
; newWidthBytes - [rbp-8]

section	.text
global scale

scale:
    ;prolog
    push rbp
    mov rbp, rsp
    sub rsp, 40

    push rbx
    push r12
    push r13
    push r14
    push r15
    
    movdqu  [rbp-24], xmm6
    movdqu  [rbp-40], xmm7


    cvtsi2ss xmm6, esi
    cvtsi2ss xmm5, r8d
    divss xmm6, xmm5            ; 1/scaleX = width / newWidth

    mov r15, rdx

    cvtsi2ss xmm7, edx
    cvtsi2ss xmm5, r9d
    divss xmm7, xmm5            ; 1/scaleY = height / newHeight

    mov eax, esi
    and eax, 3
    lea r10d, [esi+esi*2]
    add r10d, eax
    mov [rbp-4], r10d           ; row width in bytes

    mov eax, r8d
    and eax, 3
    lea r10d, [r8d+r8d*2]
    add r10d, eax
    mov [rbp-8], r10d           ; new row width in bytes

    xor r14, r14                ; x = 0
    xor rbx, rbx                ; y = 0

    dec rsi
    dec r15
loop:
    cvtsi2ss xmm0, r14          ; float(x)
    cvtsi2ss xmm1, rbx          ; float(y)
    mulss xmm0, xmm6            ; float(x) / scaleX
    mulss xmm1, xmm7            ; float(y) / scaleY

    cvttss2si r12d, xmm0        ; int(x / scaleX)
    cvttss2si r13d, xmm1        ; int(y / scaleY)

    cmp r12d, esi
    jb less_x
    cvtsi2ss xmm0, esi
    mov r12d, esi
less_x:

    cmp r13d, r15d
    jb less_y
    cvtsi2ss xmm1, r15d
    mov r13d, r15d
less_y:

    cvtsi2ss xmm2, r12d
    cvtsi2ss xmm3, r13d

    subss xmm0, xmm2            ; dx
    subss xmm1, xmm3            ; dy

    ;calculation
    mov eax, r13d
    mul DWORD [rbp-4]

    lea r10d, [r12d+r12d*2]
    add r10d, eax               ; first pixel position
    add r10, rdi                ; first pixel address

    mov eax, [rbp-4]
    mov r11, r10
    add r11, rax                ; third pixel address

    mov eax, ebx
    mul DWORD [rbp-8]
    lea r13d, [r14d+r14d*2]

    add r13d, eax               ; new pixel position
    add r13, rcx                ; new pixel address

    xor r12, r12                ; loop count = 0
loop_color:

    movzx edx, BYTE [r10+r12]          ; c00
    cvtsi2ss xmm2, edx
    movzx edx, BYTE [r10+r12+3]        ; c10
    cvtsi2ss xmm3, edx

    movzx edx, BYTE [r11+r12]          ; c01
    cvtsi2ss xmm4, edx
    movzx edx, BYTE [r11+r12+3]        ; c11
    cvtsi2ss xmm5, edx

    ; calculate new color

    subss xmm3, xmm2
    mulss xmm3, xmm0
    addss xmm3, xmm2            ; cx0 = c00 + (c10 - c00) * dx

    subss xmm5, xmm4
    mulss xmm5, xmm0
    addss xmm5, xmm4            ; cx1 = c01 + (c11 - c01) * dx

    subss xmm5, xmm3
    mulss xmm5, xmm1
    addss xmm5, xmm3            ; cxy = cx0 + (cx1 - cx0) * dy

    cvttss2si edx, xmm5         ; new color

    ; set new color
    mov [r13+r12], dl         

    inc r12
    cmp r12, 3
    jnz loop_color

    inc r14                     ; x += 1
    cmp r14, r8
    jnz loop                    ; jump if x != newWidth

    inc rbx                     ; y += 1
    xor r14, r14                ; x = 0
    cmp rbx, r9
    jnz loop                    ; jump if y != newHeight


    ;restore
    movdqu  xmm6, [rbp-24]
    movdqu  xmm7, [rbp-40]

    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx

	;epilog
    mov rsp, rbp
    pop rbp
    ret

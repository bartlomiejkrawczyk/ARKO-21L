; Krawczyk Bartłomiej
; ARKO - projekt x86
; Skalowanie obrazu wykorzystując interpolację dwuliniową

; scale(void *img, int width, int height, void *scaledImg, int newWidth, int newHeight);

; img - [ebp + 8]
; width - [ebp + 12]
; height - [ebp + 16]
; scaledImg - [ebp + 20]
; newWidth - [ebp + 24]
; newHeight - [ebp + 28]
;=======================
; widthBytes - [ebp - 4]
; x - [ebp - 8]
; y - [ebp - 12]q
; newWidthBytes - [ebp - 16]
; firstPixelPos - [ebp - 20]
; thirdPixelPos - [ebp - 24]

section	.text
global  _scale, scale

_scale:
scale:
    ;prolog
    push ebp
    mov ebp, esp
    sub esp, 24                 ; (LOCAL_DATA_SIZE + 3) & ~3 ;

    push ebx
    push esi
    push edi


    movss xmm6, [ebp+12]
    divss xmm6, [ebp+24]        ; 1/scaleX = width / newWidth


    movss xmm7, [ebp+16]
    divss xmm7, [ebp+28]        ; 1/scaleY = height / newHeight

    mov ebx, [ebp+12]
    mov esi, ebx
    and esi, 3
    lea ebx, [ebx + ebx * 2]
    add ebx, esi
    mov [ebp-4], ebx            ; row width in bytes

    mov ebx, [ebp+24]
    mov esi, ebx
    and esi, 3
    lea ebx, [ebx + ebx * 2]
    add ebx, esi
    mov [ebp-16], ebx           ; new row width in bytes

    mov [ebp-8], DWORD 0        ; x = 0
    mov [ebp-12], DWORD 0       ; y = 0

    dec DWORD [ebp+12]
    dec DWORD [ebp+16]
loop:

    cvtsi2ss xmm0, [ebp-8]      ; float(x)
    cvtsi2ss xmm1, [ebp-12]     ; float(y)
    mulss xmm0, xmm6            ; float(x) / scaleX
    mulss xmm1, xmm7            ; float(y) / scaleY

    cvttss2si edi, xmm0         ; int(x / scaleX)
    cvttss2si ecx, xmm1         ; int(y / scaleY)

    cmp edi, [ebp+12]
    jb less_x
    cvtsi2ss xmm0, [ebp+12]
    mov edi, [ebp+12]
less_x:

    cmp ecx, [ebp+16]
    jb less_y
    cvtsi2ss xmm1, [ebp+16]
    mov ecx, [ebp+16]
less_y:


    cvtsi2ss xmm2, edi
    cvtsi2ss xmm3, ecx

    subss xmm0, xmm2            ; dx
    subss xmm1, xmm3            ; dy

    ;calculation
    mov eax, ecx
    mul DWORD [ebp-4]


    lea ebx, [edi + edi * 2]
    mov [ebp-20], ebx
    add [ebp-20], eax           ; first pixel position

    add eax, [ebp-4]

    mov [ebp-24], ebx
    add [ebp-24], eax           ; third pixel position


    mov eax, [ebp-12]
    mul DWORD [ebp-16]
    mov esi, [ebp-8]
    lea esi, [esi + esi * 2]

    add esi, eax                ; new pixel

    xor edi, edi                ; loop count = 0
loop_color:
    mov eax, [ebp + 8]
    mov ebx, eax

    add eax, [ebp-20]
    add ebx, [ebp-24]

    movzx ecx, BYTE [eax + edi]         ; c00
    cvtsi2ss xmm2, ecx
    movzx ecx, BYTE [eax + edi + 3]     ; c10
    cvtsi2ss xmm3, ecx

    movzx ecx, BYTE [ebx + edi]         ; c01
    cvtsi2ss xmm4, ecx
    movzx ecx, BYTE [ebx + edi + 3]     ; c11
    cvtsi2ss xmm5, ecx

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

    cvttss2si ecx, xmm5

    ; set new color
    mov eax, [ebp + 20]
    add eax, esi
    mov [eax + edi], cl         ; new color

    inc edi
    cmp edi, 3
    jnz loop_color

    inc DWORD [ebp-8]           ; x += 1
    mov ebx, [ebp-8]
    cmp ebx, [ebp+24]
    jnz loop                    ; jump if x != newWidth

    inc DWORD [ebp-12]          ; y += 1
    mov esi, [ebp-12]
    mov [ebp-8], DWORD 0        ; x = 0
    cmp esi, [ebp+28]
    jnz loop                    ; jump if y != newHeight

	;epilog
	pop edi
    pop esi
    pop ebx

    mov esp, ebp
    pop ebp
    ret

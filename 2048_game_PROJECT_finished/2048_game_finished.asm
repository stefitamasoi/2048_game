.586
.model flat, stdcall
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;includem biblioteci, si declaram ce functii vrem sa importam
includelib msvcrt.lib
extern exit: proc
extern malloc: proc
extern memset: proc
extern rand: proc
extern srand: proc
extern time: proc

includelib canvas.lib
extern BeginDrawing: proc
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;declaram simbolul start ca public - de acolo incepe executia
public start
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;sectiunile programului, date, respectiv cod
.data
;aici declaram date
window_title DB "Exemplu proiect desenare",0
area_width EQU 640
area_height EQU 480
area DD 0

st_p dd 0
end_p dd 0
step dd 0 
set dd 0
deja_gen dd 0

patru dd 4
d_16 dd 16

; mat dd  2, 0, 0, 2, 
		; 0, 2, 0, 1, 
		; 1, 1, 1, 1,
		; 3, 0, 0, 1 
mat dd 16 dup(0)

num_width equ 43
num_height equ 43
nums_sz dd 43
colors dd 0ffffffh, 0ffffffh, 0ffffffh, 0de1804h, 0c1e1f9h 

over dd 0

counter DD 0 ; numara evenimentele de tip timer

arg1 EQU 8
arg2 EQU 12
arg3 EQU 16
arg4 EQU 20


symbol_width EQU 10
symbol_height EQU 20
include digits.inc
include letters.inc
include nums.inc

.code
nr_nou proc  ; alegem o casuta goala pt a pune un nou "2"
	pusha
	
    call rand
	mov ebx, 0
	mov ecx, eax
	
	try_next:
	
	mov eax, ecx
	add eax, ebx
	mov edx, 0
	div d_16
	
	cmp mat[edx*4], 0
	je asign
	
	inc ebx
	jmp try_next
	
	asign:
	
	mov mat[edx*4], 1
	
	end_nr_nou:
	popa
	ret
nr_nou endp
; procedura make_text afiseaza o litera sau o cifra la coordonatele date
; arg1 - simbolul de afisat (litera sau cifra)
; arg2 - pointer la vectorul de pixeli
; arg3 - pos_x
; arg4 - pos_y
make_text proc
	push ebp
	mov ebp, esp
	pusha
	
	mov eax, [ebp+arg1] ; citim simbolul de afisat
	cmp eax, 'A'
	jl make_digit
	cmp eax, 'Z'
	jg make_digit
	sub eax, 'A'
	lea esi, letters
	jmp draw_text
make_digit:
	cmp eax, '0'
	jl make_space
	cmp eax, '9'
	jg make_space
	sub eax, '0'
	lea esi, digits
	jmp draw_text
make_space:	
	mov eax, 26 ; de la 0 pana la 25 sunt litere, 26 e space
	lea esi, letters
	
draw_text:
	mov ebx, symbol_width
	mul ebx
	mov ebx, symbol_height
	mul ebx
	add esi, eax
	mov ecx, symbol_height
bucla_simbol_linii:
	mov edi, [ebp+arg2] ; pointer la matricea de pixeli
	mov eax, [ebp+arg4] ; pointer la coord y
	add eax, symbol_height
	sub eax, ecx
	mov ebx, area_width
	mul ebx
	add eax, [ebp+arg3] ; pointer la coord x
	shl eax, 2 ; inmultim cu 4, avem un DWORD per pixel
	add edi, eax
	push ecx
	mov ecx, symbol_width
bucla_simbol_coloane:
	cmp byte ptr [esi], 0
	je simbol_pixel_alb
	mov dword ptr [edi], 0
	jmp simbol_pixel_next
simbol_pixel_alb:
	mov dword ptr [edi], 0FFFFFFh
simbol_pixel_next:
	inc esi
	add edi, 4
	loop bucla_simbol_coloane
	pop ecx
	loop bucla_simbol_linii
	popa
	mov esp, ebp
	pop ebp
	ret
make_text endp

; un macro ca sa apelam mai usor desenarea simbolului
make_text_macro macro symbol, drawArea, x, y
	push y
	push x
	push drawArea
	push symbol
	call make_text
	add esp, 16
endm

line_horizontal macro x, y, len, color
local bucla_line
	mov eax, y ; eax=y
	mov ebx, area_width
	mul ebx ;eax = y * area_width
	add eax, x ;eax = y * area_width * x
	shl eax, 2 ;(eax = y * area_width * x) * 4
	add eax, area
	mov ecx, len
bucla_line:
	mov dword ptr[eax], color
	add eax, 4
	loop bucla_line
endm

line_vertical macro x, y, len, color
local bucla_linie_verticala
	mov eax, y ; eax=y
	mov ebx, area_width
	mul ebx ;eax = y * area_width
	add eax, x ;eax = y * area_width * x
	shl eax, 2 ;(eax = y * area_width * x) * 4
	add eax, area
	mov ecx, len
bucla_linie_verticala:
	mov dword ptr[eax], color
	add eax, 4 * area_width
	loop bucla_linie_verticala
endm


	
slam proc ; mutam toate casutele de la poz st_p in directia din step
	pusha

	not_set:
	mov set, 1
	
	mov eax, st_p
	mov ebx, st_p
	add ebx, step
	mov edx, st_p
	add edx, 4
	
	for_line:
	
	mov ecx, mat[eax*4]
	cmp ecx, mat[ebx*4]
	je egale
	
	cmp ecx, 0
	jne nxt_blk
	
	push mat[eax*4] ; cod pt mutarea casutelor pline pe casute goale in directia dorita
	push mat[ebx*4]
	pop mat[eax*4]
	pop mat[ebx*4]
	mov set, 0
	
	cmp deja_gen, 0
	jne skip_gen
	;call nr_nou
	mov deja_gen, 1
	skip_gen:
	
	jmp nxt_blk
	
	egale: ;cod pt combinarea a 2 casute egale adiacente
	
	cmp ecx, 0
	je nxt_blk
	
	inc mat[eax*4]
	mov mat[ebx*4], 0
	mov set, 0
	
	cmp deja_gen, 0
	jne skip_gen1
	;call nr_nou
	mov deja_gen, 1
	skip_gen1:
	
	nxt_blk:
	;make_text_macro edx, area, 0, 0
	add eax, step
	add ebx, step
	cmp ebx, end_p
	jne for_line
	
	cmp set, 1
	jne not_set
	
	popa
	ret
slam endp


; macrouri pt fiecare directie
slam_left macro

	mov step, 1
	mov st_p, 0
	mov end_p, 4
	call slam
	mov st_p, 4
	mov end_p, 8
	call slam
	mov st_p, 8
	mov end_p, 12
	call slam
	mov st_p, 12
	mov end_p, 16
	call slam

endm

slam_right macro

	mov step, -1
	mov st_p, 3
	mov end_p, -1
	call slam
	mov st_p, 7
	mov end_p, 3
	call slam
	mov st_p, 11
	mov end_p, 7
	call slam
	mov st_p, 15
	mov end_p, 11
	call slam

endm 

slam_up macro

	mov step, 4
	mov st_p, 0
	mov end_p, 16
	call slam
	mov st_p, 1
	mov end_p, 17
	call slam
	mov st_p, 2
	mov end_p, 18
	call slam
	mov st_p, 3
	mov end_p, 19
	call slam

endm 

slam_down macro

	mov step, -4
	mov st_p, 15
	mov end_p, -1
	call slam
	mov st_p, 14
	mov end_p, -2
	call slam
	mov st_p, 13
	mov end_p, -3
	call slam
	mov st_p, 12
	mov end_p, -4
	call slam

endm 



make_num proc ;proc pt a desena o casuta
	push ebp
	mov ebp, esp
	pusha
	
	mov eax, [ebp+arg1] ; citim numul de afisat
	lea esi, nums
	
draw_num:
	mov ebx, num_width
	mul ebx
	mov ebx, num_height
	mul ebx
	add esi, eax
	mov ecx, num_height
bucla_num_linii:
	mov edi, [ebp+arg2] ; pointer la matricea de pixeli
	mov eax, [ebp+arg4] ; pointer la coord y
	add eax, num_height
	sub eax, ecx
	mov ebx, area_width
	mul ebx
	add eax, [ebp+arg3] ; pointer la coord x
	shl eax, 2 ; inmultim cu 4, avem un DWORD per pixel
	add edi, eax
	push ecx
	mov ecx, num_width
bucla_num_coloane:
	push ebx
	mov ebx, 0
	mov bl, byte ptr[esi]
	push colors[ebx*4]
	pop dword ptr[edi]
	pop ebx
num_pixel_next:
	inc esi
	add edi, 4
	loop bucla_num_coloane
	pop ecx
	loop bucla_num_linii
	popa
	mov esp, ebp
	pop ebp
	ret
make_num endp

; un macro ca sa apelam mai usor desenarea numarului
make_num_macro macro num, drawArea, x, y
	push y
	push x
	push drawArea
	push num
	call make_num
	add esp, 16
endm

afis_mat proc ; proc care deseneaza toata matricea folosind functia anterioara
	pusha
	
	mov eax, 0
	mov ecx, 0
	lini:
	
	mov ebx, 0
	mov edx, 0
	coloane:
	
	pusha
	push edx
	push ecx
	
	mov edx, 0
	mul patru
	add eax, ebx
	mov ebx, mat[eax*4]
	sub ebx, 1
	
	pop ecx
	pop edx
	
	;make_text_macro ebx, area, edx, ecx
	cmp ebx, -1
	je empty_box
	make_num_macro ebx, area, edx, ecx
	empty_box:
	
	popa
	inc ebx
	add edx, nums_sz
	cmp ebx, 4
	jl coloane
	
	inc eax
	add ecx, nums_sz
	cmp eax, 4
	jl lini
	
	popa
	ret
afis_mat endp

; functia de desenare - se apeleaza la fiecare click
; sau la fiecare interval de 200ms in care nu s-a dat click
; arg1 - evt (0 - initializare, 1 - click, 2 - s-a scurs intervalul fara click, 3 - s-a apasat o tasta)
; arg2 - x (in cazul apasarii unei taste, x contine codul ascii al tastei care a fost apasata)
; arg3 - y

draw proc
	push ebp
	mov ebp, esp
	pusha
	
	mov eax, [ebp+arg1]
	cmp eax, 1
	jz evt_click
	cmp eax, 3
	jz evt_click
	cmp eax, 2
	jz evt_timer ; nu s-a efectuat click pe nimic
	;mai jos e codul care intializeaza fereastra cu pixeli albi
	mov eax, area_width
	mov ebx, area_height
	mul ebx
	shl eax, 2
	push eax
	push 255
	push area
	call memset
	add esp, 12
	call rand
	jmp afisare_litere
	
	
evt_click:

	mov eax, [ebp+arg2]
	
	cmp eax, 25h
	jne nu_left
	slam_left 
	nu_left:
	
	cmp eax, 26h
	jne nu_up
	slam_up 
	nu_up:
	
	cmp eax, 27h
	jne nu_right
	slam_right 
	nu_right:
	
	cmp eax, 28h
	jne nu_down
	slam_down
	nu_down:
	
	cmp deja_gen, 1
	jne skip_gen3
	call nr_nou
	mov deja_gen, 0
	skip_gen3:
	
evt_timer:
	mov eax, area
	mov ebx, 0
	make_white:
	mov dword ptr[ebx*4 + eax], 0ffffffh
	inc ebx
	cmp ebx, area_height*area_width
	jl make_white
	
	call afis_mat
	
afisare_litere:
	;afisam valoarea counter-ului curent (sute, zeci si unitati)
	; mov ebx, 10
	; mov eax, counter
	
	; mov edx, 0 ;cifra unitatilor
	; div ebx
	; add edx, '0'
	; make_text_macro edx, area, 30, 10
	
	; mov edx, 0 ;cifra zecilor
	; div ebx
	; add edx, '0'
	; make_text_macro edx, area, 20, 10
	
	; mov edx, 0 ;cifra sutelor
	; div ebx
	; add edx, '0'
	; make_text_macro edx, area, 10, 10

	;scriem un mesaj
	make_text_macro '2', area, 230, 200
	make_text_macro '0', area, 240, 200
	make_text_macro '4', area, 250, 200
	make_text_macro '8', area, 260, 200
	make_text_macro ' ', area, 270, 200
	make_text_macro 'G', area, 280, 200
	make_text_macro 'A', area, 290, 200
	make_text_macro 'M', area, 300, 200
	make_text_macro 'E', area, 310, 200
	
	line_horizontal 0, 0, 165, 0
	line_horizontal 0, 45, 165, 0
	line_horizontal 0, 85, 165, 0
	line_horizontal 0, 125, 165, 0
	line_horizontal 0, 165, 165, 0
	
	line_vertical 0, 0, 165, 0
	line_vertical 45, 0, 165, 0
	line_vertical 85, 0, 165, 0
	line_vertical 125, 0, 165, 0
	line_vertical 165, 0, 165, 0
	
final_draw:
	popa
	mov esp, ebp
	pop ebp
	ret
draw endp

start:
	;alocam memorie pentru zona de desenat
	mov eax, area_width
	mov ebx, area_height
	mul ebx
	shl eax, 2
	push eax
	call malloc
	add esp, 4
	mov area, eax
	;apelam functia de desenare a ferestrei
	; typedef void (*DrawFunc)(int evt, int x, int y);
	; void __cdecl BeginDrawing(const char *title, int width, int height, unsigned int *area, DrawFunc draw);
	
    push 0
    call time                
    add esp, 4
    push eax               
    call srand       
    add esp, 4

	call nr_nou
	call nr_nou
    
	push offset draw
	push area
	push area_height
	push area_width
	push offset window_title
	call BeginDrawing
	add esp, 20
	
	;terminarea programului
	push 0
	call exit
end start

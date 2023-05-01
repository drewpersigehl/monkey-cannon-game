; #########################################################################
;
;   blit.asm - Assembly file for CompEng205 Assignment 3
;
;
; #########################################################################

      .586
      .MODEL FLAT,STDCALL
      .STACK 4096
      option casemap :none  ; case sensitive

include stars.inc
include lines.inc
include trig.inc
include blit.inc


.DATA

	;; If you need to, you can place global variables here
	
.CODE

DrawPixel PROC USES ebx ecx x:DWORD, y:DWORD, color:DWORD
	
	;;  first check for drawing out of bounds
	cmp x, 639
	jg skip_draw
	cmp x, 0
	jl skip_draw
	cmp y, 479
	jg skip_draw
	cmp y, 0
	jl skip_draw

	;;  the pixel index should be
	;;  x + 640*y
	;;  e.g. (0, 1) would be pixel array index 640

	mov eax, 640
	mul y
	add eax, x

	;;  put the address of the backbuffer into ebx
	mov ebx, [ScreenBitsPtr]

	;;  need to just get the LSB of color

	mov cl, BYTE PTR [color]

	;;  now use ebx as a base register and eax as the index register
	mov BYTE PTR [ebx + eax], cl

	skip_draw:

	ret 			; Don't delete this line!!!
DrawPixel ENDP

BasicBlit PROC USES ebx ecx edx edi esi ptrBitmap:PTR EECS205BITMAP , xcenter:DWORD, ycenter:DWORD

	LOCAL bitWidth:DWORD, bitHeight:DWORD, topleft_x:DWORD, topleft_y:DWORD, color_draw:DWORD, color_array:DWORD, x_draw:DWORD, y_draw:DWORD, t_color:DWORD

	;;  put the address of the bitmap in ebx
	mov ebx, [ptrBitmap]

	;; move bTransparent into t_color
	xor eax, eax
	mov al, [ebx + 8]
	mov t_color, eax

	;; put the address of the array of bitmap colors in color_array
	mov ecx, [ebx + 12]
	mov color_array, ecx

	;;  let's find the x coordinate of the top left of the bitmap
	;;  we need to start drawing at dwWidth/2 pixels left of xcenter
	
	;;  move dwWidth into ecx, and put it in bitWidth for safe keeping
	mov ecx, [ebx]
	mov bitWidth, ecx

	;;  divide bitWidth by two by shifting right 1 bit
	sar ecx, 1

	;;  subtract half of bitWidth from xcenter to get the x coordinate of top left
	mov edx, xcenter
	sub edx, ecx
	mov topleft_x, edx
	
	;;  let's find the y coordinate of the top left of the bitmap
	;;  we need to start drawing at dwHeight/2 pixels up from ycenter
	
	;;  move dwHeight into ecx, and put it in bitHeight for safe keeping
	mov ecx, [ebx + 4]
	mov bitHeight, ecx

	;;  divide bitHeight by two by shifting right 1 bit
	sar ecx, 1

	;;  subtract half of bitHeight from ycenter to get the y coordinate of top left
	mov edx, ycenter
	sub edx, ecx
	mov topleft_y, edx

	;;  now we move into our nested for loops for filling in the bitmap
	;;  edi = x counter, esi = y counter

		xor esi, esi
		jmp eval_y
	body_y:
		
			xor edi, edi
			jmp eval_x
		body_x:
			
			;;  Here's where we actually do the drawing

			;;  we turn eax into our index reg
			mov eax, bitWidth
			mul esi
			add eax, edi

			;;  put color_array into a register so it may be interpreted as a base reg rather than a displacement
			mov ebx, color_array

			;;  we extract the corresponding color byte from the array and move it to ecx
			xor ecx, ecx
			mov cl, BYTE PTR [ebx + eax]
			mov color_draw, ecx

			;;  we check to see if the color to be drawn is the one that should be transparent
			;;  if it is, then we skip the drawing step
			cmp ecx, t_color
			je skip_draw

			mov ecx, topleft_x
			mov x_draw, ecx
			add x_draw, edi
			mov ecx, topleft_y
			mov y_draw, ecx
			add y_draw, esi

			invoke DrawPixel, x_draw, y_draw, color_draw

			skip_draw:

			inc edi
		eval_x:
			cmp edi, bitWidth
			jl body_x

		inc esi
	eval_y:
		cmp esi, bitHeight
		jl body_y
	

	ret 			; Don't delete this line!!!	
BasicBlit ENDP


RotateBlit PROC USES esi edx lpBmp:PTR EECS205BITMAP, xcenter:DWORD, ycenter:DWORD, angle:FXPT

	LOCAL cosa:DWORD, sina:DWORD, fixed_dwWidth:FXPT, fixed_dwHeight:FXPT, shiftX:DWORD, shiftY:DWORD, dstWidth:DWORD, dstHeight:DWORD, dstX:DWORD, dstY:DWORD, srcX:DWORD, srcY:DWORD, draw_x:DWORD, draw_y:DWORD, draw_color:DWORD, color_array:DWORD

	invoke FixedCos, angle
	mov cosa, eax

	invoke FixedSin, angle
	mov sina, eax

	;;  put the bitmap address into esi
	mov esi, [lpBmp]

	;;  put the address of the array of bitmap colors in color_array
	mov eax, [esi + 12]
	mov color_array, eax

	;;  put a fixedpoint version of dwWidth into fixed_dwWidth
	mov eax, DWORD PTR [esi]
	mov fixed_dwWidth, eax
	shl fixed_dwWidth, 16

	;;  put a fixedpoint version of dwHeight into fixed_dwHeight
	mov eax, DWORD PTR [esi + 4]
	mov fixed_dwHeight, eax
	shl fixed_dwHeight, 16

	;;  getting shiftX

	xor eax, eax
	xor edx, edx

	mov eax, fixed_dwWidth
	imul cosa
	;;  result of imul is now in edx[15:0] and eax[31:16]
	shr eax, 16
	shl edx, 16
	or eax, edx
	;;  shift once more to divide by 2
	sar eax, 1
	mov shiftX, eax

	xor eax, eax
	xor edx, edx

	mov eax, fixed_dwHeight
	imul sina
	;;  result of imul is now in edx[15:0] and eax[31:16]
	shr eax, 16
	shl edx, 16
	or eax, edx
	;;  shift once more to divide by 2
	sar eax, 1
	sub shiftX, eax

	;;  getting shiftY

	xor eax, eax
	xor edx, edx

	mov eax, fixed_dwHeight
	imul cosa
	;;  result of imul is now in edx[15:0] and eax[31:16]
	shr eax, 16
	shl edx, 16
	add eax, edx
	;;  shift once more to divide by 2
	sar eax, 1
	mov shiftY, eax

	xor eax, eax
	xor edx, edx

	mov eax, fixed_dwWidth
	imul sina
	;;  result of imul is now in edx[15:0] and eax[31:16]
	shr eax, 16
	shl edx, 16
	add eax, edx
	;;  shift once more to divide by 2
	sar eax, 1
	add shiftY, eax

	;;  NOTE: at this point, shiftX and shiftY both hold fixed point values

	;;  getting dstWidth and dstHeight

	mov eax, fixed_dwWidth
	mov dstWidth, eax
	mov eax, fixed_dwHeight
	add dstWidth, eax
	mov eax, dstWidth
	mov dstHeight, eax

	;;  NOTE: at this point, dstWidth and dstHeight both hold fixed point values

	;;  nested for loops for drawing

		;;  initializing the counter dstX as -dstWidth
		mov eax, dstWidth
		mov dstX, eax
		neg dstX

		jmp eval_x
	body_x:
		
		;;  initializing the counter dstY as -dstHeight
		mov eax, dstHeight
		mov dstY, eax
		neg dstY

		jmp eval_y
	body_y:
		
		;; Now here's the meat of the loop

		;;  getting srcX

		mov eax, dstX
		imul cosa
		;;  result of imul is now in edx[15:0] and eax[31:16]
		shr eax, 16
		shl edx, 16
		add eax, edx
		mov srcX, eax

		mov eax, dstY
		imul sina
		;;  result of imul is now in edx[15:0] and eax[31:16]
		shr eax, 16
		shl edx, 16
		add eax, edx
		add srcX, eax

		;; getting srcY

		mov eax, dstY
		imul cosa
		;;  result of imul is now in edx[15:0] and eax[31:16]
		shr eax, 16
		shl edx, 16
		add eax, edx
		mov srcY, eax

		mov eax, dstX
		imul sina
		;;  result of imul is now in edx[15:0] and eax[31:16]
		shr eax, 16
		shl edx, 16
		add eax, edx
		sub srcY, eax

		;;  if conditions to draw

		;;  srcX >= 0
		cmp srcX, 0
		jl skip_draw

		;;  srcX < dwWidth
		mov eax, fixed_dwWidth
		cmp srcX, eax
		jge skip_draw

		;;  srcY >= 0
		cmp srcY, 0
		jl skip_draw

		;;  srcY < dwHeight
		mov eax, fixed_dwHeight
		cmp srcY, eax
		jge skip_draw

		;;  put (xcenter+dstX-shiftX) in draw_x
		;;  NOTE: xcenter is an integer value but the other two are fixed point
		mov eax, xcenter
		shl eax, 16
		add eax, dstX
		sub eax, shiftX
		;;  now move it back into integer form
		shr eax, 16
		mov draw_x, eax

		;;  (xcenter+dstX-shiftX) >= 0
		cmp draw_x, 0
		jl skip_draw

		;;  (xcenter+dstX-shiftX) < 639
		cmp draw_x, 639
		jge skip_draw

		;;  put (ycenter+dstY-shiftY) in draw_y
		;;  NOTE: ycenter is an integer value but the other two are fixed point
		mov eax, ycenter
		shl eax, 16
		add eax, dstY
		sub eax, shiftY
		;;  now move it back into integer form
		shr eax, 16
		mov draw_y, eax

		;;  (ycenter+dstY-shiftY) >= 0
		cmp draw_y, 0
		jl skip_draw

		;;  (ycenter+dstY-shiftY) < 479
		cmp draw_y, 479
		jge skip_draw

		;;  put the correct color value from pixel (srcX, srcY) into draw_color
		mov eax, fixed_dwWidth
		shr eax, 16
		mov ebx, srcY
		shr ebx, 16
		imul ebx
		mov ebx, srcX
		shr ebx, 16
		add eax, ebx
		;;  now that we have the index in eax, we must access the bitmap
		xor ecx, ecx
		mov ebx, color_array
		mov cl, BYTE PTR [ebx + eax]
		mov draw_color, ecx

		;; move bTransparent into eax
		xor eax, eax
		mov al, [esi + 8]

		;;  bitmap pixel (srcX,srcY) is not transparent)
		cmp draw_color, eax
		je skip_draw

		;;  finally, the draw instruction:
		invoke DrawPixel, draw_x, draw_y, draw_color

		skip_draw:

		add dstY, 00010000h
	eval_y:
		mov eax, dstHeight
		cmp dstY, eax
		jl body_y

		add dstX, 00010000h
	eval_x:
		mov eax, dstWidth
		cmp dstX, eax
		jl body_x

	ret 			; Don't delete this line!!!		
RotateBlit ENDP



END

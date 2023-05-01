; #########################################################################
;
;   trig.asm - Assembly file for CompEng205 Assignment 3
;
;
; #########################################################################

      .586
      .MODEL FLAT,STDCALL
      .STACK 4096
      option casemap :none  ; case sensitive

include trig.inc

.DATA

;;  These are some useful constants (fixed point values that correspond to important angles)
;;  these are in decimal!
PI_HALF = 102943           	;;  PI / 2
PI =  205887	                ;;  PI 
TWO_PI	= 411774                ;;  2 * PI 
PI_INC_RECIP =  5340353        	;;  Use reciprocal to find the table entry for a given angle
	                        ;;              (It is easier to use than divison would be)
							;;  this number is the reciprocal of Pi/256
PI_PLUS_HALF = 308830		;; 3PI / 2

	;; If you need to, you can place global variables here
	
.CODE

FixedSin PROC USES ebx ecx angle:FXPT

	xor eax, eax

	mov ebx, angle

	;;  while angle is negative, add 2 pi until it becomes positive
		jmp eval1
	body1:
		add ebx, TWO_PI
	eval1: 
		cmp ebx, 0
		jl body1

	;;  while angle is 2 pi or greater, subtract 2 pi until its less than 2 pi
		jmp eval2
	body2:
		sub ebx, TWO_PI
	eval2:
		cmp ebx, TWO_PI
		jge body2

	;; if new angle is greater than or equal to 1.5pi, compute -sin(2pi - angle)
		cmp ebx, PI_PLUS_HALF
		jl skip0
		mov ecx, TWO_PI
		sub ecx, ebx
		invoke FixedSinAdjusted, ecx
		neg eax
		jmp skip4
	skip0:

	;;  if new angle is greater than or equal to pi, compute -sin(angle - pi)
		cmp ebx, PI
		jl skip1
		sub ebx, PI
		invoke FixedSinAdjusted, ebx
		neg eax
		jmp skip4
	skip1:

		
	;; if new angle is greater than pi/2 but less than pi, compute sin(pi - angle)
		cmp ebx, PI_HALF
		jle skip2
		mov ecx, PI
		sub ecx, ebx
		invoke FixedSinAdjusted, ecx
		jmp skip4
	skip2:

	;; if new angle is exactly equal to pi/2, return 1
		cmp ebx, PI_HALF
		jne skip3
		mov eax, 00010000h
		jmp skip4
	skip3:

	;; new angle must be in [0, pi/2), compute sin(angle)
		invoke FixedSinAdjusted, ebx
	skip4:

	ret			; Don't delete this line!!!
FixedSin ENDP 

;; Here I define a helper function which computes the fixed point sign of an angle in [0, Pi/2)
	
FixedSinAdjusted PROC USES edx angle:FXPT

	LOCAL reciprocal:DWORD

	;; first copy the angle to eax
	mov eax, angle

	;;  for angles within the range [0, Pi/2)
	;;  to figure out what index we need, multiply the angle by the reciprocal of Pi/256

	;; sign extend eax (the angle) into edx
	cdq

	;; divide by Pi/256 via multiplying by 256/Pi
	mov reciprocal, PI_INC_RECIP
	imul reciprocal

	;;  we need to shift the result right by 16 bits to reach the correct fixed point result
	;;  we need to shift the result right by another 16 bits to convert the fixed point result to an integer
	;;  thus, we are just going to use edx in place of eax

	;;  now edx should contain i
	;;  we need to access the ith element of SINTAB (which has type WORD)
	movzx eax, WORD PTR [SINTAB + 2*edx]

	ret			; Don't delete this line!!!
FixedSinAdjusted ENDP
	
FixedCos PROC USES ebx angle:FXPT

	xor eax, eax

	mov ebx, angle

	;;  since cos(x) = sin(x + pi/2), we just have to add pi/2 to angle and then compute FixedSin(angle)

	add ebx, PI_HALF
	invoke FixedSin, ebx

	ret			; Don't delete this line!!!	
FixedCos ENDP	
END


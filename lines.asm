; #########################################################################
;
;   lines.asm - Assembly file for CompEng205 Assignment 2
;
;
;	Name:	Drew Persigehl 
;	NetID:  dcp1893
;	
;
; #########################################################################

      .586
      .MODEL FLAT,STDCALL
      .STACK 4096
      option casemap :none  ; case sensitive

include stars.inc
include lines.inc

.DATA

	;; If you need to, you can place global variables here
	
.CODE
	

;; Don't forget to add the USES the directive here
;;   Place any registers that you modify (either explicitly or implicitly)
;;   into the USES list so that caller's values can be preserved
	
;;   For example, if your procedure uses only the eax and ebx registers
;;      DrawLine PROC USES eax ebx x0:DWORD, y0:DWORD, x1:DWORD, y1:DWORD, color:DWORD
DrawLine PROC USES ebx ecx x0:DWORD, y0:DWORD, x1:DWORD, y1:DWORD, color:DWORD
	;; Feel free to use local variables...declare them here
	;; For example:
	;; 	LOCAL foo:DWORD, bar:DWORD
	
	LOCAL delta_x:DWORD, delta_y:DWORD, inc_x:DWORD, inc_y:DWORD, err:DWORD, prev_err:DWORD, curr_x:DWORD, curr_y:DWORD	
		
	
	;; Place your code here
	
		;; initialize delta_x
		mov ebx, x1
		sub ebx, x0
		cmp ebx, 0
		jge Positive_x
		neg ebx
	Positive_x:
		mov delta_x, ebx
		
		;; initialize delta_y
		mov ebx, y1
		sub ebx, y0
		cmp ebx, 0
		jge Positive_y
		neg ebx
	Positive_y:
		mov delta_y, ebx
		
		;; initialize inc_x
		mov ebx, x0
		cmp ebx, x1
		jge Bigger_x0
		mov inc_x, 1
		jmp inc_x_done
	Bigger_x0:
		mov inc_x, -1
	inc_x_done:
	
		;; initialize inc_y
		mov ebx, y0
		cmp ebx, y1
		jge Bigger_y0
		mov inc_y, 1
		jmp inc_y_done
	Bigger_y0:
		mov inc_y, -1
	inc_y_done:
	
		;; initialize err
		mov ebx, delta_x
		cmp ebx, delta_y
		jle Bigger_delta_y
		shr ebx, 1
		mov err, ebx
		jmp err_done
	Bigger_delta_y:
		mov ebx, delta_y
		neg ebx
		sar ebx, 1
		mov err, ebx
	err_done:
		
		;; initialize curr_x
		mov ebx, x0
		mov curr_x, ebx
		
		;; initialize curr_y
		mov ebx, y0
		mov curr_y, ebx
		
		;; draw first pixel
		invoke DrawPixel, curr_x, curr_y, color
		
		;; WHILE LOOP
		
		jmp Eval
		
	Do:
		invoke DrawPixel, curr_x, curr_y, color
		
		;; update prev_err
		mov ebx, err
		mov prev_err, ebx
		
		;; first if block
		mov ecx, delta_x
		neg ecx
		cmp prev_err, ecx
		jng Escape_first
		mov ecx, delta_y
		sub err, ecx
		mov ecx, inc_x
		add curr_x, ecx
	Escape_first:
		
		;; second if block
		mov ecx, delta_y
		cmp prev_err, ecx
		jnl Escape_second
		mov ebx, delta_x
		add err, ebx
		mov ecx, inc_y
		add curr_y, ecx
	Escape_second:
	
	Eval:
		;; evaluate condition
		mov ebx, curr_x
		cmp ebx, x1
		jne Do
		mov ebx, curr_y
		cmp ebx, y1
		jne Do	

	ret        	;;  Don't delete this line...you need it
DrawLine ENDP




END

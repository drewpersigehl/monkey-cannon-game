; #########################################################################
;
;   stars.asm - Assembly file for CompEng205 Assignment 1
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

.DATA

	;; If you need to, you can place global variables here

.CODE

DrawStarField proc
	; drawing 16 stars
	invoke DrawStar, 574, 265 
	invoke DrawStar, 372, 188
	invoke DrawStar, 317, 274
	invoke DrawStar, 529, 122
	invoke DrawStar, 575, 119
	invoke DrawStar, 179, 109
	invoke DrawStar, 421, 96
	invoke DrawStar, 361, 100
	invoke DrawStar, 509, 470
	invoke DrawStar, 477, 211
	invoke DrawStar, 507, 459
	invoke DrawStar, 195, 209
	invoke DrawStar, 140, 14
	invoke DrawStar, 440, 373
	invoke DrawStar, 397, 183
	invoke DrawStar, 37, 433

	ret  			; Careful! Don't remove this line
DrawStarField endp



END

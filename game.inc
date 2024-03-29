; #########################################################################
;
;   game.inc - Includes for CompEng205 Assignment 4/5
;
;
; #########################################################################

;; Library Definitions
MouseInfo STRUCT
 horiz DWORD ?
 vert  DWORD ?
 buttons DWORD ?
MouseInfo ENDS

MK_CONTROL  = 0008h  ;; The CTRL key is down.
MK_LBUTTON  = 0001h  ;; The left mouse button is down.
MK_MBUTTON  = 0010h  ;; The middle mouse button is down.
MK_RBUTTON  = 0002h  ;; The right mouse button is down.
MK_SHIFT    = 0004h  ;; The SHIFT key is down.
MK_XBUTTON1 = 0020h  ;; The first X button is down.
MK_XBUTTON2 = 0040h  ;; The second X button is down.

;; Library Functions
BlackStarField	PROTO
DrawStr PROTO myStr:PTR BYTE, x:DWORD, y:DWORD, color:DWORD

;; Library Data
EXTERNDEF StarBitmap:EECS205BITMAP
EXTERNDEF MouseStatus:MouseInfo
EXTERNDEF KeyUp:DWORD
EXTERNDEF KeyDown:DWORD
EXTERNDEF KeyPress:DWORD

;; my bitmaps
EXTERNDEF background:EECS205BITMAP
EXTERNDEF cannon:EECS205BITMAP
EXTERNDEF cloud:EECS205BITMAP
EXTERNDEF cannonball:EECS205BITMAP
EXTERNDEF target:EECS205BITMAP
EXTERNDEF pausescreen:EECS205BITMAP
EXTERNDEF wall:EECS205BITMAP
EXTERNDEF heart:EECS205BITMAP
EXTERNDEF lose:EECS205BITMAP


;; User Defined Functions
GameInit PROTO
GamePlay PROTO
CheckIntersect PROTO oneX:DWORD, oneY:DWORD, oneBitmap:PTR EECS205BITMAP, twoX:DWORD, twoY:DWORD, twoBitmap:PTR EECS205BITMAP 
UpdateTarget PROTO

CannonBall STRUCT
	active DWORD 0  ;;  Zero = inactive, Nonzero = active
	bitmapPtr DWORD ?
	Xpos FXPT 0
	Ypos FXPT 0
	Xvel FXPT 0
	Yvel FXPT 0
CannonBall ENDS



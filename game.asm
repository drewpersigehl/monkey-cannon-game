; #########################################################################
;
;   game.asm - Assembly file for CompEng205 Assignment 4/5
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
include game.inc
include E:\masm32\include\windows.inc
include E:\masm32\include\user32.inc
includelib E:\masm32\lib\user32.lib
include E:\masm32\include\masm32.inc
includelib E:\masm32\lib\masm32.lib
include E:\masm32\include\winmm.inc
includelib E:\masm32\lib\winmm.lib



;; Has keycodes
include keys.inc

	
.DATA

;; If you need to, you can place global variables here

cannon_angle FXPT 0 
rotation_inc FXPT 00000500h
cannon_x FXPT 00640000h
cannon_y FXPT 01860000h
cloud_x DWORD 450
cloud_y DWORD 135
CannonBallArr CannonBall 10 DUP (<0, OFFSET cannonball, 00500000h, 00500000h, 0, 0>)
current_ball DWORD 0
cannon_power DWORD 14
cannon_power_cycle DWORD 0
gravity FXPT 00006000h
target_x DWORD 500
target_y DWORD 390
score DWORD 0
pausetoggle DWORD 0
wall_x DWORD 210
wall_y DWORD 370
lives_left DWORD 3
heart_x DWORD 510
heart_y DWORD 25

fmtStr BYTE "score: %d", 0
outStr BYTE 256 DUP(0)

gunshot BYTE "gunshot.wav",0
monkey2 BYTE "monkey2.wav",0
pausesound BYTE "pausesound.wav",0
deathsound BYTE "deathsound.wav",0
coin BYTE "coin.wav",0
increasepower BYTE "increasepower.wav",0

.CODE
	

;; Note: You will need to implement CheckIntersect!!!

GameInit PROC
	rdtsc
	invoke nseed, eax ;;  set up the random seed so we can randomly move the target
	ret         ;; Do not delete this line!!!
GameInit ENDP


GamePlay PROC

	LOCAL int_x:DWORD, int_y:DWORD

	;; TOGGLE PAUSE

		cmp KeyPress, 20h
		jne SkipToggle
		invoke PlaySound, offset pausesound, 0, SND_FILENAME OR SND_ASYNC
		cmp pausetoggle, 0
		jne WasPaused
		mov pausetoggle, 1
		jmp Toggled
	WasPaused:
		mov pausetoggle, 0
	Toggled:
		mov KeyPress, 0
	SkipToggle:

	;;  DRAW PAUSE SCREEN
	
		cmp pausetoggle, 1
		jne DonePause
		mov eax, 640
		mov ebx, 480
		mul ebx
		mov ecx, eax
		mov ebx, OFFSET pausescreen
		add ebx, 12
		mov esi, [ebx]
		mov edi, [ScreenBitsPtr]
		rep movsb
		jmp EndGamePlay
	DonePause:

	;;  RESTART AFTER LOSE
	
		cmp lives_left, 0 ;;  only want to make restart available once the game has ended
		jne NoRestart
		cmp KeyPress, 52h
		jne NoRestart
		mov score, 0
		mov cannon_power, 14
		mov cannon_power_cycle, 0
		mov lives_left, 3
		mov cannon_angle, 0
		invoke UpdateTarget
		;;  now need a loop to deactivate all the cannonballs
			xor edi, edi ;;  clear edi to use as our loop counter
			mov ebx, OFFSET CannonBallArr
		DeactivateBody:
			mov eax, TYPE CannonBallArr
			mul edi ;;  to update the displacement
			mov ecx, eax
			;;  deactivate
			mov (CannonBall PTR [ebx + ecx]).active, 0
			add edi, 1 ;;  to increment the counter
		DeactivateCond:
			cmp edi, 9
			jng DeactivateBody
		mov KeyPress, 0
	NoRestart:

	;;  DRAW LOSE SCREEN
		cmp lives_left, 0
		jne NoLose
		mov eax, 640
		mov ebx, 480
		mul ebx
		mov ecx, eax
		mov ebx, OFFSET lose
		add ebx, 12
		mov esi, [ebx]
		mov edi, [ScreenBitsPtr]
		rep movsb
		jmp EndGamePlay
	NoLose:
	
	;;  DRAW BACKGROUND

	mov eax, 640
	mov ebx, 480
	mul ebx
	mov ecx, eax
	mov ebx, OFFSET background
	add ebx, 12
	mov esi, [ebx]
	mov edi, [ScreenBitsPtr]
	rep movsb

	;;  DRAW WALL

	mov ebx, OFFSET wall
	invoke BasicBlit, ebx, wall_x, wall_y

	;;  MOVE CLOUD

		mov ebx, OFFSET cloud
		mov ecx, [ebx] ;;  put cloud bitmap width in ecx
		shr ecx, 1 ;;  divide width by 2
		neg ecx ;;  ecx = -1/2 * width of cloud
		cmp cloud_x, ecx
		jg StillGood ;;  check if cloud has gone totally off left side of screen 
		neg ecx
		add ecx, 640
		mov cloud_x, ecx ;;  move cloud all the way to right side of screen
	StillGood:
		;;  cloud is still moving across the middle of the screen
		sub cloud_x, 1

	;;  DRAW CLOUD

	invoke BasicBlit, ebx, cloud_x, cloud_y

	;;  DRAW TARGET

	mov ebx, OFFSET target
	invoke BasicBlit, ebx, target_x, target_y

	;;  UPDATE CANNON ANGLE

		cmp KeyPress, 27h ;;  check for right arrow
		jne NotRight
		mov esi, rotation_inc
		add cannon_angle, esi
	NotRight:
		cmp KeyPress, 25h ;;  check for left arrow
		jne NotLeft
		mov esi, rotation_inc
		sub cannon_angle, esi
	NotLeft:

	;;  SHOOT CANNONBALL

		mov eax, OFFSET MouseStatus
		cmp DWORD PTR [eax + 8], 0001h ;;  check for mouse click
		;cmp KeyPress, 26h
		jne DoneShooting

		;;  advance to next cannonball in array
			cmp current_ball, 9
			jne NoReload
			mov current_ball, 0
			jmp Loaded
		NoReload:
			add current_ball, 1
		Loaded:

		;;  ACTIVATE CANNONBALL

			mov ebx, OFFSET CannonBallArr
			mov eax, current_ball
			mov ecx, TYPE CannonBallArr
			mul ecx ;;  because we want to jump a whole CannonBall at a time through the array
			mov ecx, eax
			mov (CannonBall PTR [ebx + ecx]).active , 1 ;;  copy in a nonzero value to make active

		;;  CANNON SOUND
			push ecx
			push ebx
			push eax
			invoke PlaySound, offset gunshot, 0, SND_FILENAME OR SND_ASYNC
			pop eax
			pop ebx
			pop ecx

		;;  CANNONBALL INITIAL POSITION

			mov eax, cannon_x
			mov (CannonBall PTR [ebx + ecx]).Xpos, eax
			mov eax, cannon_y
			mov (CannonBall PTR [ebx + ecx]).Ypos, eax

		;;  CANNONBALL INITIAL VELOCITY

			invoke FixedSin, cannon_angle ;;  puts the sine of cannon_angle into eax
			mul cannon_power ;;  scales the initial speed
			mov (CannonBall PTR [ebx + ecx]).Yvel, eax
			invoke FixedCos, cannon_angle ;;  puts the cosine of cannon_angle into eax
			mul cannon_power ;;  scales the initial speed
			mov (CannonBall PTR [ebx + ecx]).Xvel, eax
	DoneShooting:

	mov eax, OFFSET MouseStatus
	mov DWORD PTR [eax + 8], 0


	;;  MOVE CANNONBALLS

		xor edi, edi ;;  clear edi to use as our loop counter
		mov ebx, OFFSET CannonBallArr
	MoveBody:
		mov eax, TYPE CannonBallArr
		mul edi ;;  to update the displacement
		mov ecx, eax
		;;  move in x direction
		mov eax, (CannonBall PTR [ebx + ecx]).Xvel
		add (CannonBall PTR [ebx + ecx]).Xpos, eax
		;;  move in y direction
		mov eax, (CannonBall PTR [ebx + ecx]).Yvel
		add (CannonBall PTR [ebx + ecx]).Ypos, eax
		;;  move to next item in array
		add edi, 1 ;;  to increment the counter
	MoveCond:
		cmp edi, 9
		jng MoveBody
		
	;;  ACCELERATE CANNONBALLS

		xor edi, edi ;;  clear edi to use as our loop counter
		mov ebx, OFFSET CannonBallArr
	AccBody:
		mov eax, TYPE CannonBallArr
		mul edi ;;  to update the displacement
		mov ecx, eax
		;;  accelerate in y direction
		mov eax, gravity
		add (CannonBall PTR [ebx + ecx]).Yvel, eax
		add edi, 1 ;;  to increment the counter
	AccCond:
		cmp edi, 9
		jng AccBody

	;;  DRAW CANNONBALLS

		xor edi, edi ;;  clear edi to use as our loop counter
		mov ebx, OFFSET CannonBallArr
	DrawBody:
		mov eax, TYPE CannonBallArr
		mul edi ;;  to update the displacement
		mov ecx, eax
		;;  if active, then draw
		cmp (CannonBall PTR [ebx + ecx]).active, 0
		je NotActive
		;;  Need to convert FXPT positions to integers for drawing
		mov esi, (CannonBall PTR [ebx + ecx]).Xpos
		shr esi, 16
		mov int_x, esi
		mov esi, (CannonBall PTR [ebx + ecx]).Ypos
		shr esi, 16
		mov int_y, esi
		invoke BasicBlit, (CannonBall PTR [ebx + ecx]).bitmapPtr, int_x, int_y
	NotActive:
		add edi, 1
	DrawCond:
		cmp edi, 9
		jng DrawBody

	;;  CHECK CANNONBALL-TARGET COLLIIONS

		xor edi, edi ;;  clear edi to use as our loop counter
		mov ebx, OFFSET CannonBallArr
	HitBody:
		mov eax, TYPE CannonBallArr
		mul edi ;;  to update the displacement
		mov ecx, eax
		;;  we only care about collisions of active cannonballs, so check if active
		cmp (CannonBall PTR [ebx + ecx]).active, 0
		je NoCollision
		;;  now we need to get the cannonball's position in integer format
		mov esi, (CannonBall PTR [ebx + ecx]).Xpos
		shr esi, 16
		mov int_x, esi
		mov esi, (CannonBall PTR [ebx + ecx]).Ypos
		shr esi, 16
		mov int_y, esi
		mov esi, OFFSET target ;;  eax is now a pointer to the target's bitmap
		invoke CheckIntersect, int_x, int_y, (CannonBall PTR [ebx + ecx]).bitmapPtr, target_x, target_y, esi
		;;  if they collide, need to deactivate cannonball and incremement score
		cmp eax, 0 
		je NoCollision
		mov (CannonBall PTR [ebx + ecx]).active, 0
		add score, 1
		add cannon_power_cycle, 1 ;;  we want to add 1 to cannon_power every 3 hits
		cmp cannon_power_cycle, 3
		jne NoCannonPower
		mov cannon_power_cycle, 0
		add cannon_power, 1 ;;  increase cannon_power to make game more difficult
		push eax
		push ebx
		push ecx
		push edi
		invoke PlaySound, offset increasepower, 0, SND_FILENAME OR SND_ASYNC
		pop edi
		pop ecx
		pop ebx
		pop eax
		jmp EndSound
	NoCannonPower:
		push eax
		push ebx
		push ecx
		push edi
		invoke PlaySound, offset coin, 0, SND_FILENAME OR SND_ASYNC
		pop edi
		pop ecx
		pop ebx
		pop eax
	EndSound:
		invoke UpdateTarget
	NoCollision:
		add edi, 1
	HitCond:
		cmp edi, 9
		jng HitBody

	;; CHECK CANNONBALL-WALL COLLISIONS AND OUT OF BOUNDS

		xor edi, edi ;;  clear edi to use as our loop counter
		mov ebx, OFFSET CannonBallArr
	HitBody2:
		mov eax, TYPE CannonBallArr
		mul edi ;;  to update the displacement
		mov ecx, eax
		;;  we only care about collisions of active cannonballs, so check if active
		cmp (CannonBall PTR [ebx + ecx]).active, 0
		je NoCollision2
		;;  now we need to get the cannonball's position in integer format
		mov esi, (CannonBall PTR [ebx + ecx]).Xpos
		shr esi, 16
		mov int_x, esi
		mov esi, (CannonBall PTR [ebx + ecx]).Ypos
		shr esi, 16
		mov int_y, esi
		mov esi, OFFSET wall ;;  eax is now a pointer to the wall's bitmap
		invoke CheckIntersect, int_x, int_y, (CannonBall PTR [ebx + ecx]).bitmapPtr, wall_x, wall_y, esi
		;;  if they collide, need to deactivate cannonball
		cmp eax, 0 
		jne Collision2
		;;  there must not be a wall collision, let's check for OOB
		cmp int_x, 0 ;;  left boundary
		jl Collision2
		cmp int_x, 640 ;;  right boundary
		jg Collision2
		cmp int_y, 460 ;;  bottom boundary
		jle NoCollision2
		cmp int_y, 600
		jg NoCollision2
	Collision2:
		mov (CannonBall PTR [ebx + ecx]).active, 0
		sub lives_left, 1
		cmp lives_left, 0
		jne NoEndSound
		push eax
		push ebx
		push ecx
		push edi
		invoke PlaySound, offset monkey2, 0, SND_FILENAME OR SND_ASYNC
		pop edi
		pop ecx
		pop ebx
		pop eax
		jmp NoCollision2
	NoEndSound:
		push eax
		push ebx
		push ecx
		push edi
		invoke PlaySound, offset deathsound, 0, SND_FILENAME OR SND_ASYNC
		pop edi
		pop ecx
		pop ebx
		pop eax
	NoCollision2:
		add edi, 1
	HitCond2:
		cmp edi, 9
		jng HitBody2


	;;  DRAW CANNON

	mov ebx, OFFSET cannon
	mov esi, cannon_x
	shr esi, 16
	mov edi, cannon_y
	shr edi, 16
	invoke RotateBlit, ebx, esi, edi, cannon_angle ;;  note that cannon_angle is a fixed point value

	;;  DRAW SCORE
	push score
	push OFFSET fmtStr
	push OFFSET outStr
	call wsprintf
	add esp, 12
	invoke DrawStr, OFFSET outStr, 540, 20, 0

	;;  DRAW HEARTS
		mov ebx, OFFSET heart
		mov ecx, heart_x
		;;  now check how many hearts we need to draw
		cmp lives_left, 3
		jl OneDeath
		invoke BasicBlit, ebx, ecx, heart_y
	OneDeath:
		sub ecx, 30
		cmp lives_left, 2
		jl TwoDeath
		invoke BasicBlit, ebx, ecx, heart_y
	TwoDeath:
		sub ecx, 30
		cmp lives_left, 1
		jl ThreeDeath
		invoke BasicBlit, ebx, ecx, heart_y
	ThreeDeath:

	EndGamePlay:

	ret         ;; Do not delete this line!!!
GamePlay ENDP

UpdateTarget PROC
	
	invoke nrandom, 250
	add eax, 320
	mov target_x, eax
	
	ret
UpdateTarget ENDP

CheckIntersect PROC USES esi edi oneX:DWORD, oneY:DWORD, oneBitmap:PTR EECS205BITMAP, twoX:DWORD, twoY:DWORD, twoBitmap:PTR EECS205BITMAP 
	
	LOCAL oneWidth:DWORD, oneHeight:DWORD, twoWidth:DWORD, twoHeight:DWORD
		
		xor eax, eax ;;  start with a clear eax

		;;  get the heights and widths of each bitmap

		mov esi, [oneBitmap] ;;  moves the first bitmap address into esi
		mov edi, DWORD PTR [esi]
		mov oneWidth, edi
		mov edi, DWORD PTR [esi + 4]
		mov oneHeight, edi

		mov esi, [twoBitmap] ;;  moves the second bitmap address into esi
		mov edi, DWORD PTR [esi]
		mov twoWidth, edi
		mov edi, DWORD PTR [esi + 4]
		mov twoHeight, edi

		;;  first condition
		;;  (abs(oneX - twoX) * 2) < (oneWidth + twoWidth)

		mov esi, oneX
		sub esi, twoX
		cmp esi, 0
		jge Positive1
		neg esi
	Positive1:
		shl esi, 1 ;;  multiply by 2 
		mov edi, oneWidth
		add edi, twoWidth
		cmp esi, edi
		jge Skip ;; if condition not met, jump to end of procedure

		;;  second condition
		;;  (abs(oneY - twoY) * 2) < (oneHeight + twoHeight)

		mov esi, oneY
		sub esi, twoY
		cmp esi, 0
		jge Positive2
		neg esi
	Positive2:
		shl esi, 1 ;;  multiply by 2
		mov edi, oneHeight
		add edi, twoHeight
		cmp esi, edi
		jge Skip ;; if condition not met, jump to end of procedure

		;;  both conditions must have passed

		mov eax, 1 ;;  return nonzero value in eax

	Skip:
		ret
CheckIntersect ENDP

END

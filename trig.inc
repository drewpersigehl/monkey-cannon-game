; #########################################################################
;
;   trig.inc - Includes for CompEng205 Assignment 3
;
;
; #########################################################################

FXPT TYPEDEF SDWORD

EXTERNDEF SINTAB:WORD

FixedSin PROTO STDCALL angle:FXPT
FixedSinAdjusted PROTO STDCALL angle:FXPT
FixedCos PROTO STDCALL angle:FXPT
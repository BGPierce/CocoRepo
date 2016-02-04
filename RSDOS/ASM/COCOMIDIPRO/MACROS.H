; MACROS.h
; General purpose macros
; Written by Lester Hands, 1988

S.LOCFL TEQ 0
S.OFS TEQ 0

; Macro for declaring "local" variables.
; Up to 5 2-byte variables may be declared.
; S.LOCFL is set to 1
;
LOCALVAR %MACRO v0,v1,v2,v3,v4
S.LOCFL TEQ 1 ;flag set to 1
S.OFS TEQ 0
 %IFNB v0
v0 TEQ S.OFS
S.OFS TEQ S.OFS+2
 %ENDIF
 %IFNB v1
v1 TEQ S.OFS
S.OFS TEQ S.OFS+2
 %ENDIF
 %IFNB v2
v2 TEQ S.OFS
S.OFS TEQ S.OFS+2
 %ENDIF
 %IFNB v3
v3 TEQ S.OFS
S.OFS TEQ S.OFS+2
 %ENDIF
 %IFNB v4
v4 TEQ S.OFS
S.OFS TEQ S.OFS+2
 %ENDIF
 %ENDM

; A macro to start a procedure; use after the
; declaration of local variables. The declared
; variables are all two bytes in length. As many as
; four, or as few as none may be used. Space is
; allocated on the stack for local variables.
; S.LOCFL is checked to make sure it is set to 1
;
STACKVAR %MACRO v0,v1,v2,v3
 %IF S.LOCFL eq 0
S.OFS TEQ 0
 %ENDIF
 PSHS X,Y,U
 %IFNB v0
v0 TEQ S.OFS+8
 %ENDIF
 %IFNB v1
v1 TEQ S.OFS+10
 %ENDIF
 %IFNB v2
v2 TEQ S.OFS+12
 %ENDIF
 %IFNB v3
v3 TEQ S.OFS+14
 %ENDIF
 %IF S.OFS
 LEAS -S.OFS,S
 %ENDIF
S.X TEQ S.OFS ;used for modifying
S.Y TEQ S.OFS+2 ;returned register
S.U TEQ S.OFS+4 ;values
 %ENDM

; A macro that marks the end of a procedure; local
; variable storage is deallocated and control is
; returned to calling routine
; Clears the local flag
;
ENDS %MACRO
S.LOCFL TEQ 0
 %IF S.OFS ne 0
 LEAS S.OFS,S
 %ENDIF
 PULS X,Y,U,PC
 %ENDM

; a macro that allows C-like calls to procedures
; the procedure name is followed by a list of the
; variables to be passed (0-4).
;
CALL %MACRO v0,v1,v2,v3,v4
S.NUM TEQ 0
 %IFNB v4
 %IFEQ v4,REGX
 PSHS X
 %ELSE
 LDD v4
 PSHS D
 %ENDIF
S.NUM TEQ S.NUM+2
 %ENDIF
 %IFNB v3
 %IFEQ v3,REGX
 PSHS X
 %ELSE
 LDD v3
 PSHS D
 %ENDIF
S.NUM TEQ S.NUM+2
 %ENDIF
 %IFNB v2
 %IFEQ v2,REGX
 PSHS X
 %ELSE
 LDD v2
 PSHS D
 %ENDIF
S.NUM TEQ S.NUM+2
 %ENDIF
 %IFNB v1
 %IFEQ v1,REGX
 PSHS X
 %ELSE
 LDD v1
 PSHS D
 %ENDIF
S.NUM TEQ S.NUM+2
 %ENDIF
 LBSR v0
 LEAS S.NUM,S
 %ENDM

; a macro for declaring a character "string"
; only for use immediately after a LOCALVAR macro
;  CHAR LABEL,LENGTH
;
CHAR %MACRO v0,v1
v0 TEQ S.OFS
S.OFS TEQ S.OFS+v1
 %ENDM

; end of file: MACROS.h

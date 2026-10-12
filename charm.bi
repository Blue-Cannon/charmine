' ==========================================================
'  charm.bi -- shared constants, tables and declarations
'  for the Charmine toolchain (lexer + compiler + vm).
'  This file is $INCLUDE'd by main.bas; never run it alone.
' ==========================================================

' ---- opcodes: the only words the VM understands ----
CONST OP.HALT = 0        ' stop the machine
CONST OP.PRINT = 1       ' print bcNum# values popped from the stack
CONST OP.PUSHNUM = 2     ' push number bcNum#
CONST OP.PUSHSTR = 3     ' push string bcArg$
CONST OP.PUSHVAR = 4     ' push variable named bcArg$
CONST OP.STORE = 5       ' pop stack into variable named bcArg$
CONST OP.ADD = 6         ' pop 2, push sum (concat if either is a string)
CONST OP.SUB = 7
CONST OP.MUL = 8
CONST OP.DIV = 9
CONST OP.CMPEQ = 10      ' comparisons push 1 (true) or 0 (false)
CONST OP.CMPNE = 11
CONST OP.CMPLT = 12
CONST OP.CMPGT = 13
CONST OP.CMPLE = 14
CONST OP.CMPGE = 15
CONST OP.JMP = 16        ' jump to instruction number bcNum#
CONST OP.JZ = 17         ' pop; jump to bcNum# if it was 0
CONST OP.INPUT = 18      ' prompt bcArg$, push the user's answer

' ---- token types ----
CONST T.NUM = 1
CONST T.STR = 2
CONST T.IDENT = 3
CONST T.OP = 4

' ---- token table (filled by the lexer, one line at a time) ----
DIM SHARED tokType%(200)
DIM SHARED tokText$(200)
DIM SHARED tokN%

' ---- bytecode table (filled by the compiler) ----
DIM SHARED bcOp%(2000)
DIM SHARED bcArg$(2000)
DIM SHARED bcNum#(2000)
DIM SHARED bcN%

' ---- source, labels, variables, vm stack ----
DIM SHARED src$(500)
DIM SHARED srcN%
DIM SHARED curLine%

DIM SHARED lblName$(100)
DIM SHARED lblAddr%(100)
DIM SHARED lblN%

DIM SHARED varName$(100)
DIM SHARED varVal$(100)
DIM SHARED varType%(100)     ' 0 = number, 1 = string
DIM SHARED varN%

DIM SHARED stVal$(200)
DIM SHARED stType%(200)
DIM SHARED stN%

' ---- cross-module state ----
DIM SHARED lexBlock%         ' inside a @...@ comment?
DIM SHARED tcur%             ' token cursor of the expression parser

' ---- every procedure in the project, declared up front ----
DECLARE SUB lexLine (s$)
DECLARE SUB addTok (ty%, tx$)
DECLARE FUNCTION isChr% (c$)
DECLARE SUB compileAll ()
DECLARE SUB emit (op%, a$, n#)
DECLARE SUB compLine ()
DECLARE SUB compPrint ()
DECLARE SUB compInputStmt ()
DECLARE SUB compIf ()
DECLARE SUB compAssign ()
DECLARE SUB compRange (t0%, t1%)
DECLARE SUB compExpr ()
DECLARE SUB compCmp ()
DECLARE SUB compAdd ()
DECLARE SUB compMul ()
DECLARE SUB compAtom ()
DECLARE SUB newLabel (n$)
DECLARE FUNCTION findLabel% (n$)
DECLARE SUB runVM ()
DECLARE SUB push (v$, t%)
DECLARE FUNCTION pop$ ()
DECLARE FUNCTION popNum# ()
DECLARE SUB vmAdd ()
DECLARE SUB vmArith (op%)
DECLARE SUB vmCompare (op%)
DECLARE SUB vmPushVar (n$)
DECLARE SUB vmStore (n$)
DECLARE FUNCTION varFind% (n$)
DECLARE SUB vmPrint (n#)
DECLARE FUNCTION numToStr$ (v#)
DECLARE SUB die (msg$, ln%)

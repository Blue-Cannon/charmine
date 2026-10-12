' ==========================================================
'  CHARMINE 0.1 -- a small language implemented in QBASIC
'  file: main.bas
'
'  Run with:  QBASIC /RUN MAIN.BAS   (or open in QB64 and run)
'  Then type the name of a .charm program (the extension is
'  optional), or just press ENTER to run the built-in demo.
'
'  Charmine syntax supported so far:
'    print("Hello, World!")        output
'    print(2 + 3 * 4)              math: + - * / and ( )
'    print("x = " + x)             mixing text and values
'    name = "Alice"                variables (strings & numbers)
'    age = input("How old? ")      ask the user
'    input("Name? ", name)         same thing, statement form
'    if x < 4 then goto again      decisions
'    again:                        labels
'    # one line comment
'    @ multi line
'      comment @
'    exit                          stop the program
' ==========================================================
' © BlueBixt 2026, All Rights Reserved.
' The LICENSE is under Apache 2.0, See ./LICENSE.
' Charmine is CODEOWNERED by bluebixt-indiedev.
' Please Contact our Email if something happens to our 
' Files or Repository. BlueBixt <newssungoldentoday@gmail.com>

DECLARE FUNCTION evalNum# (e$)
DECLARE FUNCTION evalStr$ (e$)
DECLARE FUNCTION trim$ (s$)
DECLARE FUNCTION findTok% (s$, t$)
DECLARE FUNCTION numToStr$ (v#)
DECLARE FUNCTION hasLetters% (s$)
DECLARE FUNCTION isIdent% (c$)
DECLARE FUNCTION validIdent% (s$)
DECLARE FUNCTION getVar$ (n$)
DECLARE FUNCTION findVar% (n$)
DECLARE FUNCTION findLabel% (n$)
DECLARE FUNCTION firstWord$ (s$)
DECLARE FUNCTION askUser$ (p$)
DECLARE FUNCTION peekC$ ()
DECLARE FUNCTION parseCmp# ()
DECLARE FUNCTION parseAdd# ()
DECLARE FUNCTION parseMul# ()
DECLARE FUNCTION parseAtom# ()
DECLARE FUNCTION doIf% (rest$)
DECLARE SUB skipSpc ()
DECLARE SUB die (msg$, ln%)
DECLARE SUB setVar (n$, v$, t%)
DECLARE SUB doPrint (rest$)
DECLARE SUB doInput (rest$)
DECLARE SUB doAssign (txt$)

DIM SHARED src$(500)          ' the .charm source, one line each
DIM SHARED srcN%              ' how many source lines we loaded
DIM SHARED varName$(100)      ' variable names (uppercased)
DIM SHARED varVal$(100)       ' variable values, kept as text
DIM SHARED varType%(100)      ' 0 = number, 1 = string
DIM SHARED varN%
DIM SHARED labelName$(100)    ' label names (uppercased)
DIM SHARED labelLine%(100)    ' line to jump to for each label
DIM SHARED labelN%
DIM SHARED ex$, ep%           ' expression text + cursor (parser)
DIM SHARED curLine%           ' line being executed (for errors)

CLS
PRINT "Charmine 0.1 -- interpreter written in QBASIC"
PRINT

' ---------- load the program ----------
INPUT ".charm file to run (blank = demo): ", f$
IF trim$(f$) = "" THEN
    GOSUB loadDemo
ELSE
    IF INSTR(f$, ".") = 0 THEN f$ = f$ + ".charm"
    ON ERROR GOTO cantOpen
    OPEN f$ FOR INPUT AS #1
    ON ERROR GOTO 0
    WHILE NOT EOF(1) AND srcN% < 500
        srcN% = srcN% + 1
        LINE INPUT #1, src$(srcN%)
    WEND
    CLOSE #1
END IF
GOTO loaded

cantOpen:
PRINT "charm: cannot open '"; f$; "'"
END

' ---------- pass 1: strip comments, char by char ----------
loaded:
inBlock% = 0
FOR i% = 1 TO srcN%
    s$ = src$(i%)
    out$ = ""
    inq% = 0
    FOR j% = 1 TO LEN(s$)
        c$ = MID$(s$, j%, 1)
        IF c$ = CHR$(34) THEN inq% = 1 - inq%      ' inside "..." ?
        IF inq% = 0 THEN
            IF c$ = "#" AND inBlock% = 0 THEN EXIT FOR   ' rest is comment
            IF c$ = "@" THEN inBlock% = 1 - inBlock%: GOTO skip1
        END IF
        out$ = out$ + c$
        skip1:
    NEXT j%
    src$(i%) = trim$(out$)
NEXT i%

' ---------- pass 1b: collect labels (a line like  name:) ----------
FOR i% = 1 TO srcN%
    s$ = src$(i%)
    IF LEN(s$) > 1 AND RIGHT$(s$, 1) = ":" AND findTok%(s$, "=") = 0 THEN
        n$ = trim$(LEFT$(s$, LEN(s$) - 1))
        IF validIdent%(n$) THEN
            labelN% = labelN% + 1
            IF labelN% > 100 THEN die "too many labels", i%
            labelName$(labelN%) = UCASE$(n$)
            labelLine%(labelN%) = i% + 1
            src$(i%) = ""                  ' label line does nothing
        END IF
    END IF
NEXT i%

' ---------- pass 2: execute ----------
pc% = 1
WHILE pc% <= srcN%
    curLine% = pc%
    txt$ = src$(pc%)
    IF txt$ <> "" THEN
        kw$ = firstWord$(txt$)
        rest$ = trim$(MID$(txt$, LEN(kw$) + 1))
        SELECT CASE kw$
            CASE "PRINT"
                doPrint rest$
            CASE "INPUT"
                doInput rest$
            CASE "IF"
                j% = doIf%(rest$)
                IF j% > 0 THEN pc% = j% - 1
            CASE "GOTO"
                t% = findLabel%(rest$)
                IF t% <= 0 THEN die "unknown label '" + rest$ + "'", pc%
                pc% = t% - 1
            CASE "EXIT", "END"
                pc% = srcN% + 1
            CASE ELSE
                IF findTok%(txt$, "=") > 0 THEN
                    doAssign txt$
                ELSE
                    die "unknown statement '" + kw$ + "'", pc%
                END IF
        END SELECT
    END IF
    pc% = pc% + 1
WEND

PRINT "charm: program finished."
END

' ---------- built-in demo program ----------
loadDemo:
    srcN% = srcN% + 1: src$(srcN%) = "# Charmine demo program"
    srcN% = srcN% + 1: src$(srcN%) = "print(""Hello, World!"")"
    srcN% = srcN% + 1: src$(srcN%) = "name = input(""What is your name? "")"
    srcN% = srcN% + 1: src$(srcN%) = "print(""Nice to meet you, "" + name + ""!"")"
    srcN% = srcN% + 1: src$(srcN%) = "print(""2 + 3 * 4 = "" + (2 + 3 * 4))"
    srcN% = srcN% + 1: src$(srcN%) = "@"
    srcN% = srcN% + 1: src$(srcN%) = "   a multi-line"
    srcN% = srcN% + 1: src$(srcN%) = "   comment @"
    srcN% = srcN% + 1: src$(srcN%) = "x = 1"
    srcN% = srcN% + 1: src$(srcN%) = "again:"
    srcN% = srcN% + 1: src$(srcN%) = "print(""x = "" + x)"
    srcN% = srcN% + 1: src$(srcN%) = "x = x + 1"
    srcN% = srcN% + 1: src$(srcN%) = "if x < 4 then goto again"
    srcN% = srcN% + 1: src$(srcN%) = "print(""Done!"")"
    srcN% = srcN% + 1: src$(srcN%) = "exit"
RETURN

' ==========================================================
'                         PARSER
' ==========================================================

FUNCTION evalNum# (e$)
    ex$ = e$
    ep% = 1
    evalNum# = parseCmp#
END FUNCTION

SUB skipSpc
    WHILE ep% <= LEN(ex$) AND MID$(ex$, ep%, 1) = " "
        ep% = ep% + 1
    WEND
END SUB

FUNCTION peekC$
    CALL skipSpc
    IF ep% <= LEN(ex$) THEN peekC$ = MID$(ex$, ep%, 1) ELSE peekC$ = ""
END FUNCTION

FUNCTION parseCmp#
    v# = parseAdd#
    CALL skipSpc
    op$ = ""
    IF ep% + 1 <= LEN(ex$) THEN
        t2$ = MID$(ex$, ep%, 2)
        IF t2$ = "<=" OR t2$ = ">=" OR t2$ = "<>" OR t2$ = "==" OR t2$ = "!=" THEN
            op$ = t2$
            ep% = ep% + 2
        END IF
    END IF
    IF op$ = "" AND ep% <= LEN(ex$) THEN
        c$ = MID$(ex$, ep%, 1)
        IF c$ = "=" OR c$ = "<" OR c$ = ">" THEN op$ = c$: ep% = ep% + 1
    END IF
    IF op$ <> "" THEN
        r# = parseAdd#
        ok% = 0
        IF op$ = "=" OR op$ = "==" THEN ok% = (v# = r#)
        IF op$ = "<>" OR op$ = "!=" THEN ok% = (v# <> r#)
        IF op$ = "<" THEN ok% = (v# < r#)
        IF op$ = ">" THEN ok% = (v# > r#)
        IF op$ = "<=" THEN ok% = (v# <= r#)
        IF op$ = ">=" THEN ok% = (v# >= r#)
        IF ok% THEN v# = 1 ELSE v# = 0
    END IF
    parseCmp# = v#
END FUNCTION

FUNCTION parseAdd#
    v# = parseMul#
    DO
        c$ = peekC$
        IF c$ = "+" THEN
            ep% = ep% + 1
            v# = v# + parseMul#
        ELSEIF c$ = "-" THEN
            ep% = ep% + 1
            v# = v# - parseMul#
        ELSE
            EXIT DO
        END IF
    LOOP
    parseAdd# = v#
END FUNCTION

FUNCTION parseMul#
    v# = parseAtom#
    DO
        c$ = peekC$
        IF c$ = "*" THEN
            ep% = ep% + 1
            v# = v# * parseAtom#
        ELSEIF c$ = "/" THEN
            ep% = ep% + 1
            r# = parseAtom#
            IF r# = 0 THEN die "division by zero", curLine%
            v# = v# / r#
        ELSE
            EXIT DO
        END IF
    LOOP
    parseMul# = v#
END FUNCTION

FUNCTION parseAtom#
    c$ = peekC$
    IF c$ = "(" THEN
        ep% = ep% + 1
        v# = parseCmp#
        IF peekC$ <> ")" THEN die "missing )", curLine%
        ep% = ep% + 1
        parseAtom# = v#
        EXIT FUNCTION
    END IF
    IF c$ = "-" THEN
        ep% = ep% + 1
        parseAtom# = -parseAtom#
        EXIT FUNCTION
    END IF
    IF (c$ >= "0" AND c$ <= "9") OR c$ = "." THEN
        st% = ep%
        WHILE ep% <= LEN(ex$)
            c2$ = MID$(ex$, ep%, 1)
            IF (c2$ >= "0" AND c2$ <= "9") OR c2$ = "." THEN
                ep% = ep% + 1
            ELSE
                EXIT WHILE
            END IF
        WEND
        parseAtom# = VAL(MID$(ex$, st%, ep% - st%))
        EXIT FUNCTION
    END IF
    IF isIdent%(c$) THEN
        st% = ep%
        WHILE ep% <= LEN(ex$)
            c2$ = MID$(ex$, ep%, 1)
            IF isIdent%(c2$) OR (c2$ >= "0" AND c2$ <= "9") THEN
                ep% = ep% + 1
            ELSE
                EXIT WHILE
            END IF
        WEND
        n$ = MID$(ex$, st%, ep% - st%)
        i% = findVar%(n$)
        IF i% = 0 THEN die "undefined variable '" + n$ + "'", curLine%
        IF varType%(i%) <> 0 THEN die "'" + n$ + "' is a string, expected a number", curLine%
        parseAtom# = VAL(varVal$(i%))
        EXIT FUNCTION
    END IF
    die "cannot parse '" + c$ + "' as a number", curLine%
END FUNCTION

' ---------- string / mixed expressions ----------
FUNCTION evalStr$ (e$)
    t$ = trim$(e$)
    IF t$ = "" THEN die "empty expression", curLine%
    IF INSTR(t$, CHR$(34)) = 0 THEN
        ' pure numeric expression
        evalStr$ = numToStr$(evalNum#(t$))
    ELSE
        p% = findTok%(t$, "+")          ' string concatenation
        IF p% > 0 THEN
            evalStr$ = evalStr$(LEFT$(t$, p% - 1)) + evalStr$(MID$(t$, p% + 1))
        ELSEIF LEFT$(t$, 1) = CHR$(34) AND RIGHT$(t$, 1) = CHR$(34) AND LEN(t$) > 1 THEN
            evalStr$ = MID$(t$, 2, LEN(t$) - 2)
        ELSEIF hasLetters%(t$) THEN
            evalStr$ = getVar$(t$)
        ELSE
            evalStr$ = numToStr$(evalNum#(t$))
        END IF
    END IF
END FUNCTION

' ==========================================================
'                      SMALL HELPERS
' ==========================================================

FUNCTION trim$ (s$)
    t$ = s$
    WHILE LEFT$(t$, 1) = " ": t$ = MID$(t$, 2): WEND
    WHILE RIGHT$(t$, 1) = " ": t$ = MID$(t$, 1, LEN(t$) - 1): WEND
    trim$ = t$
END FUNCTION

FUNCTION findTok% (s$, t$)      ' find a char outside quotes/parens
    inq% = 0
    dep% = 0
    FOR i% = 1 TO LEN(s$)
        c$ = MID$(s$, i%, 1)
        IF c$ = CHR$(34) THEN inq% = 1 - inq%
        IF inq% = 0 THEN
            IF c$ = "(" THEN dep% = dep% + 1
            IF c$ = ")" THEN dep% = dep% - 1
            IF dep% = 0 AND c$ = t$ THEN findTok% = i%: EXIT FUNCTION
        END IF
    NEXT i%
    findTok% = 0
END FUNCTION

FUNCTION isIdent% (c$)
    isIdent% = 0
    IF c$ = "" THEN EXIT FUNCTION
    IF (c$ >= "a" AND c$ <= "z") OR (c$ >= "A" AND c$ <= "Z") OR c$ = "_" THEN isIdent% = 1
END FUNCTION

FUNCTION hasLetters% (s$)
    hasLetters% = 0
    u$ = UCASE$(s$)
    FOR i% = 1 TO LEN(u$)
        c$ = MID$(u$, i%, 1)
        IF c$ >= "A" AND c$ <= "Z" THEN hasLetters% = 1: EXIT FUNCTION
    NEXT i%
END FUNCTION

FUNCTION validIdent% (s$)
    validIdent% = 0
    t$ = trim$(s$)
    IF t$ = "" THEN EXIT FUNCTION
    IF isIdent%(LEFT$(t$, 1)) = 0 THEN EXIT FUNCTION
    FOR i% = 2 TO LEN(t$)
        c$ = MID$(t$, i%, 1)
        IF isIdent%(c$) = 0 AND (c$ < "0" OR c$ > "9") THEN EXIT FUNCTION
    NEXT i%
    validIdent% = 1
END FUNCTION

FUNCTION firstWord$ (s$)
    t$ = trim$(s$)
    i% = 1
    WHILE i% <= LEN(t$) AND isIdent%(MID$(t$, i%, 1)): i% = i% + 1: WEND
    firstWord$ = UCASE$(LEFT$(t$, i% - 1))
END FUNCTION

FUNCTION numToStr$ (v#)
    IF v# = INT(v#) AND ABS(v#) < 1000000000000000# THEN
        numToStr$ = LTRIM$(STR$(INT(v#)))
    ELSE
        numToStr$ = LTRIM$(STR$(v#))
    END IF
END FUNCTION

' ==========================================================
'                       VARIABLES
' ==========================================================

FUNCTION findVar% (n$)
    u$ = UCASE$(trim$(n$))
    findVar% = 0
    FOR i% = 1 TO varN%
        IF varName$(i%) = u$ THEN findVar% = i%: EXIT FUNCTION
    NEXT i%
END FUNCTION

SUB setVar (n$, v$, t%)
    u$ = UCASE$(trim$(n$))
    IF validIdent%(u$) = 0 THEN die "bad variable name '" + n$ + "'", curLine%: EXIT SUB
    i% = findVar%(u$)
    IF i% = 0 THEN
        varN% = varN% + 1
        IF varN% > 100 THEN die "too many variables", curLine%
        i% = varN%
        varName$(i%) = u$
    END IF
    varVal$(i%) = v$
    varType%(i%) = t%
END SUB

FUNCTION getVar$ (n$)
    i% = findVar%(n$)
    IF i% = 0 THEN die "undefined variable '" + trim$(n$) + "'", curLine%: EXIT FUNCTION
    getVar$ = varVal$(i%)
END FUNCTION

' ==========================================================
'                        STATEMENTS
' ==========================================================

SUB doPrint (rest$)
    t$ = trim$(rest$)
    IF LEFT$(t$, 1) <> "(" OR RIGHT$(t$, 1) <> ")" THEN
        die "print needs parentheses, like print(""hi"")", curLine%: EXIT SUB
    END IF
    inner$ = MID$(t$, 2, LEN(t$) - 2)
    out$ = ""
    first% = 1
    WHILE trim$(inner$) <> ""
        inner$ = trim$(inner$)
        p% = findTok%(inner$, ",")
        IF p% = 0 THEN
            part$ = inner$
            inner$ = ""
        ELSE
            part$ = LEFT$(inner$, p% - 1)
            inner$ = MID$(inner$, p% + 1)
        END IF
        IF first% = 0 THEN out$ = out$ + " "
        out$ = out$ + evalStr$(part$)
        first% = 0
    WEND
    PRINT out$
END SUB

FUNCTION askUser$ (promptExpr$)
    PRINT evalStr$(promptExpr$);
    LINE INPUT u$
    askUser$ = u$
END FUNCTION

SUB doInput (rest$)
    t$ = trim$(rest$)
    IF LEFT$(t$, 1) <> "(" OR RIGHT$(t$, 1) <> ")" THEN
        die "input needs parentheses", curLine%: EXIT SUB
    END IF
    inner$ = MID$(t$, 2, LEN(t$) - 2)
    p% = findTok%(inner$, ",")
    IF p% = 0 THEN die "input needs a prompt and a variable", curLine%: EXIT SUB
    v$ = askUser$(LEFT$(inner$, p% - 1))
    setVar MID$(inner$, p% + 1), v$, 1
END SUB

SUB doAssign (txt$)
    p% = findTok%(txt$, "=")
    lhs$ = trim$(LEFT$(txt$, p% - 1))
    rhs$ = trim$(MID$(txt$, p% + 1))
    IF validIdent%(lhs$) = 0 THEN die "bad variable name '" + lhs$ + "'", curLine%: EXIT SUB
    IF firstWord$(rhs$) = "INPUT" THEN
        '  name = input("prompt")
        t$ = trim$(rhs$)
        t$ = trim$(MID$(t$, 6))
        IF LEFT$(t$, 1) <> "(" OR RIGHT$(t$, 1) <> ")" THEN
            die "input needs ( )", curLine%: EXIT SUB
        END IF
        setVar lhs$, askUser$(MID$(t$, 2, LEN(t$) - 2)), 1
    ELSEIF INSTR(rhs$, CHR$(34)) > 0 THEN
        setVar lhs$, evalStr$(rhs$), 1
    ELSE
        setVar lhs$, numToStr$(evalNum#(rhs$)), 0
    END IF
END SUB

FUNCTION findLabel% (n$)
    u$ = UCASE$(trim$(n$))
    findLabel% = -1
    FOR i% = 1 TO labelN%
        IF labelName$(i%) = u$ THEN findLabel% = labelLine%(i%): EXIT FUNCTION
    NEXT i%
END FUNCTION

FUNCTION doIf% (rest$)
    u$ = UCASE$(rest$)
    p% = INSTR(u$, " THEN ")
    IF p% = 0 THEN die "if without 'then'", curLine%
    tp$ = trim$(MID$(rest$, p% + 6))
    IF UCASE$(LEFT$(tp$, 5)) <> "GOTO " THEN
        die "only 'goto' is allowed after 'then'", curLine%
    END IF
    doIf% = 0
    IF evalNum#(LEFT$(rest$, p% - 1)) <> 0 THEN
        t% = findLabel%(MID$(tp$, 6))
        IF t% <= 0 THEN die "unknown label in if", curLine%
        doIf% = t%
    END IF
END FUNCTION

SUB die (msg$, ln%)
    PRINT "charm: error on line"; ln%; ": "; msg$
    END
END SUB

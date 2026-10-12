' ==========================================================
'  lexer.bas -- turns one .charm source line into tokens.
'  Fills tokType%(), tokText$() and sets tokN%.
'  Handles  # comments,  @...@ block comments, strings,
'  numbers, names and operators (<=, >=, ==, !=, <> too).
' ==========================================================

SUB lexLine (s$)
    tokN% = 0
    i% = 1
    WHILE i% <= LEN(s$)
        c$ = MID$(s$, i%, 1)
        IF lexBlock% THEN
            ' inside a block comment only @ can wake us up
            IF c$ = "@" THEN lexBlock% = 0
            i% = i% + 1
        ELSEIF c$ = " " OR c$ = CHR$(9) THEN
            i% = i% + 1                      ' skip whitespace
        ELSEIF c$ = "#" THEN
            EXIT SUB                         ' rest of line is a comment
        ELSEIF c$ = "@" THEN
            lexBlock% = 1
            i% = i% + 1
        ELSEIF c$ = CHR$(34) THEN
            ' string literal "...": store the text without quotes
            j% = i% + 1
            t$ = ""
            WHILE j% <= LEN(s$) AND MID$(s$, j%, 1) <> CHR$(34)
                t$ = t$ + MID$(s$, j%, 1)
                j% = j% + 1
            WEND
            IF j% > LEN(s$) THEN die "string without closing quote", curLine%
            addTok T.STR, t$
            i% = j% + 1
        ELSEIF (c$ >= "0" AND c$ <= "9") OR c$ = "." THEN
            j% = i%
            t$ = ""
            WHILE j% <= LEN(s$) AND ((MID$(s$, j%, 1) >= "0" AND MID$(s$, j%, 1) <= "9") OR MID$(s$, j%, 1) = ".")
                t$ = t$ + MID$(s$, j%, 1)
                j% = j% + 1
            WEND
            addTok T.NUM, t$
            i% = j%
        ELSEIF isChr%(c$) THEN
            ' a name: letters, digits and _
            j% = i%
            WHILE j% <= LEN(s$) AND (isChr%(MID$(s$, j%, 1)) OR (MID$(s$, j%, 1) >= "0" AND MID$(s$, j%, 1) <= "9"))
                j% = j% + 1
            WEND
            addTok T.IDENT, MID$(s$, i%, j% - i%)
            i% = j%
        ELSE
            ' operators; two-character ones first
            t2$ = MID$(s$, i%, 2)
            IF t2$ = "<=" OR t2$ = ">=" OR t2$ = "==" OR t2$ = "!=" OR t2$ = "<>" THEN
                addTok T.OP, t2$
                i% = i% + 2
            ELSEIF INSTR("+-*/(),:=<>", c$) > 0 THEN
                addTok T.OP, c$
                i% = i% + 1
            ELSE
                die "unexpected character '" + c$ + "'", curLine%
            END IF
        END IF
    WEND
END SUB

SUB addTok (ty%, tx$)
    tokN% = tokN% + 1
    IF tokN% > 200 THEN die "too many tokens on one line", curLine%
    tokType%(tokN%) = ty%
    tokText$(tokN%) = tx$
END SUB

FUNCTION isChr% (c$)
    isChr% = 0
    IF c$ = "" THEN EXIT FUNCTION
    IF (c$ >= "a" AND c$ <= "z") OR (c$ >= "A" AND c$ <= "Z") OR c$ = "_" THEN isChr% = 1
END FUNCTION

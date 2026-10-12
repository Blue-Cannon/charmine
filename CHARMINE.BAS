' ==========================================
' CHARMINE Interpreter v0.1
' Language: Charmine (.charm files)
' Host: QBASIC / QB64
' Author: Rogge Ramos
' ==========================================

DECLARE SUB CharmineRun (fileName$)

' --- Main ---
CLS
PRINT "Charmine Interpreter v0.1 - (c) Rogge"
PRINT "Host: QBASIC"
PRINT "-------------------------------"
INPUT "Enter .charm file to run (ex: TEST.CHARM): ", f$
IF f$ = "" THEN f$ = "TEST.CHARM"
CALL CharmineRun(f$)
END

SUB CharmineRun (fileName$)
    DIM varNames(100) AS STRING
    DIM varValues(100) AS STRING
    DIM varCount AS INTEGER
    varCount = 0

    ON ERROR GOTO FileError
    OPEN fileName$ FOR INPUT AS #1
    ON ERROR GOTO 0

    DO WHILE NOT EOF(1)
        LINE INPUT #1, line$
        origLine$ = line$
        line$ = LTRIM$(RTRIM$(line$))
        
        IF line$ = "" THEN GOTO NextLine
        IF LEFT$(line$, 2) = "//" THEN GOTO NextLine
        IF LEFT$(line$, 1) = "'" THEN GOTO NextLine

        ' --- let name = value ---
        IF LCASE$(LEFT$(line$, 4)) = "let " THEN
            rest$ = MID$(line$, 5)
            eqPos = INSTR(rest$, "=")
            IF eqPos > 0 THEN
                vName$ = LTRIM$(RTRIM$(LEFT$(rest$, eqPos - 1)))
                vValue$ = LTRIM$(RTRIM$(MID$(rest$, eqPos + 1)))
                ' Remove quotes if string
                IF LEFT$(vValue$, 1) = CHR$(34) AND RIGHT$(vValue$, 1) = CHR$(34) THEN
                    vValue$ = MID$(vValue$, 2, LEN(vValue$) - 2)
                END IF
                
                ' Check if var exists
                found = 0
                FOR i = 1 TO varCount
                    IF varNames(i) = vName$ THEN
                        varValues(i) = vValue$
                        found = 1
                        EXIT FOR
                    END IF
                NEXT i
                IF found = 0 THEN
                    varCount = varCount + 1
                    varNames(varCount) = vName$
                    varValues(varCount) = vValue$
                END IF
            END IF
        END IF

        ' --- case("text") -> main output command of Charmine ---
        IF LCASE$(LEFT$(line$, 5)) = "case(" THEN
            ' Extract inside case(...)
            p1 = INSTR(line$, "(")
            p2 = INSTR(line$, ")")
            IF p1 > 0 AND p2 > p1 THEN
                out$ = MID$(line$, p1 + 1, p2 - p1 - 1)
                ' Remove quotes
                out$ = LTRIM$(RTRIM$(out$))
                IF LEFT$(out$, 1) = CHR$(34) AND RIGHT$(out$, 1) = CHR$(34) THEN
                    out$ = MID$(out$, 2, LEN(out$) - 2)
                END IF
                ' Variable substitution {var}
                FOR i = 1 TO varCount
                    search$ = "{" + varNames(i) + "}"
                    DO WHILE INSTR(out$, search$) > 0
                        p = INSTR(out$, search$)
                        out$ = LEFT$(out$, p - 1) + varValues(i) + MID$(out$, p + LEN(search$))
                    LOOP
                NEXT i
                ' If out$ is just a variable name
                FOR i = 1 TO varCount
                    IF out$ = varNames(i) THEN out$ = varValues(i)
                NEXT i
                PRINT out$
            END IF
        END IF

        ' --- keep print for compatibility ---
        IF LCASE$(LEFT$(line$, 6)) = "print " THEN
            out$ = MID$(line$, 7)
            FOR i = 1 TO varCount
                search$ = "{" + varNames(i) + "}"
                DO WHILE INSTR(out$, search$) > 0
                    p = INSTR(out$, search$)
                    out$ = LEFT$(out$, p - 1) + varValues(i) + MID$(out$, p + LEN(search$))
                LOOP
            NEXT i
            FOR i = 1 TO varCount
                IF out$ = varNames(i) THEN out$ = varValues(i)
            NEXT i
            IF LEFT$(out$, 1) = CHR$(34) AND RIGHT$(out$, 1) = CHR$(34) THEN
                out$ = MID$(out$, 2, LEN(out$) - 2)
            END IF
            PRINT out$
        END IF

        ' --- cls ---
        IF LCASE$(line$) = "cls" THEN CLS

NextLine:
    LOOP
    CLOSE #1
    PRINT ""
    PRINT "--- Program finished ---"
    EXIT SUB

FileError:
    PRINT "Error: Could not open "; fileName$
    PRINT "Make sure TEST.CHARM is in same folder as CHARMINE.BAS"
    RESUME NEXT
END SUB

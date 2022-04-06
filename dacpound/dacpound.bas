REM *********** DACPOUND.BAS *********************
REM * Brought to you by Eudimorphodon
REM * AKA "Paleozoic PCs", 2022
REM *
REM * Run to see if your VGA card's DAC
REM * generates snow when the port registers
REM * are updated. Simply run, ignore the
REM * tearing grayscale bar cycling in the
REM * middle of the screen, and look to see
REM * if off-color specks/sparkles are appearing
REM * anywhere else on the screen.
REM *
REM * For best results this program should be
REM * be compiled in Microsoft QuickBasic. It
REM * will run under the QBasic interpreter
REM * included with DOS 5.0 and up, but unless
REM * you have a fast machine it may not pound
REM * on the registers hard enough to generate
REM * significant snow. When compiled without
REM * debug using QB 4.5 it runs more than fast enough
REM * to generate snow on a 4.77mhz XT
REM ****************************************************

DEFINT A-Z
SCREEN 13
y = 0

REM init screen
FOR x = 0 TO 255
LINE (x, 10)-(x, 199), x
NEXT x


PRINT "Press ESC to exit"
REM main loop
DO

OUT &H3C8, 192
FOR x = 0 TO 63
OUT &H3C9, y
OUT &H3C9, y
OUT &H3C9, y
y = y + 1: IF y > 63 THEN y = y - 63
NEXT x

LOOP UNTIL INKEY$ = CHR$(27)


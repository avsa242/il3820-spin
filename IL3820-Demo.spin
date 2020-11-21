{
    --------------------------------------------
    Filename: IL3820-Demo.spin
    Author: Jesse Burt
    Description: Demo of the IL3820 driver
    Copyright (c) 2020
    Started Nov 30, 2019
    Updated Nov 21, 2020
    See end of file for terms of use.
    --------------------------------------------
}

CON

    _clkmode    = cfg#_clkmode
    _xinfreq    = cfg#_xinfreq

' -- User-modifiable constants
    LED         = cfg#LED1
    SER_BAUD    = 115_200

    DIN         = 0                            ' E-Paper I/O pins
    CLK         = 1
    CS          = 2
    DC          = 3
    RST         = 4
    BUSY        = 5

    WIDTH       = 128
    HEIGHT      = 296
' --

    XMAX        = WIDTH-1
    YMAX        = HEIGHT-1
    BUFF_SZ     = WIDTH * ((HEIGHT + 7) / 8)

OBJ

    cfg     : "core.con.boardcfg.activityboard"
    ser     : "com.serial.terminal.ansi"
    time    : "time"
    epaper  : "display.epaper.il3820.spi"
    fnt     : "font.5x8"

VAR

    byte _framebuff[BUFF_SZ]

PUB Main{} | i

    setup{}
    ser.position(0, 3)

    repeat until epaper.displayready{}          ' Wait for display to be ready

    epaper.bgcolor($FF)
    epaper.clear{}
    epaper.fgcolor(0)
    epaper.box(0, 0, XMAX, YMAX, 0, FALSE)
    epaper.position(5, 5)
    epaper.str(string("HELLO WORLD"))

    epaper.line(0, 0, 100, 100, 0)              ' Draw diagonal line
    repeat i from 0 to 64 step 10
        epaper.circle(64, 148, i, 0)

    repeat i from 0 to 100                      ' Same, mirrored, using Plot()
        epaper.plot(127-i, i, 0)
    epaper.box(28, 100, 100, 200, 0, FALSE)

    hrule{}
    vrule{}

    epaper.update{}                             ' Update the display

    repeat

PUB HRule{} | x, grad_len
' Draw a simple rule along the x-axis
    grad_len := 5

    repeat x from 0 to WIDTH step 5
        if x // 10 == 0
            epaper.line(x, 0, x, grad_len, -1)
        else
            epaper.line(x, 0, x, grad_len*2, -1)

PUB VRule{} | y, grad_len
' Draw a simple rule along the y-axis
    grad_len := 5

    repeat y from 0 to HEIGHT step 5
        if y // 10 == 0
            epaper.line(0, y, grad_len, y, -1)
        else
            epaper.line(0, y, grad_len*2, y, -1)

PUB Setup{}

    ser.start(SER_BAUD)
    time.msleep(100)
    ser.clear{}
    ser.strln(string("Serial terminal started"))
    if epaper.start(CS, CLK, DIN, DC, RST, BUSY, WIDTH, HEIGHT, @_framebuff)
        ser.strln(string("IL3820 driver started"))
        epaper.fontaddress(fnt.baseaddr{})
        epaper.fontsize(6, 8)
    else
        ser.strln(string("IL3820 driver failed to start - halting"))
        epaper.stop{}
        time.msleep(500)
        ser.stop{}

DAT
'1024 bytes
    Beanie      byte    $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
                byte    $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $80, $C0
                byte    $C0, $C0, $C0, $C0, $C0, $C0, $C0, $C0, $80, $80, $80, $80, $00, $00, $00, $00
                byte    $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $80
                byte    $80, $00, $00, $00, $80, $80, $80, $80, $C0, $C0, $C0, $C0, $C0, $E0, $E0, $E0
                byte    $E0, $E0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0
                byte    $E0, $E0, $80, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
                byte    $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
                byte    $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
                byte    $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $0F, $1F, $3F
                byte    $3F, $7F, $7F, $7F, $7F, $7F, $7F, $7F, $7F, $7F, $7F, $7F, $3F, $3F, $3F, $3F
                byte    $3F, $3F, $1F, $1F, $1E, $1E, $1E, $0E, $0E, $0E, $0E, $06, $06, $06, $F7, $FF
                byte    $FF, $F7, $03, $03, $03, $03, $03, $03, $03, $03, $03, $03, $03, $03, $03, $07
                byte    $07, $07, $07, $07, $07, $0F, $0F, $0F, $0F, $0F, $1F, $1F, $1F, $1F, $1F, $1F
                byte    $0F, $0F, $07, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
                byte    $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
                byte    $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
                byte    $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
                byte    $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
                byte    $00, $80, $C0, $C0, $E0, $E0, $60, $70, $30, $30, $18, $18, $C8, $FF, $FF, $FF
                byte    $FF, $FF, $FF, $C8, $18, $18, $30, $30, $70, $60, $E0, $E0, $C0, $C0, $80, $00
                byte    $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
                byte    $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
                byte    $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
                byte    $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
                byte    $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
                byte    $00, $00, $00, $00, $00, $00, $00, $00, $80, $C0, $E0, $F0, $F8, $FC, $FE, $7F
                byte    $3F, $0F, $07, $03, $01, $00, $00, $00, $00, $C0, $FC, $FF, $FF, $FF, $FF, $FF
                byte    $FF, $FF, $FF, $FF, $FF, $FC, $C0, $00, $00, $00, $00, $01, $03, $07, $0F, $3F
                byte    $7F, $FE, $FC, $F8, $F0, $E0, $C0, $80, $00, $00, $00, $00, $00, $00, $00, $00
                byte    $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
                byte    $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
                byte    $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
                byte    $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
                byte    $00, $00, $00, $80, $E0, $F8, $FC, $FF, $FF, $FF, $FF, $FF, $3F, $07, $01, $00
                byte    $00, $00, $00, $00, $00, $00, $00, $00, $F8, $FF, $FF, $FF, $FF, $FF, $FF, $FF
                byte    $FF, $FF, $FF, $FF, $FF, $FF, $FF, $F8, $00, $00, $00, $00, $00, $00, $00, $00
                byte    $00, $01, $07, $3F, $FF, $FF, $FF, $FF, $FF, $FC, $F8, $E0, $80, $00, $00, $00
                byte    $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
                byte    $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
                byte    $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
                byte    $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
                byte    $00, $C0, $FC, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $BF, $81, $80, $80, $80, $C0
                byte    $C0, $C0, $C0, $C0, $C0, $C0, $C0, $F0, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
                byte    $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $F0, $C0, $C0, $C0, $C0, $C0, $C0, $C0
                byte    $C0, $80, $80, $80, $81, $BF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FC, $C0, $00
                byte    $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
                byte    $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
                byte    $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
                byte    $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
                byte    $78, $FF, $FF, $FF, $FF, $FF, $FF, $CF, $CF, $CF, $CF, $CF, $C7, $87, $87, $87
                byte    $87, $87, $87, $87, $87, $87, $87, $07, $03, $03, $03, $03, $03, $03, $03, $03
                byte    $03, $03, $03, $03, $03, $03, $03, $03, $07, $87, $87, $87, $87, $87, $87, $87
                byte    $87, $87, $87, $C7, $CF, $CF, $CF, $CF, $CF, $FF, $FF, $FF, $FF, $FF, $FF, $78
                byte    $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
                byte    $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
                byte    $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
                byte    $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
                byte    $00, $00, $01, $01, $03, $03, $03, $03, $03, $07, $07, $07, $07, $07, $07, $07
                byte    $0F, $0F, $0F, $0F, $0F, $0F, $0F, $0F, $0F, $0F, $0F, $0F, $0F, $0F, $0F, $0F
                byte    $0F, $0F, $0F, $0F, $0F, $0F, $0F, $0F, $0F, $0F, $0F, $0F, $0F, $0F, $0F, $0F
                byte    $07, $07, $07, $07, $07, $07, $07, $03, $03, $03, $03, $03, $01, $01, $00, $00
                byte    $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
                byte    $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00

DAT
{
    --------------------------------------------------------------------------------------------------------
    TERMS OF USE: MIT License

    Permission is hereby granted, free of charge, to any person obtaining a copy of this software and
    associated documentation files (the "Software"), to deal in the Software without restriction, including
    without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
    copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the
    following conditions:

    The above copyright notice and this permission notice shall be included in all copies or substantial
    portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT
    LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
    IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
    WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
    SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
    --------------------------------------------------------------------------------------------------------
}

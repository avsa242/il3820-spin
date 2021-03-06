{
    --------------------------------------------
    Filename: IL3820-Demo.spin
    Author: Jesse Burt
    Description: Demo of the IL3820 driver
    Copyright (c) 2021
    Started Nov 30, 2019
    Updated Apr 4, 2021
    See end of file for terms of use.
    --------------------------------------------
}

CON

    _clkmode    = cfg#_clkmode
    _xinfreq    = cfg#_xinfreq

' -- User-modifiable constants
    LED         = cfg#LED1
    SER_BAUD    = 115_200

    DIN         = 0
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

    cfg     : "core.con.boardcfg.flip"
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

    epaper.bgcolor(epaper#WHITE)                ' set BG color for text, and
    epaper.clear{}                              '   also Clear() color
    epaper.fgcolor(epaper#BLACK)                ' set FG color for text
    epaper.box(0, 0, XMAX, YMAX, 0, FALSE)      ' draw box full-screen size

    epaper.position(5, 5)
    epaper.str(string("HELLO WORLD"))

    epaper.line(0, 0, 100, 100, 0)              ' Draw diagonal line

    repeat i from 0 to 100                      ' Same, mirrored, using Plot()
        epaper.plot(127-i, i, 0)

    repeat i from 0 to 64 step 10               ' concentric circles
        epaper.circle(64, 148, i, 0, false)

    epaper.box(28, 100, 100, 200, 0, FALSE)     ' box around circles

    hrule{}                                     ' draw rulers at screen edges
    vrule{}

    epaper.update{}                             ' Update the display

    repeat

PUB HRule{} | x, grad_len
' Draw a simple rule along the x-axis
    grad_len := 5

    repeat x from 0 to WIDTH step 5
        if x // 10 == 0
            epaper.line(x, 0, x, grad_len, epaper#INVERT)
        else
            epaper.line(x, 0, x, grad_len*2, epaper#INVERT)

PUB VRule{} | y, grad_len
' Draw a simple rule along the y-axis
    grad_len := 5

    repeat y from 0 to HEIGHT step 5
        if y // 10 == 0
            epaper.line(0, y, grad_len, y, epaper#INVERT)
        else
            epaper.line(0, y, grad_len*2, y, epaper#INVERT)

PUB Setup{}

    ser.start(SER_BAUD)
    time.msleep(30)
    ser.clear{}
    ser.strln(string("Serial terminal started"))
    if epaper.startx(CS, CLK, DIN, DC, RST, BUSY, WIDTH, HEIGHT, @_framebuff)
        ser.strln(string("IL3820 driver started"))
        epaper.fontscale(1)
        epaper.fontaddress(fnt.baseaddr{})
        epaper.fontsize(6, 8)
    else
        ser.strln(string("IL3820 driver failed to start - halting"))
        epaper.stop{}
        time.msleep(500)
        ser.stop{}

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

{
----------------------------------------------------------------------------------------------------
    Filename:       Il3820-Demo.spin
    Description:    IL3820-specific setup for E-Ink/E-Paper graphics demo
    Author:         Jesse Burt
    Started:        Jul 2, 2022
    Updated:        Jul 16, 2026
    Copyright (c) 2026 - See end of file for terms of use.
----------------------------------------------------------------------------------------------------
}

CON

    _clkmode    = xtal1+pll16x
    _xinfreq    = 5_000_000


OBJ

    ser:    "com.serial.terminal.ansi" | SER_BAUD=115_200
    epaper: "display.epaper.il3820" | WIDTH=128, HEIGHT=296, ...
                                        CS=0, SCK=1, MOSI=2, DC=3, RST=4, BUSY=5
    time:   "time"
    fnt:    "font.5x8"

    ' NOTE: The WIDTH and HEIGHT are the panel's physical size and generally don't need to be
    '   changed. These aren't used to change the display orientation/rotation. That can be
    '   set using the set_rotation() method shown below.


PUB main()

    ser.start()
    time.msleep(30)
    ser.clear()
    ser.strln(@"Serial terminal started")

    if ( epaper.start() )
        ser.strln(@"E-ink driver started")
        epaper.set_font(fnt.ptr(), fnt.setup())
    else
        ser.strln(@"E-ink driver failed to start - halting")
        repeat

    epaper.preset_2p9_bw()
    epaper.set_rotation(0)                      ' rotate screen by 0, 90, 180, 270 deg
    demo()                                      ' start demo
    repeat


DAT

    _test_txt byte "HELLO WORLD", 0


PUB demo() | i

    repeat
    until epaper.disp_rdy()                     ' Wait for display to be ready

    epaper.bgcolor(epaper.WHITE)                ' set BG color for text, and
    epaper.clear()                              '   also Clear() color
    epaper.fgcolor(epaper.BLACK)                ' set FG color for text
    epaper.box(0, 0, epaper._disp_xmax, epaper._disp_ymax, 0, FALSE)      ' draw box full-screen size

    { find center X pos_xy for test text and draw it }
    epaper.pos_xy((epaper.textcols() / 2)-(strsize(@_test_txt) / 2), 2)
    epaper.str(@_test_txt)

    { diagonal lines }
    epaper.line(0, 0, epaper._disp_xmax, epaper._disp_ymax, 0)
    epaper.line(epaper._disp_xmax, 0, 0, epaper._disp_ymax, 0)

    { concentric circles }
    repeat i from 0 to (epaper._disp_width/2) step 10
        epaper.circle(epaper._disp_width/2, epaper._disp_height/2, i, 0, false)

    hrule()                                     ' draw rulers at screen edges
    vrule()

    epaper.show()                               ' Update the display


PUB hrule() | x, grad_len
' Draw a simple rule along the x-axis
    grad_len := 5

    repeat x from 0 to epaper._disp_xmax step 4
        ifnot (x // 8)                          ' minor ticks
            epaper.line(x, 0, x, grad_len, epaper.INVERT)
        else                                    ' major ticks
            epaper.line(x, 0, x, grad_len*2, epaper.INVERT)


PUB vrule() | y, grad_len
' Draw a simple rule along the y-axis
    grad_len := 5

    repeat y from 0 to epaper._disp_ymax step 4
        ifnot (y // 8)
            epaper.line(0, y, grad_len, y, epaper.INVERT)
        else
            epaper.line(0, y, grad_len*2, y, epaper.INVERT)


DAT
{
Copyright 2026 Jesse Burt

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and
associated documentation files (the "Software"), to deal in the Software without restriction,
including without limitation the rights to use, copy, modify, merge, publish, distribute,
sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or
substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT
NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT
OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
}


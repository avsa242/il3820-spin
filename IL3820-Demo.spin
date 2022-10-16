{
    --------------------------------------------
    Filename: Il3820-Demo.spin
    Description: IL3820-specific setup for E-Ink/E-Paper graphics demo
    Author: Jesse Burt
    Copyright (c) 2022
    Started: Jul 2, 2022
    Updated: Oct 16, 2022
    See end of file for terms of use.
    --------------------------------------------
}
CON

    _clkmode    = cfg#_clkmode
    _xinfreq    = cfg#_xinfreq

' -- User-modifiable constants
    LED         = cfg#LED1
    SER_BAUD    = 115_200

    WIDTH       = 128
    HEIGHT      = 296

{ SPI configuration }
    CS_PIN      = 0
    SCK_PIN     = 1
    MOSI_PIN    = 2
    DC_PIN      = 3
    BUSY_PIN    = 4
    RES_PIN     = 5
' --

    BPP         = epaper#BYTESPERPX
    BYTESPERLN  = WIDTH * BPP
    BUFF_SZ     = ((WIDTH * HEIGHT) * BPP) / 8

OBJ

    cfg     : "boardcfg.flip"
    epaper  : "display.epaper.il3820"

PUB main{}

    ser.start(SER_BAUD)
    time.msleep(30)
    ser.clear{}
    ser.strln(string("Serial terminal started"))

    if epaper.startx(CS_PIN, SCK_PIN, MOSI_PIN, DC_PIN, RES_PIN, BUSY_PIN, WIDTH, HEIGHT, {
}   @_disp_buff)
        ser.printf1(string("%s driver started"), @_drv_name)
        epaper.fontspacing(1, 0)
        epaper.fontsize(fnt#WIDTH, fnt#HEIGHT)
        epaper.fontscale(1)
        epaper.fontaddress(fnt.ptr{})
    else
        ser.printf1(string("%s driver failed to start - halting"), @_drv_name)
        repeat

    epaper.preset_2p9_bw{}
    demo{}                                      ' start demo
    repeat

{ demo routines (common to all display types) included here }
#include "EInkDemo-common.spinh"

DAT
    _drv_name   byte    "IL3820 (SPI)", 0

{
Copyright 2022 Jesse Burt

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


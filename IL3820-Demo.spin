{
    --------------------------------------------
    Filename: IL3820-Demo.spin
    Author: Jesse Burt
    Description: Demo of the IL3820 driver
    Copyright (c) 2019
    Started Nov 30, 2019
    Updated Dec 1, 2019
    See end of file for terms of use.
    --------------------------------------------
}

CON

    _clkmode    = cfg#_clkmode
    _xinfreq    = cfg#_xinfreq

    LED         = cfg#LED1

    DIN_PIN     = 11
    CLK_PIN     = 10
    CS_PIN      = 9
    DC_PIN      = 8
    RST_PIN     = 7
    BUSY_PIN    = 6

    DISP_WIDTH  = 128
    DISP_HEIGHT = 296
    BUFF_SZ     = DISP_WIDTH * ((DISP_HEIGHT + 7) >> 3)
'width * ((height + 7) >> 3)
OBJ

    cfg     : "core.con.boardcfg.activityboard"
    ser     : "com.serial.terminal.ansi"
    time    : "time"
    io      : "io"
    eink    : "display.electrophoretic.il3820.spi"

VAR

    byte _draw_buff[BUFF_SZ]
    byte _ser_cog

PUB Main | i, la

    Setup
    ser.Position (0, 3)

    repeat until not eink.Busy

    ser.Position (0, 3)
    ser.Str (string("Ready", ser#CR, ser#LF))
    ser.str (string("Clearing..."))
    eink.Clear
    repeat until not eink.Busy
    ser.str (string("done", ser#CR, ser#LF))

    ser.str (string("writing bitmap..."))
    bytefill(@_draw_buff, $FF, BUFF_SZ)
    bytemove(@_draw_buff, @beanie, 1024)
    eink.Bitmap(@_draw_buff, BUFF_SZ)
    eink.Refresh

    repeat until not eink.Busy
    ser.str (string("done", ser#CR, ser#LF))

'    eink.Update
    FlashLED (LED, 100)

PUB Setup

    repeat until _ser_cog := ser.Start (115_200)
    time.msleep(100)
    ser.Clear
    ser.Str(string("Serial terminal started", ser#CR, ser#LF))
    eink.DrawBuffer (@_draw_buff)
    if eink.Start (CS_PIN, CLK_PIN, DIN_PIN, DC_PIN, RST_PIN, BUSY_PIN, DISP_WIDTH, DISP_HEIGHT)
        ser.Str (string("IL3820 driver started (disp addr $"))
        ser.Hex (eink.DrawBuffer (-2), 4)
        ser.Str (string(", size "))
        ser.Dec (BUFF_SZ)
        ser.Char ("/")
        ser.Dec (eink.buffsz)
        ser.Str (string(" bytes)"))
    else
        ser.Str (string("IL3820 driver failed to start - halting"))
        eink.Stop
        time.MSleep (500)
        ser.Stop
        FlashLED (LED, 500)

PUB FlashLED(led_pin, delay_ms)

    io.Output (led_pin)
    repeat
        io.Toggle (led_pin)
        time.MSleep (delay_ms)

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

{
----------------------------------------------------------------------------------------------------
    Filename:       display.epaper.il3820.spin
    Description:    Driver for the IL3820 electrophoretic display controller
    Author:         Jesse Burt
    Started:        Nov 30, 2019
    Updated:        Jul 15, 2026
    Copyright (c) 2026 - See end of file for terms of use.
----------------------------------------------------------------------------------------------------
}

#define 1BPP
#define MEMMV_NATIVE bytemove
#include "graphics.common.spinh"
#ifdef GFX_DIRECT
# error "GFX_DIRECT not supported by this driver"
#endif

CON

    ' -- default I/O settings; these can be overridden in the parent object
    ' display dimensions
    ' NOTE: These are hardware-specific panel dimensions that don't change while the driver is
    '   running, and generally don't need to be changed from the default below. They don't
    '   reflect what orientation is being used to draw the display, which can optionally
    '   be changed at runtime using set_rotation() (see graphics.common.spinh).
    WIDTH           = 128
    HEIGHT          = 296

    ' SPI
    CS              = 0
    SCK             = 1
    MOSI            = 2
    DC              = 3
    RST             = 4
    BUSY            = 5
    SPI_FREQ        = 1_000_000
    ' --

    ' automatically computed - do not change
    BPP             = 1                             ' bits per pixel/color depth of the display
    BYTESPERPX      = 1 #> (BPP/8)                  ' limit to minimum of 1
    BPPDIV          = (8 / BPP) #> BYTESPERPX       ' limit to range BYTESPERPX .. (8/BPP)
    BUFF_SZ         = (WIDTH * HEIGHT) / BPPDIV
    MAX_COLOR       = (1 << BPP)-1
    XMAX            = WIDTH-1
    YMAX            = HEIGHT-1
    CENTERX         = WIDTH/2
    CENTERY         = HEIGHT/2


' Colors
    BLACK           = 0
    WHITE           = $FF
    INVERT          = -1


' Border waveform control
    GS_TRANS        = %00
    FIXEDLEV        = %01
    VCOM            = %10
    HIZ             = %11

    BRD_VSS         = %00
    BRD_VSH1        = %01
    BRD_VSL         = %10
    BRD_VSH2        = %11

    FLWLUT_VCOMRED  = 0
    FLWLUT          = 1

    LUT0            = %00
    LUT1            = %01
    LUT2            = %10
    LUT3            = %11

' Display addressing modes
    HORIZ           = 0
    VERT            = 1
    YD_XD           = %00
    YD_XI           = %01
    YI_XD           = %10
    YI_XI           = %11

' Source drive voltage control
    VSH1            = 0
    VSH2            = 1
    VSL             = 2

' Waveform LUT offsets
    WV_LUT0         = 0
    WV_LUT1         = 7
    WV_LUT2         = 14
    WV_LUT3         = 21
    WV_LUT4         = 28
    WV_TP0          = 35
    WV_TP1          = 40
    WV_TP2          = 45
    WV_TP3          = 50
    WV_TP4          = 55
    WV_TP5          = 60
    WV_TP6          = 65

    GDC             = 70
    SDC0            = 71
    SDC1            = 72
    SDC2            = 73
    DL              = 74
    GT              = 75


VAR

    byte _CS, _DC, _RST, _BUSY
    byte _data_entr_mode, _drv_out_ctrl[3]
    byte _gate_drv_volt
    byte _framebuffer[BUFF_SZ]


OBJ

{ decide: Bytecode SPI engine, or PASM? Default is PASM if BC isn't specified }
#ifdef IL3820_SPI_BC
    spi:    "com.spi.25khz.nocog"               ' BC SPI engine
#else
    spi:    "com.spi.1mhz"                      ' PASM SPI engine
#endif
    core:   "core.con.il3820"                   ' HW-specific constants
    time:   "time"


PUB null()
' This is not a top-level object


PUB start(): s
' Start using default I/O settings
'   Returns: cog ID + 1 of the SPI engine
    return startx(CS, SCK, MOSI, DC, RST, BUSY, WIDTH, HEIGHT, @_framebuffer)


PUB startx(CS_PIN, SCK_PIN, MOSI_PIN, DC_PIN, RST_PIN, BUSY_PIN, DISP_W, DISP_H, ptr_fb=0): s
' Start using custom I/O pins
'   CS_PIN:     chip select
'   SCK_PIN:    serial clock (may be labeled 'CLK')
'   MOSI_PIN:   master-out slave-in (may be labeled 'DIN')
'   DC_PIN:     data/command (sometimes called 'register select')
'   RST_PIN:    reset (optional)
'       (Specify something invalid to ignore (e.g., -1). You must then either connect it to
'       the display's supply voltage, or you could connect it to the Propeller's reset pin, which
'       will reset the display every time the Propeller is reset or program code is loaded)
'   BUSY_PIN:   display busy state
'   DISP_W:     display width, in pixels
'   DISP_H:     display height, in pixels
'   ptr_fb:     pointer to display/frame buffer (optional; default uses the internal framebuffer)

'   Returns: cog ID + 1 of the SPI engine
    if (    lookdown(CS_PIN: 0..31) and lookdown(SCK_PIN: 0..31) and ...
            lookdown(MOSI_PIN: 0..31) and lookdown(DC_PIN: 0..31) and ...
            lookdown(RST_PIN: 0..31) and lookdown(BUSY_PIN: 0..31) )
        if ( s := spi.init(SCK_PIN, MOSI_PIN, MOSI_PIN, core.SPI_MODE) )
            _CS := CS_PIN
            _DC := DC_PIN
            _RST := RST_PIN
            _BUSY := BUSY_PIN

            dira[_BUSY] := 0
            outa[_CS] := 1
            dira[_CS] := 1
            outa[_DC] := 0
            dira[_DC] := 1

            set_dims(DISP_W, DISP_H)
            set_address(ptr_fb)
            reset()
            return s
    ' if this point is reached, something above failed
    ' Double check I/O pin assignments, connections, power
    ' Lastly - make sure you have at least one free core/cog
    return FALSE


PUB stop()
' Stop SPI engine, float I/O pins, and clear variable space
    spi.deinit()
    dira[_CS] := 0
    dira[_DC] := 0
    dira[_BUSY] := 0
    longfill(@_ptr_drawbuffer, 0, 4)
    wordfill(@_buff_sz, 0, 2)
    bytefill(@_disp_width, 0, 4)


PUB defaults() | tmp
' Factory defaults
    reset()
    disp_lines(_disp_height)                    ' MUX
    gate_high_voltage(22_000)                   ' VGH
    gate_low_voltage(-20_000)                   ' VGL
    vsh1_voltage(15_000)                        ' VSH/VSL
    dummy_line_per(26)
    gate_line_width(62)

    tmp.byte[0] := $D7
    tmp.byte[1] := $D6
    tmp.byte[2] := $9D
    writereg(core.BOOST_CTRL, 3, @tmp)

    tmp := $A8
    writereg(core.WR_VCOM, 1, @tmp)

    'dataentrymode(%0_11)

    wr_lut(@_lut_e029a01_bw_full)

    repeat
    until disp_rdy()

    draw_area(0, 0, XMAX, YMAX)
    disp_pos(0, 0)


PUB preset_2p9_bw = preset_e029a01_bw
PUB preset_e029a01_bw()
' Presets for 2.9" BW E-ink panel, 128x296
'   (e.g., Parallax #28084, Waveshare #12563)
    reset()
    repeat
    until disp_rdy()

'    gatestartpos(0)
    disp_lines(296)
'    gatefirstchan(0)
'    interlaced(false)
'    mirrorv(false)
    addr_mode(HORIZ)
    addr_ctr_mode(YI_XI)

    draw_area(0, 0, 127, 295)

'    bordermode(HIZ)
'    bordervbdlev(BRD_VSS)
'    bordergstctrl(FLWLUT_VCOMRED)
'    bordergstrans(LUT0)

'    vcomvoltage(2_125)
'    gatevoltage(19_000)
'    vsh1voltage(15_000)
'    vsh2voltage(5_000)
'    vslvoltage(-15_000)

'    dummylineper(_lut_2p13_bw_full[74])
'    gatelinewidth(_lut_2p13_bw_full[75])
    wr_lut(@_lut_e029a01_bw_full)
'    disp_pos(0, 0)
    repeat
    until disp_rdy()


PUB addr_ctr_mode(md)
' Set address increment/decrement mode
'   md:
'       YD_XD (%00): Y-decrement, X-decrement
'       YD_XI (%01): Y-decrement, X-increment
'       YI_XD (%10): Y-increment, X-decrement
'      *YI_XI (%11): Y-increment, X-increment
'       other values ignored
    case md
        YD_XD, YD_XI, YI_XD, YI_XI:
            md := ((_data_entr_mode & core.ID_MASK) | md)
            if (md == _data_entr_mode)          ' no change to shadow reg;
                return                          ' don't bother writing
            else
                _data_entr_mode := md           ' update shadow reg
                writereg(core.DATA_ENT_MD, 1, @_data_entr_mode)


PUB addr_mode(md)
' Set display addressing mode
'   md:
'      *HORIZ (0)
'       VERT (1)
'       other values ignored
    case md
        HORIZ, VERT:
            md <<= core.AM
            md := ((_data_entr_mode & core.AM_MASK) | md)
            if (md == _data_entr_mode)          ' no change to shadow reg;
                return                          ' don't bother writing
            else
                _data_entr_mode := md           ' update shadow reg
                writereg(core.DATA_ENT_MD, 1, @_data_entr_mode)


#ifndef GFX_DIRECT
PUB clear()
' Clear the display buffer
    bytefill(_ptr_drawbuffer, _bgcolor, BUFF_SZ)
#endif


PUB draw_area(sx, sy, ex, ey) | tmpx, tmpy
' Set drawable display region for subsequent drawing operations
'   Valid values:
'       sx, ex: 0..127
'       sy, ey: 0..295
    tmpx.byte[0] := sx / 8
    tmpx.byte[1] := ex / 8

    tmpy.byte[0] := sy.byte[0]
    tmpy.byte[1] := sy.byte[1]
    tmpy.byte[2] := ey.byte[0]
    tmpy.byte[3] := ey.byte[1]

    writereg(core.RAM_X_WIND, 2, @tmpx)
    writereg(core.RAM_Y_WIND, 4, @tmpy)


PUB disp_lines(l)
' Set display visible lines
'   l:
'       1..296
'       other values ignored
    case l
        1..296:
            l -= 1
            if ( l == ( (_drv_out_ctrl[1] << 8) | _drv_out_ctrl[0]) )
                return
            else
                _drv_out_ctrl[0] := l.byte[0]
                _drv_out_ctrl[1] := l.byte[1]
                writereg(core.DRV_OUT_CTRL, 3, @_drv_out_ctrl)


PUB disp_pos(x, y) | tmp
' Set position for subsequent drawing operations
'   Valid values:
'       x: 0..127
'       y: 0..295
    writereg(core.RAM_X, 1, @x)
    writereg(core.RAM_Y, 2, @y)


PUB disp_rdy(): r
' Flag indicating display is ready to accept writeregs
'   Returns: TRUE (-1) if display is ready, FALSE (0) otherwise
    return (ina[_BUSY] == 0)


PUB disp_upd_ctrl2() | tmp

    tmp := $c7
    writereg(core.DISP_UP_CTRL2, 1, @tmp)


PUB dummy_line_per(p)
' Set dummy line period, in units TGate (1 TGate = line width in uSec)
'   p:
'       0..127
'       other values ignored
    case p
        0..127:
            writereg(core.DUMMY_LN_PER, 1, @p)


PUB gate_first_chan(ch)
' Set first output gate
'   ch:
'       0: G0 first channel; output sequence is G0, G1, G2, G3...
'       1: G1 first channel; output sequence is G1, G0, G3, G2...
'       other values ignored
    case ch
        0, 1:
            ch <<= core.GD
            ch := ((_drv_out_ctrl[2] & core.GD_MASK) | ch)
            if ( ch == _drv_out_ctrl[2] )
                return
            else
                _drv_out_ctrl[2] := ch
                writereg(core.DRV_OUT_CTRL, 3, @_drv_out_ctrl)


PUB gate_high_voltage(v)
' Set gate driving voltage (high level, VGH), in millivolts
'   v:
'       15_000..22_000 (default 22_000)
'       other values ignored
    case v
        15_000..22_000:
            v := ((v / 500) - 30) << core.VGH
            v := ((_gate_drv_volt & core.VGH_MASK) | v)
            if ( v == _gate_drv_volt )
                return
            else
                _gate_drv_volt  := v
                writereg(core.GATE_DRV_CTRL, 1, @v)


PUB gate_line_width(w)
' Set gate line width, in microseconds (figure TGate)
'   w:
'       30, 34, 38, 40, 44, 46, 52, 56, 62, 68, 78, 88, 104, 125, 156, 208
'       other values ignored
    case w
        30, 34, 38, 40, 44, 46, 52, 56, 62, 68, 78, 88, 104, 125, 156, 208:
            w := lookdownz(w: 30, 34, 38, 40, 44, 46, 52, 56, 62, 68, ...
                                    78, 88, 104, 125, 156, 208)
            writereg(core.GATE_LN_WD, 1, @w)


PUB gate_low_voltage(v)
' Set gate driving voltage (low level, VGL), in millivolts
'   v:
'       -20_000..-15_000 (default: -20_000)
'       other values ignored
    case v
        -20_000..-15_000:
            v := (abs(v) / 500) - 30
            v := ((_gate_drv_volt & core.VGL_MASK) | v)
            if ( v == _gate_drv_volt )
                return
            else
                _gate_drv_volt := v
                writereg(core.GATE_DRV_CTRL, 1, @v)


PUB gate_start_pos(row)

    writereg(core.GATE_ST_POS, 2, @row)


PUB interlace_ena(i): c
' Alternate direction of every other display line
'   i:
'       TRUE (-1 or 1), FALSE (0)
'       other values ignored
    case abs(i)
        0, 1:
            i := abs(i) << core.SM
            i := ((_drv_out_ctrl[2] & core.SM_MASK) | i)
            if (i == _drv_out_ctrl[2])
                return
            else
                _drv_out_ctrl[2] := i
                writereg(core.DRV_OUT_CTRL, 3, @_drv_out_ctrl)


PUB master_act()

    command(core.MASTER_ACT)


PUB mirror_v(m)  'XXX not functional yet
' Mirror display, vertically
'   m:
'       TRUE (-1 or 1), FALSE (0)
'       other values ignored
    case abs(m)
        0, 1:
            m := abs(m) << core.TB
            m := ((_drv_out_ctrl[2] & core.TB_MASK) | m)
            if (m == _drv_out_ctrl[2])
                return
            else
                _drv_out_ctrl[2] := m
                writereg(core.DRV_OUT_CTRL, 3, @_drv_out_ctrl)


PUB plot(x, y, c) | t, o, mask
' Plot pixel
'   x, y:   coordinates to draw
'   c:      pixel color
    if ( (x < 0) or (x > _disp_xmax) or (y < 0) or (y > _disp_ymax) )
        return                                  ' coords out of bounds, ignore

    case _rotation
        1:                                      ' 90deg CW
            t := x
            x := WIDTH - 1 - y
            y := t
        2:                                      ' 180deg
            x := WIDTH - x - 1
            y := HEIGHT - y - 1
        3:                                      ' 270deg
            t := x
            x := y
            y := HEIGHT-1-t

    o := _ptr_drawbuffer + ( (x / 8) + y * ((WIDTH + 7) / 8) )
    mask := $80 >> (x & 7)

    case c
        1:                                      ' white
            byte[o] |= mask
        0:                                      ' black
            byte[o] &= !mask
        -1:                                     ' inverse
            byte[o] ^= mask
        other:
            return


#ifndef GFX_DIRECT
PUB point(x, y): c | t
' Get color of pixel at x, y
    x := 0 #> x <# _disp_xmax
    y := 0 #> y <# _disp_ymax

    case _rotation
        1:                                      ' 90deg CW
            t := x
            x := WIDTH - 1 - y
            y := t
        2:                                      ' 180deg
            x := WIDTH - x - 1
            y := HEIGHT - y - 1
        3:                                      ' 270deg
            t := x
            x := y
            y := HEIGHT-1-t

    return byte[_ptr_drawbuffer][(x + y * _disp_width) >> 3]
#endif


PUB reset() | tmp
' Reset the display controller
    if (lookdown(_RST: 0..31))                  ' only touch the reset pin
        outa[_RST] := 0
        dira[_RST] := 1
        time.usleep(core.T_POR)
        outa[_RST] := 1
        time.usleep(core.T_POR)
    else                                        ' otherwise, just perform
        command(core.SWRESET)
        time.usleep(core.T_POR)

    repeat
    until disp_rdy()


PUB show() | tmp
' Send the draw buffer to the display
    draw_area(0, 0, XMAX, YMAX)
    disp_pos(0, 0)

    repeat
    until disp_rdy()

    writereg(core.WR_RAM_BW, _buff_sz, _ptr_drawbuffer)

    tmp := core.SEQ_CLK_CP_EN | core.SEQ_PATT_DISP
    writereg(core.DISP_UP_CTRL2, 1, @tmp)
    command(core.MASTER_ACT)
    command(core.NOOP)

    repeat
    until disp_rdy()


PUB vsh1_voltage(v)
' Set source drive (VSH/VSL) level, in millivolts
'   v:
'       10_000..17_000
'       other values ignored
    case v
        10_000..17_000:
            v := (v / 500) - 20
            writereg(core.SRC_DRV_CTRL, 1, @v)


PUB wr_lut(p_lut)
' Write display-specific pixel waveform LookUp Table
    writereg(core.WR_LUT, 30, p_lut)


CON

    CMD     = 0
    DATA    = 1


PRI command(c)
' Issue command without parameters to display
    outa[_DC] := CMD
    outa[_CS] := 0
    spi.wr_byte(c)
    outa[_CS] := 1


#ifndef GFX_DIRECT
PRI memfill(xs, ys, val, count)
' Fill region of display buffer memory
'   xs, ys: Start of region
'   val: Color
'   count: Number of consecutive memory locations to write
    bytefill(_ptr_drawbuffer + (xs + (ys * _bytesperln)), val, count)
#endif


PRI writereg(c, len, p_src)
' Write value to register/issue command
    outa[_CS] := 0
    outa[_DC] := CMD                            ' D/C low = command
    spi.wr_byte(c)                              ' write command
    outa[_DC] := DATA                           ' D/C high = data
    spi.wrblock_lsbf(p_src, len)                ' write parameters or data
    outa[_CS] := 1


DAT

    ' 2.9in E029A01, BW, full update
    _lut_e029a01_bw_full    byte    $02, $02, $01, $11, $12, $12, $22, $22, $66, $69
                            byte    $69, $59, $58, $99, $99, $88, $00, $00, $00, $00
                            byte    $F8, $B4, $13, $51, $35, $51, $51, $19, $01, $00


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


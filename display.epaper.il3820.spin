{
----------------------------------------------------------------------------------------------------
    Filename:       display.epaper.il3820.spin
    Description:    Driver for the IL3820 electrophoretic display controller
    Author:         Jesse Burt
    Started:        Nov 30, 2019
    Updated:        Oct 24, 2024
    Copyright (c) 2024 - See end of file for terms of use.
----------------------------------------------------------------------------------------------------
}

#define 1BPP
#define MEMMV_NATIVE bytemove
#include "graphics.common.spinh"
#ifdef GFX_DIRECT
#   error "GFX_DIRECT not supported by this driver"
#endif

CON

    { -- default I/O settings; these can be overridden in the parent object }
    { display dimensions }
    WIDTH           = 128
    HEIGHT          = 296

    { SPI }
    CS              = 0
    SCK             = 1
    MOSI            = 2
    DC              = 3
    RST             = 4
    BUSY            = 5
    ' --

    XMAX            = WIDTH-1
    YMAX            = HEIGHT-1
    CENTERX         = WIDTH/2
    CENTERY         = HEIGHT/2
    BYTESPERLN      = WIDTH * BYTESPERPX
    BUFF_SZ         = ((WIDTH * HEIGHT) * BYTESPERPX) / 8


' Colors
    BLACK           = 0
    WHITE           = $FF
    INVERT          = -1

    MAX_COLOR       = 1
    BYTESPERPX      = 1

    MSB             = 1
    LSB             = 0

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
    core:   "core.con.il3820"
    time:   "time"


PUB null()
' This is not a top-level object


PUB start(): status
' Start using default I/O settings
    return startx(CS, SCK, MOSI, DC, RST, BUSY, WIDTH, HEIGHT, @_framebuffer)


PUB startx(CS_PIN, SCK_PIN, MOSI_PIN, DC_PIN, RST_PIN, BUSY_PIN, DISP_W, DISP_H, ptr_fb): status
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
'   ptr_fb:     pointer to display/frame buffer

'   Returns: cog ID + 1 of the SPI engine
    if (    lookdown(CS_PIN: 0..31) and lookdown(SCK_PIN: 0..31) and ...
            lookdown(MOSI_PIN: 0..31) and lookdown(DC_PIN: 0..31) and ...
            lookdown(RST_PIN: 0..31) and lookdown(BUSY_PIN: 0..31) )
        if ( status := spi.init(SCK_PIN, MOSI_PIN, MOSI_PIN, core.SPI_MODE) )
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
            _buff_sz := _disp_width * ((_disp_height + 7) / 8)
            set_address(ptr_fb)
            reset()
            return status
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

    wr_lut(@_lut_2p9_bw_full)

    repeat until disp_rdy()

    draw_area(0, 0, _disp_width-1, _disp_height-1)
    disp_pos(0, 0)


PUB preset_2p9_bw = preset_e029a01_bw
PUB preset_e029a01_bw()
' Presets for 2.9" BW E-ink panel, 128x296
'   (e.g., Parallax #28084, Waveshare #12563)
    reset()
    repeat until disp_rdy()

    analog_blk_ctrl()
    dig_blk_ctrl()
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
    wr_lut(@_lut_2p9_bw_full)
'    disp_pos(0, 0)
    repeat until disp_rdy()


PUB addr_ctr_mode(mode): curr_mode
' Set address increment/decrement mode
'   Valid values:
'       YD_XD (%00): Y-decrement, X-decrement
'       YD_XI (%01): Y-decrement, X-increment
'       YI_XD (%10): Y-increment, X-decrement
'      *YI_XI (%11): Y-increment, X-increment
'   Any other value returns the current (cached) setting
    curr_mode := _data_entr_mode
    case mode
        YD_XD, YD_XI, YI_XD, YI_XI:
            mode := ((curr_mode & core.ID_MASK) | mode)
            if (mode == curr_mode)              ' no change to shadow reg;
                return                          ' don't bother writing
            else
                _data_entr_mode := mode
                writereg(core.DATA_ENT_MD, 1, @_data_entr_mode)
        other:
            return (curr_mode & core.ID_BITS)


PUB addr_mode(mode): curr_mode
' Set display addressing mode
'   Valid values:
'      *HORIZ (0)
'       VERT (1)
'   Any other value returns the current (cached) setting
    curr_mode := _data_entr_mode
    case mode
        HORIZ, VERT:
            mode <<= core.AM
            mode := ((curr_mode & core.AM_MASK) | mode)
            if (mode == curr_mode)                      ' no change to shadow reg;
                return                                  ' don't bother writing
            else
                _data_entr_mode := mode
                writereg(core.DATA_ENT_MD, 1, @_data_entr_mode)
        other:
            return ((curr_mode >> core.AM) & 1)


PUB analog_blk_ctrl() | tmp
' Analog Block control
    tmp := $54
    writereg(core.ANLG_BLK_CTRL, 1, @tmp)


#ifndef GFX_DIRECT
PUB clear()
' Clear the display buffer
    bytefill(_ptr_drawbuffer, _bgcolor, _buff_sz)
#endif


PUB dig_blk_ctrl() | tmp
' Digital Block control
    tmp := $3b
    writereg(core.DIGI_BLK_CTRL, 1, @tmp)


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


PUB disp_lines(lines): curr_lines
' Set display visible lines
'   Valid values: 1..296
'   Any other value returns the current (cached) setting
    curr_lines.byte[0] := _drv_out_ctrl[0]
    curr_lines.byte[1] := _drv_out_ctrl[1]
    case lines
        1..296:
            lines -= 1
            if (lines == curr_lines)                    ' no change to shadow reg;
                return                                  ' don't bother writing
            else
                _drv_out_ctrl[0] := lines.byte[0]
                _drv_out_ctrl[1] := lines.byte[1]
                writereg(core.DRV_OUT_CTRL, 3, @_drv_out_ctrl)
        other:
            return (curr_lines + 1)


PUB disp_pos(x, y) | tmp
' Set position for subsequent drawing operations
'   Valid values:
'       x: 0..127
'       y: 0..295
    writereg(core.RAM_X, 1, @x)
    writereg(core.RAM_Y, 2, @y)


PUB disp_rdy(): flag
' Flag indicating display is ready to accept commands
'   Returns: TRUE (-1) if display is ready, FALSE (0) otherwise
    return (ina[_BUSY] == 0)


PUB disp_upd_ctrl2() | tmp

    tmp := $c7
    writereg(core.DISP_UP_CTRL2, 1, @tmp)


PUB dummy_line_per(period)
' Set dummy line period, in units TGate (1 TGate = line width in uSec)
'   Valid values: 0..127
'   Any other value is ignored
    case period
        0..127:
            writereg(core.DUMMY_LN_PER, 1, @period)
        other:
            return


PUB gate_first_chan(ch): curr_ch
' Set first output gate
'   Valid values:
'       0: G0 first channel; output sequence is G0, G1, G2, G3...
'       1: G1 first channel; output sequence is G1, G0, G3, G2...
'   Any other value returns the current (cached) setting
    curr_ch := _drv_out_ctrl[2]
    case ch
        0, 1:
            ch <<= core.GD
            ch := ((curr_ch & core.GD_MASK) | ch)
            if (ch == curr_ch)
                return
            else
                _drv_out_ctrl[2] := ch
                writereg(core.DRV_OUT_CTRL, 3, @_drv_out_ctrl)
        other:
            return ((curr_ch >> core.GD) & 1)


PUB gate_high_voltage(lvl): curr_lvl
' Set gate driving voltage (high level, VGH), in millivolts
'   Valid values: 15_000..22_000 (default 22_000)
'   Any other value returns the current setting
    curr_lvl := _gate_drv_volt
    case lvl
        15_000..22_000:
            lvl := ((lvl / 500) - 30) << core.VGH
            lvl := ((curr_lvl & core.VGH_MASK) | lvl)
            _gate_drv_volt  := lvl
            writereg(core.GATE_DRV_CTRL, 1, @_gate_drv_volt)
        other:
            curr_lvl := (curr_lvl >> core.VGH) & core.VGH_BITS
            return ((curr_lvl + 30) * 500)


PUB gate_line_width(usec)
' Set gate line width, in microseconds (figure TGate)
'   Valid values: 30, 34, 38, 40, 44, 46, 52, 56, 62, 68, 78, 88, 104, 125, 156, 208
'   Any other value is ignored
    case usec
        30, 34, 38, 40, 44, 46, 52, 56, 62, 68, 78, 88, 104, 125, 156, 208:
            usec := lookdownz(usec: 30, 34, 38, 40, 44, 46, 52, 56, 62, 68, ...
                                    78, 88, 104, 125, 156, 208)
            writereg(core.GATE_LN_WD, 1, @usec)
        other:
            return


PUB gate_low_voltage(voltage): curr_vlt
' Set gate driving voltage (low level, VGL), in millivolts
'   Valid values: -20_000..-15_000 (default: -20_000)
'   Any other value returns the current setting
    curr_vlt := _gate_drv_volt
    case voltage
        -20_000..-15_000:
            voltage := (||(voltage) / 500) - 30
            voltage := ((curr_vlt & core.VGL_MASK) | voltage)
            _gate_drv_volt := voltage
            writereg(core.GATE_DRV_CTRL, 1, @_gate_drv_volt)
        other:
            curr_vlt &= core.VGL_BITS
            return ((curr_vlt + 30) * 500) * -1


PUB gate_start_pos(row)

    writereg(core.GATE_ST_POS, 2, @row)


PUB interlace_ena(state): curr_state
' Alternate direction of every other display line
'   Valid values: TRUE (-1 or 1), FALSE (0)
'   Any other value returns the current (cached) setting
    curr_state := _drv_out_ctrl[2]
    case ||(state)
        0, 1:
            state := ||(state) << core.SM
            state := ((curr_state & core.SM_MASK) | state)
            if (state == curr_state)
                return
            else
                _drv_out_ctrl[2] := state
                writereg(core.DRV_OUT_CTRL, 3, @_drv_out_ctrl)
        other:
            return (((curr_state >> core.SM) & 1) == 1)


PUB master_act()

    command(core.MASTER_ACT)


PUB mirror_v(state): curr_state  'XXX not functional yet
' Mirror display, vertically
'   Valid values: TRUE (-1 or 1), FALSE (0)
'   Any other value returns the current (cached) setting
    curr_state := _drv_out_ctrl[2]
    case ||(state)
        0, 1:
            state := ||(state) << core.TB
            state := ((curr_state & core.TB_MASK) | state)
            if (state == curr_state)
                return
            else
                _drv_out_ctrl[2] := state
                writereg(core.DRV_OUT_CTRL, 3, @_drv_out_ctrl)
        other:
            return (((curr_state >> core.TB) & 1) == 1)


PUB plot(x, y, color)
' Plot pixel at (x, y) in color
    if ( (x < 0) or (x > _disp_xmax) or (y < 0) or (y > _disp_ymax) )
        return                                  ' coords out of bounds, ignore
#ifdef GFX_DIRECT
' direct to display
'   (not implemented)
#else
' buffered display
    case color
        1:
            byte[_ptr_drawbuffer][(x + y * _disp_width) >> 3] |= $80 >> (x & 7)
        0:
            byte[_ptr_drawbuffer][(x + y * _disp_width) >> 3] &= !($80 >> (x & 7))
        -1:
            byte[_ptr_drawbuffer][(x + y * _disp_width) >> 3] ^= $80 >> (x & 7)
        other:
            return
#endif


#ifndef GFX_DIRECT
PUB point(x, y): pix_clr
' Get color of pixel at x, y
    x := 0 #> x <# _disp_xmax
    y := 0 #> y <# _disp_ymax

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
    repeat until disp_rdy()


PUB show() | tmp
' Send the draw buffer to the display
    draw_area(0, 0, _disp_width-1, _disp_height-1)
    disp_pos(0, 0)

    repeat until disp_rdy()

    writereg(core.WR_RAM_BW, _buff_sz, _ptr_drawbuffer)

    tmp := core.SEQ_CLK_CP_EN | core.SEQ_PATT_DISP
    writereg(core.DISP_UP_CTRL2, 1, @tmp)
    command(core.MASTER_ACT)
    command(core.NOOP)

    repeat until disp_rdy()


PUB vsh1_voltage(voltage)
' Set source drive (VSH/VSL) level, in millivolts
'   Valid values: 10_000..17_000
'   Any other value is ignored
    case voltage
        10_000..17_000:
            voltage := (voltage / 500) - 20
            writereg(core.SRC_DRV_CTRL, 1, @voltage)
        other:
            return


PUB wr_lut(ptr_lut)
' Write display-specific pixel waveform LookUp Table
    writereg(core.WR_LUT, 30, ptr_lut)


CON

    CMD     = 0
    DATA    = 1

PRI command(c)
' Issue command without parameters to display
    case c
        core.SWRESET, core.MASTER_ACT, core.NOOP:
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


PRI writereg(reg_nr, nr_bytes, ptr_buff)
' Write nr_bytes from ptr_buff to device
    case reg_nr
        $01, $03, $04, $0C, $10, $11, $1A, $21, $22, $24, $2C, $32, $3A..$3C, $44, $45, $4E, $4F:
            { commands with parameters }
            outa[_CS] := 0
            outa[_DC] := CMD                    ' D/C low = command
            spi.wr_byte(reg_nr)
            outa[_DC] := DATA                   ' D/C high = data
            spi.wrblock_lsbf(ptr_buff, nr_bytes)
            outa[_CS] := 1
        other:
            return


DAT

    _lut_2p9_bw_full    byte    $02, $02, $01, $11, $12, $12, $22, $22, $66, $69
                        byte    $69, $59, $58, $99, $99, $88, $00, $00, $00, $00
                        byte    $F8, $B4, $13, $51, $35, $51, $51, $19, $01, $00


DAT
{
Copyright 2024 Jesse Burt

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


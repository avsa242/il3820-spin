{
    --------------------------------------------
    Filename: core.con.il3820.spin
    Author:
    Description:
    Copyright (c) 2019
    Started Nov 30, 2019
    Updated Nov 30, 2019
    See end of file for terms of use.
    --------------------------------------------
}

CON

' SPI Configuration
    SCK_CPOL                    = 0
    CLK_DELAY                   = 10             ' Max is 4MHz
    MOSI_BITORDER               = 5             'MSBFIRST

' Register definitions
    DRIVER_OUT_CTRL             = $01
    BOOSTER_SOFTST_CTRL         = $0C
    DEEP_SLEEP                  = $10
    DATA_ENTRY_MODE             = $11
    SWRESET                     = $12
    TEMPERATURE_CTRL            = $1A
    MASTER_ACT                  = $20
    DISP_UPDATE_CTRL1           = $21
    DISP_UPDATE_CTRL2           = $22
        SEQ_ALL                 = $FF
        SEQ_CLKEN               = $80
        SEQ_CLK_CP_EN           = $C0
        SEQ_INITIAL_PATTERN_DISP= $0C
        SEQ_INITIAL_DISP        = $08
        SEQ_PATTERN_DISP        = $04
        SEQ_CLK_CP_DIS          = $03
        SEQ_CLK_DIS             = $01

    WRITE_RAM                   = $24
    WRITE_VCOM_REG              = $2C
    WRITE_LUT_REG               = $32
    DUMMY_LINE_PER              = $3A
    GATE_LINE_WIDTH             = $3B
    BORDER_WAVEFM_CTRL          = $3C
    RAM_X_ADDR                  = $44
    RAM_Y_ADDR                  = $45
    RAM_X_ADDR_AC               = $4E
    RAM_Y_ADDR_AC               = $4F
    NOOP                        = $FF

PUB Null
' This is not a top-level object

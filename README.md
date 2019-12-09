# il3820-spin 
-------------

This is a P8X32A/Propeller driver object for the IL3820 electrophoretic (E-Ink, E-Paper) display controller

## Salient Features

* SPI connection at up to 1MHz
* Integration with generic bitmap graphics library

## Requirements

* P1/SPIN1: 1 extra core/cog for the PASM I2C driver

## Compiler Compatibility

* P1/SPIN1: OpenSpin (tested with 1.00.81)

## Limitations

* Very early in development - may malfunction, or outright fail to build
* Most initialization and setup code for the display is currently hardcoded

## TODO


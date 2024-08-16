# il3820-spin 
-------------

This is a P8X32A/Propeller driver object for the IL3820 electrophoretic (E-Ink, E-Paper) display controller

**IMPORTANT**: This software is meant to be used with the [spin-standard-library](https://github.com/avsa242/spin-standard-library) (P8X32A) or [p2-spin-standard-library](https://github.com/avsa242/p2-spin-standard-library) (P2X8C4M64P). Please install the applicable library first before attempting to use this code, otherwise you will be missing several files required to build the project.

## Salient Features

* SPI connection at up to 1MHz (P1), ~4MHz (P2)
* Integration with generic bitmap graphics library


## Requirements

P1/SPIN1:
* spin-standard-library
* P1/SPIN1: 1 extra core/cog for the PASM I2C engine
* graphics.common.spinh (provided by spin-standard-library)
* `(WIDTH * HEIGHT) / 8` bytes of RAM for the display buffer (internal to the driver)

P2/SPIN2:
* p2-spin-standard-library
* graphics.common.spin2h (provided by p2-spin-standard-library)
* `(WIDTH * HEIGHT) / 8` bytes of RAM for the display buffer (internal to the driver)


## Compiler Compatibility

| Processor | Language | Compiler               | Backend      | Status                |
|-----------|----------|------------------------|--------------|-----------------------|
| P1        | SPIN1    | FlexSpin (6.9.4)       | Bytecode     | OK                    |
| P1        | SPIN1    | FlexSpin (6.9.4)       | Native/PASM  | OK                    |
| P2        | SPIN2    | FlexSpin (6.9.4)       | NuCode       | OK (Untested)         |
| P2        | SPIN2    | FlexSpin (6.9.4)       | Native/PASM2 | OK                    |

(other versions or toolchains not listed are __not supported__, and _may or may not_ work)


## Hardware compatibility

* Tested with Parallax #28084 (Waveshare #12563), 2.9" BW panel


## Limitations

* Very early in development - may malfunction, or outright fail to build
* No rotation support (planned)
* No horizontal mirroring support (planned)


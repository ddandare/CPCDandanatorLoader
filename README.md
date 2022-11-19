# CPCDandanatorLoader
Z80 assembly code of the CPC Dandanator USB Romset Loader

This is the Z80 assembly code for the CPC Dandanator Romset Loader.\
This code has been developed by Dandare and mad3001.\
Information on the CPC Dandanator may be found on http://www.dandare.es \
This software communicate with the Romset Creator Java Tool through USB-Serial. \
The Java Romset Creator Tool has been developed by overCLK and the repository is here: https://github.com/teiram/dandanator-cpc

Use SJASMPLUS https://github.com/z00m128/sjasmplus to compile the software. \
  - The main program is eewriter_cpc_v3.asm
  - A demo launcher for the program is also present: demo_launch_loader.asm. Load it @ 0x4000 and set the PC to run from that address

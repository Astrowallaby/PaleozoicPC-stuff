# Paleozoic PC Stuff

Random retrocomputing things brought to you by the loser
who runs the Paleozoic PCs channel on Youtube.

[Link](https://www.youtube.com/channel/UC8DxqCcs3MqUyXdEJHCd9vg)

So what's here?

## VGAFUDGE.EXE

### Fixes VGA detection issues in Tandy 1000s upgraded with VGA cards.

This program performs the same function as the "VGAFIX" sofware that can be
found in the Oldskool Tandy 1000 archive, IE, it simply modifies a few bytes
in the BIOS data area that Tandy doesn't update correctly to indicate that
a VGA card is installed. Without this fix some software that attempts to
automatically determine what kind of card is installed will fail.

Where this differs from VGAFIX is the earlier software is designed to run
from the command line after boot, or from AUTOEXEC.BAT. The problem I found is
there are some device drivers (the specific one I ran into is ANSI.SYS, but it
may also affect other things such as mouse drivers loaded from config.sys) that
likewise fail to configure themselves correctly. Using some clever tricks I
can't take credit for VGAFUDGE can be run either from the normal command line
or configured as a device driver in config.sys.

When run as a device driver no code remains resident, it simply runs and exits.
Simply place a DEVICE statement in config.sys before any drivers that may care
about video card type.

Code was formatted for and compiled with MASM 6.0 on MS/PC-DOS. Note that
VGAFUDGE is only set up to fix the data area for a color monitor. If
you actually have a VGA mono monitor you can reference the source code for
VGAFIX to compile a modified version. (Simply change the byte poked into the
BIOS data area appropriately.) My assumption was that no one actually
has a working mono VGA monitor anymore which they care about using on a
Tandy 1000.

This software may also be useful on other machines; it appears, for instance,
that the AT&T 6300 may also not set up the BIOS area correctly when fitted
with a VGA card.

## EMS2UMB.EXE

### Zero-resident enabler to use a Lo-Tech 2MB or compatible EMS card as 64k of upper memory.

Recently I built an expansion card for the Tandy 1000EX and 1000HX computers that
incorporates an EMS memory expansion that's register-compatible with the Lo-Tech
2MB EMS board:

[Link to Lo-Tech's Wiki](https://www.lo-tech.co.uk/wiki/Lo-tech_2MB_EMS_Board)

There are other clones/compatible versions of this board available from various sources.
Although sold as an "EMS/LIM 4.0" board the hardware of this device is limited solely to
manipulating 16k pages within a 64k page frame, it is not capable of "mapping" or backfilling
memory to other regions. This means the hardware is mostly only suitable for programs which
specifically use EMS memory for data, not for providing upper memory to load DOS and drivers "high".

Despite this there are times where it may be worth sacrificing EMS in order to gain space to free
conventional memory under the 640k mark. Memory managers like QRAM can convert the EMS page
frame into 64k of upper memory space, but this does require loading the device driver for the
memory card, which trades off a small amount of resident overhead. What this program does
instead is, when called from config.sys, stuff static values into the EMS page registers to
ensure the spaces are filled with unique pages of memory, then exits, leaving nothing resident.

This program is hard-coded to expect the EMS board at its default I/O location at 0x260h. If that
has been changed the program will need to be recompiled. It also does not care about the page frame
location, nor does it do a memory test. Make sure your card works with the normal driver.
The program directory includes a sample config.sys that shows how to switch between EMS and extra UMB space on boot for DOS
versions that support config.sys menus.

Code compiled with MASM 6.0 on MS/PC-DOS. This code uses the same skeleton as VGAFUDGE that
allows it to run from either the command line or config.sys; running from command-line may 
be useful for testing the RAM or making it available for static temporary loading of
bios extensions/cartridge images/whatever? (Memory should survive a warm reboot if not cleared by another process.)


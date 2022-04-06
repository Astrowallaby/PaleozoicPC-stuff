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

## RTL2UMB.EXE

### Zero-resident enabler to use memory on an RTL8019AS-based ethernet card as upper memory.

Contributed by Davide Bresolin.

The RTL8019AS ethernet ASIC includes support for writeable flash/eeprom memory devices in the boot ROM socket.
The signal to flash these devices is the same MEMW signal that RAM uses, so assuming the MEMW signal is
actually connected to the socket (this may vary depending on the PCB board used on your particular card)
this means it's possible to use a RAM chip in this socket as an upper memory block. However, there is
one catch: the setting to enable the ROM socket chip select is not "persistant"; it's not set based on
the configuration EEPROM contents, it needs to be specifically set "on", presumably by the program
used to flash new contents. Therefore you simply can't "set and forget it" for use as upper memory.

The RTL2UMB program uses the same "run from config.sys" EXE framework as the above to allow it to be loaded
from config.sys before a UMB provider program such as USE!UMBS.SYS. During execution the program stuffs
the necessary registers on the card to enable writes and exits. The program has been tested with a card
modified to "free" the MEMR and MEMW signals so they were connected to the bus signals instead of tied low
and up respectively, and works to provide a 64K upper memory block mapped according to the RTL's configuration
settings for the ROM socket base.

A possible limitation of this modification is DMA may not be supported to this RAM. This could cause
problems with floppy I/O if the DOS data area is loaded high. Per a discussion thread:

"I realized that moving the dos data segment in the UMB causes problem with floppy disks. DIR A: gets you garbage
and lots of disk fail errors. This happens with both DOSDATA=UMB (and no dosmax) and DOSMAX (and no dosdata), with
PC DOS 2000 and MS DOS 5 with a minimal configuration (floppy only, no hd nor XTIDE bios)... 

To have a working setup I must add /S+ to DOSMAX.SYS to keep the dos data segment in low memory and load only
the kernel high. This decreased free conventional to 619K, or 615K with the packet driver and etherdrv."

The RTL card only controls chip select to the ROM socket, not the MEMR/MEMW signals, so presumably the issue 
is the RTL gates itself on the AEN signal; this is common for port mapped devices but semi-erroneous to do
for memory devices.

It's unknown if this driver will work on other 8019 variants, it's only been tested on the 8019AS.

## DACPOUND.EXE

### Test your VGA card for "Palette Snow"

Some people have noticed "snow" in the form of dark/light/colored artifacts appearing on the
screen when running their favorite VGA games on original hardware. The most likely cause of
these affects is "DAC Snow", which is the result of hardware contention between the video
output circuitry and the CPU when the palette register contents are updated. (Palette cycling
is commonly employed in VGA games to perform fade transitions or provide simple pseudo-animation
effects.)

Not all DACs are prone to this, most newer cards employ DACs with "dual-ported" memory
that can be accessed and updated at the same time, but on older DACs there can be moments where
the output circuitry is blocked from accessing the memory as the CPU writes it, resulting in
a small dot or dash on the screen. Also, some programs only access the DAC during the vertical
refresh period between frames to avoid this problems, so snow may not be apparent even if
the card is prone to it. But if you've noticed these sort of artifacts when running *certain*
games this program may help you verify that there isn't a bigger problem with your system's
hardware or software.

DACPOUND sets up a simple color bar display and drops into a tight loop rolling
the palette registers corresponding to a set of grayscale bars near the middle of the screen.
Video memory is completely untouched during this display, the only thing being exercised
is the I/O mapped palette registers. Run the program and visually observe if any "snow" is
generated; if the only activity visible is the cycling gray bars then your DAC is immune, while
random artifacts appearing in the portions of the screen that should be stable indicate
your DAC isn't dual ported. (Which may be good news, it means your VGA card is otherwise OK.
DAC snow is completely normal for older cards.) Hit ESC to exit.

This program was written in Microsoft QBasic/QuickBasic, and the .EXE file was compiled with
QuickBasic 4.5. The interpreted .BAS file may be too slow to generate significant snow
unless you have a quite fast computer, but the compiled version generates copius snow
even on a 4.77mhz XT-class machine.

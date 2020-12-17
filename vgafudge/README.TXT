VGAFUDGE.EXE: A simple hack to fix VGA detection issues on Tandy 1000 and other ancient PCs

This program is only does one thing: when run it pokes a couple bytes into the DOS BIOS data area
into the location where programs that attempt to autodetect what type of video card is installed
to ensure that it returns the value expected for a machine fitted with a VGA card and color monitor.

The reason this exists is older Tandy 1000 models that "support" being upgraded to VGA cards to not
properly set this memory location. DOS programs that are specifically configured for the desired
video mode will usually work regardless of this problem, but some programs and drivers that
attempt to suss out themselves what video type is installed will guess incorrectly. This problem
is explained in more detail in the documentation for "VGAFIX", which is available from the Oldskool
Tandy 1000 archive here:

http://www.oldskool.org/guides/tvdog/utilities.html

VGAFUDGE does exactly the same thing as VGAFIX, IE, simply poking a couple bytes into the proper
place in memory; running "VGAFUDGE" at the DOS command line should result in exactly the same
changes as running "vgafixc.com". Where VGAFUDGE differs is it may also be called from
config.sys. Adding:

DEVICE=VGAFUDGE.EXE

Will cause VGAFIX to be loaded as if it were a device driver, upon which it will poke the corrected
BDA data into place and exit, consuming zero resident memory. This allows it to correct issues
with device drivers that mis-detect VGA, unlike VGAFIX. A known example of this is ANSI.SYS; without
VGAFUDGE ANSI.SYS will not allow you to use the MODE command to set the 43 and 50 line display modes
because VGA isn't detected at load time. Some mouse drivers also change their behavior if EGA or
VGA is present, running VGAFUDGE from config.sys will also correct this problem.

For this to work properly make sure that VGAFUDGE appears near the beginning of config.sys, before
any drivers that might care about video card detection, IE:

DEVICE=C:\DOS\VGAFUDGE.EXE
REM ... (other directives) ...
DEVICE=C:\DOS\ANSI.SYS
REM or DEVICEHIGH=C:\DOS\ANSI.SYS

Because VGAFUDGE.EXE leaves nothing resident it's not necessary to use "DEVICEHIGH".

#!/usr/bin/env python3
"""Render an original 14-second soundscape with FFmpeg. No downloaded samples."""
from pathlib import Path
import subprocess

root = Path(__file__).resolve().parent.parent
# Soft D/A ambient bed, gently detuned rather than a loud musical theme.
voices = [f'0.011*sin(2*PI*{f}*t+0.18*sin(2*PI*0.13*t))' for f in (73.416, 110, 146.832, 220.12)]
# Tonal swells aligned with logo assembly, title reveal and workspace arrival.
for at, length, freq, gain in [(0.1, 1.8, 64, .055), (1.2, 2.0, 145, .035), (4.2, 1.1, 210, .04), (6.45, .8, 90, .05)]:
    x = f'(t-{at})'
    voices.append(f'if(between(t,{at},{at+length}),{gain}*sin(PI*{x}/{length})^2*sin(2*PI*({freq}*{x}+90*{x}^2)),0)')
# Five small, rounded interface accents, each with a two-note harmonic tail.
for i, at in enumerate((7.7, 8.25, 8.8, 9.35, 9.9)):
    x = f'(t-{at})'; f = (587.33, 659.25, 880, 739.99, 1174.66)[i]
    voices.append(f'if(between(t,{at},{at+.32}),.045*(1-exp(-110*{x}))*exp(-17*{x})*(sin(2*PI*{f}*{x})+.25*sin(2*PI*{f*2}*{x})),0)')
# A restrained resolving chord for the ready screen, then a short descending close.
for f in (293.665, 440, 587.33):
    x = '(t-12.15)'
    voices.append(f'if(gte(t,12.15),.018*(1-exp(-18*{x}))*exp(-2.2*{x})*sin(2*PI*{f}*{x}),0)')
x = '(t-13.45)'
voices.append(f'if(between(t,13.45,13.95),.035*sin(PI*{x}/.5)^2*sin(2*PI*(650*{x}-480*{x}^2)),0)')
tone = '+'.join(voices)
# Airy noise swells rather than hard impacts or alarms.
swells = '+'.join(f'if(between(t,{at},{at+d}),{gain}*sin(PI*(t-{at})/{d})^2,0)' for at,d,gain in ((0,1.8,.17),(2.0,1.5,.055),(4.2,1.0,.09),(6.4,1.0,.12),(13.45,.5,.10)))
output = root / 'Preview' / 'soundtrack.m4a'
subprocess.run(['ffmpeg','-hide_banner','-loglevel','error','-y',
 '-f','lavfi','-i',f"aevalsrc='{tone}':s=48000:d=14",
 '-f','lavfi','-i','anoisesrc=color=white:amplitude=1:sample_rate=48000:duration=14:seed=723',
 '-filter_complex',f'[0:a]aecho=0.8:0.5:71|139:0.15|0.08[tone];[1:a]highpass=f=1100,lowpass=f=6500,volume=\'{swells}\':eval=frame[air];[tone][air]amix=inputs=2:normalize=0,afade=t=in:d=0.12,afade=t=out:st=13.65:d=0.35,loudnorm=I=-23:TP=-5:LRA=6,aformat=sample_rates=48000:channel_layouts=stereo,atrim=duration=14[out]',
 '-map','[out]','-c:a','aac','-b:a','160k','-movflags','+faststart',str(output)],check=True)
print(output)

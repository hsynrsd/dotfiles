#!/usr/bin/env python3
"""Synthesize the 'Steel' sound theme: soft, short, glassy FM chimes.
Writes WAVs; build.sh converts them to .oga into ~/.local/share/sounds/steel."""
import math, struct, wave, os, sys
SR = 48000
OUT = sys.argv[1]
os.makedirs(OUT, exist_ok=True)

D5, E5, Fs5, A5, B5, D6, A4, Fs4, D4 = 587.3, 659.3, 740.0, 880.0, 987.8, 1174.7, 440.0, 370.0, 293.7

def bell(freq, dur=0.9, amp=1.0, ratio=3.5, index=1.6, decay=5.0):
    """Glassy FM bell: metallic partials that fade quickly to a pure tone."""
    n = int(SR * dur); out = []
    for i in range(n):
        t = i / SR
        env = (1 - math.exp(-t * 400)) * math.exp(-t * decay)
        mod = index * math.exp(-t * 9) * math.sin(2 * math.pi * freq * ratio * t)
        s = math.sin(2 * math.pi * freq * t + mod)
        s += 0.25 * math.sin(2 * math.pi * freq * 2.01 * t) * math.exp(-t * decay * 1.8)
        out.append(amp * env * s)
    return out

def tick(freq=1500, dur=0.04, amp=0.5):
    n = int(SR * dur)
    return [amp * math.exp(-i / SR * 120) * math.sin(2 * math.pi * freq * i / SR) for i in range(n)]

def mix(parts, total):
    """parts: list of (start_seconds, samples)."""
    buf = [0.0] * int(SR * total)
    for start, smp in parts:
        o = int(start * SR)
        for i, v in enumerate(smp):
            if o + i < len(buf): buf[o + i] += v
    return buf

def save(name, buf, peak_db=-16):
    m = max(abs(v) for v in buf) or 1
    g = 10 ** (peak_db / 20) / m
    with wave.open(f"{OUT}/{name}.wav", "wb") as w:
        w.setnchannels(2); w.setsampwidth(2); w.setframerate(SR)
        d = int(SR * 0.012)  # tiny right-channel delay for width
        frames = bytearray()
        for i, v in enumerate(buf):
            r = buf[i - d] if i >= d else 0
            frames += struct.pack("<hh", int(v * g * 32767), int((0.85 * v + 0.15 * r) * g * 32767))
        w.writeframes(bytes(frames))

def arp(notes, gap, dur=1.0, total=None, **kw):
    total = total or gap * len(notes) + dur
    return mix([(i * gap, bell(f, dur, **kw)) for i, f in enumerate(notes)], total)

save("desktop-login",        arp([A4, D5, Fs5, A5], 0.13, 1.4, decay=3.2), -14)
save("desktop-logout",       arp([A5, Fs5, D5, A4], 0.13, 1.2, decay=3.5), -15)
save("message-new-instant",  arp([E5, A5], 0.085, 0.7), -16)
save("message",              arp([E5, A5], 0.085, 0.7), -17)
save("message-new-email",    arp([D5, Fs5], 0.1, 0.7), -17)
save("dialog-information",   arp([Fs5], 0, 0.8), -17)
save("dialog-question",      arp([D5, E5], 0.1, 0.7), -17)
save("dialog-warning",       arp([A4, A4], 0.16, 0.6, index=2.2), -15)
save("dialog-error",         arp([D5, Fs4], 0.12, 0.8, ratio=2.7, index=2.0), -15)
save("bell",                 arp([D6], 0, 0.35, decay=12), -22)
save("complete",             mix([(0, bell(D5, 1.0)), (0.02, bell(A5, 1.0, amp=0.7))], 1.1), -16)
save("outcome-success",      arp([D5, A5], 0.07, 0.9), -16)
save("outcome-failure",      arp([A4, Fs4], 0.12, 0.8), -16)
save("device-added",         arp([D5, A5], 0.06, 0.5, decay=7), -17)
save("device-removed",       arp([A5, D5], 0.06, 0.5, decay=7), -17)
save("power-plug",           arp([Fs5, B5], 0.06, 0.5, decay=7), -18)
save("power-unplug",         arp([B5, Fs5], 0.06, 0.5, decay=7), -18)
save("battery-low",          arp([Fs4, Fs4], 0.2, 0.6), -15)
save("trash-empty",          arp([D4, A4], 0.05, 0.6, decay=8, ratio=1.5), -17)
save("audio-volume-change",  tick(1400, 0.05), -24)
save("screen-capture",       mix([(0, tick(2200, 0.04)), (0.07, tick(1700, 0.05))], 0.15), -20)
save("service-login",        arp([D5, A5], 0.1, 0.8), -17)
save("service-logout",       arp([A5, D5], 0.1, 0.8), -17)
print("ok")

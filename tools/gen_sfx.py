"""Genera efectos de sonido (WAV 16-bit mono) para "Ecos de la Noche".

Se sintetizan con math puro, sin dependencias externas.
Ejecutar:  python tools/gen_sfx.py
"""
import os
import math
import random
import wave
import struct

OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "assets", "sfx")
os.makedirs(OUT, exist_ok=True)
SR = 22050


def write_wav(name, samples):
    path = os.path.join(OUT, name)
    with wave.open(path, "w") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        frames = bytearray()
        for s in samples:
            v = max(-1.0, min(1.0, s))
            frames += struct.pack("<h", int(v * 32000))
        w.writeframes(bytes(frames))
    print("sfx:", name)


def env(i, n, attack=0.02, release=0.4):
    t = i / n
    a = min(1.0, t / attack) if attack > 0 else 1.0
    r = min(1.0, (1.0 - t) / release) if release > 0 else 1.0
    return max(0.0, min(a, r))


def sine(freq, t):
    return math.sin(2 * math.pi * freq * t)


def chirp(f0, f1, dur, amp=0.6):
    n = int(SR * dur)
    out = []
    phase = 0.0
    for i in range(n):
        t = i / SR
        f = f0 + (f1 - f0) * (i / n)
        phase += 2 * math.pi * f / SR
        out.append(math.sin(phase) * env(i, n, 0.01, 0.6) * amp)
    return out


def tone(freq, dur, amp=0.5, attack=0.02, release=0.4):
    n = int(SR * dur)
    return [sine(freq, i / SR) * env(i, n, attack, release) * amp for i in range(n)]


def noise_burst(dur, amp=0.6, lp=0.5):
    n = int(SR * dur)
    out = []
    prev = 0.0
    for i in range(n):
        r = random.uniform(-1, 1)
        v = prev + (r - prev) * (1.0 - lp)
        prev = v
        out.append(v * env(i, n, 0.005, 0.5) * amp)
    return out


def concat(*parts):
    out = []
    for p in parts:
        out += p
    return out


def gain(samples, g):
    return [s * g for s in samples]


def echo_wave(dur):
    n = int(SR * dur)
    out = [0.0] * n
    for i in range(n):
        t = i / SR
        f = 9000 - 5000 * (i / n)
        a = math.exp(-6.0 * i / n)
        out[i] = math.sin(2 * math.pi * f * t) * a * 0.7
    return out


# --- Efectos ---

write_wav("echolocation.wav", concat(
    chirp(9000, 3500, 0.18, 0.7),
    [0.0] * int(SR * 0.06),
    gain(echo_wave(0.28), 0.35),
))

write_wav("flap.wav", gain(noise_burst(0.09, 0.5), 0.8))

write_wav("collect_fruit.wav", concat(
    gain(chirp(600, 900, 0.09, 0.5), 0.9),
    gain(chirp(900, 1200, 0.10, 0.5), 0.9),
))

write_wav("collect_bug.wav", concat(
    gain(chirp(300, 520, 0.12, 0.5), 0.9),
    gain(chirp(520, 360, 0.08, 0.4), 0.7),
))

write_wav("hit.wav", concat(
    gain(noise_burst(0.18, 0.8), 1.0),
    gain(chirp(300, 120, 0.18, 0.4), 0.6),
))

write_wav("goal.wav", concat(
    chirp(523, 523, 0.12, 0.4),
    chirp(659, 659, 0.12, 0.4),
    chirp(784, 784, 0.12, 0.4),
    chirp(1046, 1046, 0.22, 0.5),
))

write_wav("defeat.wav", concat(
    chirp(500, 300, 0.25, 0.5),
    chirp(300, 150, 0.45, 0.5),
))

write_wav("click.wav", gain(chirp(900, 1100, 0.05, 0.4), 0.6))

write_wav("start.wav", concat(
    gain(chirp(330, 440, 0.12, 0.4), 0.7),
    gain(chirp(440, 660, 0.16, 0.5), 0.8),
))


# --- Musica ambiental en loop (Am - F - C - G) ---

def note(freq, dur, amp, attack, release):
    n = int(SR * dur)
    out = []
    for i in range(n):
        t = i / SR
        a = min(1.0, i / (SR * attack)) if attack > 0 else 1.0
        r = min(1.0, (n - i) / (SR * release)) if release > 0 else 1.0
        out.append(math.sin(2 * math.pi * freq * t) * amp * min(a, r))
    return out


def mix_into(buf, samples, offset, g):
    for i, s in enumerate(samples):
        j = offset + i
        if 0 <= j < len(buf):
            buf[j] += s * g


def make_music():
    dur = 12.0
    buf = [0.0] * int(SR * dur)
    chords = [
        [220.00, 261.63, 329.63],   # Am
        [174.61, 220.00, 261.63],   # F
        [130.81, 164.81, 196.00],   # C
        [196.00, 246.94, 293.66],   # G
    ]
    seg = dur / len(chords)
    for ci, ch in enumerate(chords):
        off = int(SR * seg * ci)
        for f in ch:
            mix_into(buf, note(f, seg * 1.05, 0.16, 1.2, 1.4), off, 1.0)
            mix_into(buf, note(f * 2.0, seg * 1.05, 0.05, 1.2, 1.4), off, 1.0)
    # destellos suaves
    rnd = random.Random(7)
    for _ in range(10):
        f = rnd.choice([523.25, 659.25, 783.99, 880.0])
        off = int(rnd.uniform(0, dur - 1.0) * SR)
        mix_into(buf, note(f, 1.0, 0.06, 0.3, 0.7), off, 1.0)
    peak = max(1e-6, max(abs(s) for s in buf))
    norm = 0.8 / peak
    return [s * norm for s in buf]


write_wav("music.wav", make_music())

print("Listo. SFX en:", os.path.abspath(OUT))

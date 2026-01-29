from __future__ import annotations

import math
import os
import wave
from dataclasses import dataclass
from typing import List, Tuple

import numpy as np

# -------------------------
# Global settings (lofi)
# -------------------------
SR = 48000
BPM = 78.0
BEATS_PER_BAR = 4
BARS = 16
SWING = 0.05  # subtle
MASTER_GAIN = 0.9

OUT_WAV = "lofi.wav"

# -------------------------
# Helpers
# -------------------------

def midi_to_freq(m: float) -> float:
    return 440.0 * (2.0 ** ((m - 69.0) / 12.0))


def clamp_array(x: np.ndarray, lo: float, hi: float) -> np.ndarray:
    return np.minimum(np.maximum(x, lo), hi)


def soft_clip(x: np.ndarray) -> np.ndarray:
    return np.tanh(x)


def one_pole_lowpass(x: np.ndarray, cutoff: float) -> np.ndarray:
    if cutoff <= 0:
        return x
    rc = 1.0 / (2.0 * math.pi * cutoff)
    dt = 1.0 / SR
    alpha = dt / (rc + dt)
    y = np.zeros_like(x)
    y[0] = x[0]
    for i in range(1, len(x)):
        y[i] = y[i - 1] + alpha * (x[i] - y[i - 1])
    return y


def one_pole_highpass(x: np.ndarray, cutoff: float) -> np.ndarray:
    if cutoff <= 0:
        return x
    rc = 1.0 / (2.0 * math.pi * cutoff)
    dt = 1.0 / SR
    alpha = rc / (rc + dt)
    y = np.zeros_like(x)
    y[0] = x[0]
    for i in range(1, len(x)):
        y[i] = alpha * (y[i - 1] + x[i] - x[i - 1])
    return y


def pan_stereo(sig: np.ndarray, pan: float) -> Tuple[np.ndarray, np.ndarray]:
    pan = max(-1.0, min(1.0, pan))
    left = math.cos((pan + 1.0) * math.pi / 4.0)
    right = math.sin((pan + 1.0) * math.pi / 4.0)
    return sig * left, sig * right


def env_exp(n: int, decay_s: float) -> np.ndarray:
    t = np.arange(n) / SR
    return np.exp(-t / decay_s)


def adsr_env(n: int, a: float, d: float, s: float, r: float, sustain_len_s: float) -> np.ndarray:
    a_s = int(a * SR)
    d_s = int(d * SR)
    s_s = int(max(0.0, sustain_len_s) * SR)
    r_s = int(r * SR)
    total = a_s + d_s + s_s + r_s
    if total <= 0:
        return np.zeros(n, dtype=np.float32)
    env = np.zeros(total, dtype=np.float32)
    if a_s > 0:
        env[:a_s] = np.linspace(0.0, 1.0, a_s, endpoint=False)
    if d_s > 0:
        env[a_s:a_s + d_s] = np.linspace(1.0, s, d_s, endpoint=False)
    if s_s > 0:
        env[a_s + d_s:a_s + d_s + s_s] = s
    if r_s > 0:
        start = a_s + d_s + s_s
        env[start:start + r_s] = np.linspace(s, 0.0, r_s, endpoint=True)
    if total < n:
        env = np.concatenate([env, np.zeros(n - total, dtype=np.float32)])
    else:
        env = env[:n]
    return env


def write_wav(path: str, audio: np.ndarray):
    audio = clamp_array(audio, -1.0, 1.0)
    audio_i16 = (audio * 32767).astype(np.int16)
    with wave.open(path, "wb") as wf:
        wf.setnchannels(2)
        wf.setsampwidth(2)
        wf.setframerate(SR)
        wf.writeframes(audio_i16.tobytes())

# -------------------------
# Drum synthesis (simple)
# -------------------------

def make_kick() -> np.ndarray:
    length = int(0.5 * SR)
    t = np.arange(length) / SR
    f0, f1 = 110.0, 50.0
    freq = f0 * (f1 / f0) ** (t / 0.2)
    phase = np.cumsum(freq) / SR
    body = np.sin(2 * math.pi * phase)
    env = env_exp(length, 0.18)
    sig = body * env
    sig = soft_clip(sig * 1.3)
    return sig * 0.9


def make_snare() -> np.ndarray:
    # Softer, warmer backbeat (less hissy)
    length = int(0.2 * SR)
    t = np.arange(length) / SR
    tone = np.sin(2 * math.pi * 220.0 * t) * env_exp(length, 0.07)
    noise = np.random.uniform(-1, 1, length)
    noise = one_pole_lowpass(noise, 2000.0)
    noise = one_pole_highpass(noise, 300.0)
    noise *= env_exp(length, 0.05)
    sig = tone * 0.7 + noise * 0.3
    sig = soft_clip(sig * 1.2)
    return sig * 0.6


def make_hat(open_hat: bool = False) -> np.ndarray:
    length = int((0.18 if open_hat else 0.05) * SR)
    noise = np.random.uniform(-1, 1, length)
    env = env_exp(length, 0.07 if open_hat else 0.02)
    sig = one_pole_highpass(noise, 5000.0) * env
    return sig * 0.4

# -------------------------
# Music parts
# -------------------------
@dataclass
class NoteEvent:
    time_s: float
    dur_s: float
    midi: float
    vel: float


def render_notes(events: List[NoteEvent], osc: str, cutoff: float, env: Tuple[float, float, float, float]) -> np.ndarray:
    total_len = int(total_seconds() * SR)
    out = np.zeros(total_len, dtype=np.float32)
    for ev in events:
        n = int((ev.dur_s + env[3]) * SR)
        start = int(ev.time_s * SR)
        end = min(start + n, total_len)
        if end <= start:
            continue
        t = np.arange(end - start) / SR
        freq = midi_to_freq(ev.midi)
        if osc == "sine":
            sig = np.sin(2 * math.pi * freq * t)
        elif osc == "tri":
            sig = 2.0 * np.abs(2 * ((freq * t) % 1.0) - 1.0) - 1.0
        else:
            sig = np.sin(2 * math.pi * freq * t)
        env_arr = adsr_env(len(sig), env[0], env[1], env[2], env[3], ev.dur_s)
        sig *= env_arr
        sig = one_pole_lowpass(sig, cutoff)
        sig *= ev.vel
        out[start:end] += sig[: end - start]
    return out


def total_seconds() -> float:
    return (BARS * BEATS_PER_BAR) * 60.0 / BPM

# -------------------------
# Composition
# -------------------------

def build_events() -> Tuple[List[float], List[float], List[NoteEvent], List[NoteEvent]]:
    # Drum triggers
    kick_times: List[float] = []
    snare_times: List[float] = []

    # Music
    chord_events: List[NoteEvent] = []
    bass_events: List[NoteEvent] = []

    # Progression (lofi-ish)
    progression = [
        [57, 60, 64, 67],  # Am7
        [52, 55, 59, 62],  # Em7
        [50, 53, 57, 60],  # Dm7
        [55, 59, 62, 65],  # G7
    ]
    bass_roots = [45, 40, 38, 43]

    for bar in range(BARS):
        base = bar * BEATS_PER_BAR * 60.0 / BPM
        idx = bar % 4
        chord = progression[idx]
        bass = bass_roots[idx]

        # Kick on 1 and 3
        kick_times.append(base + 0.0)
        kick_times.append(base + 2.0 * 60.0 / BPM)

        # Snare on 2 and 4
        snare_times.append(base + 1.0 * 60.0 / BPM)
        snare_times.append(base + 3.0 * 60.0 / BPM)

        # Chords: sustained (whole note)
        for n in chord[:3]:
            chord_events.append(NoteEvent(base, 3.5 * 60.0 / BPM, n, 0.4))

        # Bass: simple root + octave
        bass_events.append(NoteEvent(base + 0.5 * 60.0 / BPM, 0.3, bass, 0.6))
        bass_events.append(NoteEvent(base + 2.5 * 60.0 / BPM, 0.3, bass + 12, 0.5))

    return kick_times, snare_times, chord_events, bass_events

# -------------------------
# Render
# -------------------------

def render_song() -> np.ndarray:
    total_len = int(total_seconds() * SR)
    mix_l = np.zeros(total_len, dtype=np.float32)
    mix_r = np.zeros(total_len, dtype=np.float32)

    # Build events
    kick_times, snare_times, chords, bass = build_events()

    # Drums
    kick = make_kick()
    snare = make_snare()

    def add_sample(sample: np.ndarray, time_s: float, gain: float, pan: float = 0.0):
        start = int(time_s * SR)
        end = min(start + len(sample), total_len)
        if end <= start:
            return
        l, r = pan_stereo(sample[: end - start] * gain, pan)
        mix_l[start:end] += l
        mix_r[start:end] += r

    for t in kick_times:
        add_sample(kick, t, 0.9, 0.0)
    for t in snare_times:
        add_sample(snare, t, 0.5, 0.0)
    # Music
    chord_sig = render_notes(chords, osc="tri", cutoff=1800.0, env=(0.03, 0.12, 0.6, 0.3))
    bass_sig = render_notes(bass, osc="sine", cutoff=200.0, env=(0.005, 0.05, 0.5, 0.08))

    # Simple melody (soft sine)
    melody_events: List[NoteEvent] = []
    scale = [0, 3, 5, 7, 10]  # A minor pentatonic
    for bar in range(BARS):
        base = bar * BEATS_PER_BAR * 60.0 / BPM
        # 2 notes per bar, gentle rhythm
        for step, dur in [(0.0, 0.6), (2.0, 0.6)]:
            note = 57 + 12 + scale[(bar + int(step)) % len(scale)]
            melody_events.append(NoteEvent(base + step * 60.0 / BPM, dur, note, 0.35))
    melody_sig = render_notes(melody_events, osc="sine", cutoff=2600.0, env=(0.01, 0.08, 0.5, 0.2))

    # Mix music
    chord_l, chord_r = pan_stereo(chord_sig * 0.7, -0.1)
    bass_l, bass_r = pan_stereo(bass_sig * 0.9, 0.0)
    mel_l, mel_r = pan_stereo(melody_sig * 0.6, 0.1)
    mix_l += chord_l + bass_l + mel_l
    mix_r += chord_r + bass_r + mel_r

    # Gentle glue
    mix_l = soft_clip(mix_l * 1.05)
    mix_r = soft_clip(mix_r * 1.05)

    mix = np.stack([mix_l, mix_r], axis=1)
    mix *= MASTER_GAIN
    peak = np.max(np.abs(mix))
    if peak > 0:
        mix *= (0.89 / peak)
    return mix


def main():
    audio = render_song()
    out_path = os.path.join(os.path.dirname(os.path.abspath(__file__)), OUT_WAV)
    write_wav(out_path, audio)
    print(f"Rendered: {out_path}")


if __name__ == "__main__":
    main()

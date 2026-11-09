"""Transcribe a WAV file with faster-whisper and print the text (used by `voicetype`)."""
import os, sys
import numpy as np
from faster_whisper import WhisperModel

MODEL = os.environ.get("VOICETYPE_MODEL", "large-v3-turbo")
LANG = os.environ.get("VOICETYPE_LANG") or None          # None = auto-detect

def load():
    try:
        return WhisperModel(MODEL, device="cuda", compute_type="float16")
    except Exception as e:                                # GPU busy/unavailable -> CPU
        print(f"voicetype: CUDA failed ({e}), using CPU", file=sys.stderr)
        return WhisperModel("small", device="cpu", compute_type="int8")

def read_wav(path):
    """16 kHz mono s16 WAV from pw-record -> float32 in [-1, 1].
    Parses the data chunk by hand: pw-record's header can be incomplete when stopped."""
    raw = open(path, "rb").read()
    i = raw.find(b"data")
    pcm = raw[i + 8:] if i >= 0 else raw[44:]
    a = np.frombuffer(pcm[: len(pcm) // 2 * 2], dtype=np.int16).astype(np.float32) / 32768.0
    peak = float(np.abs(a).max()) if a.size else 0.0
    if 0.002 < peak < 0.5:                      # quiet mic: boost to ~70% peak
        a *= 0.7 / peak
    print(f"voicetype: {a.size/16000:.1f}s audio, peak {peak:.3f}", file=sys.stderr)
    return a

segments, info = load().transcribe(read_wav(sys.argv[1]), language=LANG, beam_size=5, vad_filter=True)
text = " ".join(s.text.strip() for s in segments).strip()
print(f"voicetype: lang={info.language} p={info.language_probability:.2f}", file=sys.stderr)
print(text)

"""Remaster bundled sedi_alarm for PHYSICAL-UX: stronger attack/loudness, no clip."""
from __future__ import annotations

import array
import hashlib
import math
import pathlib
import struct
import wave

FE = pathlib.Path(__file__).resolve().parents[1]
SRC = FE / "android" / "app" / "src" / "main" / "res" / "raw" / "sedi_alarm.wav"
ANDROID = SRC
IOS = FE / "ios" / "Runner" / "sedi_alarm.wav"
LICENSE = FE / "docs" / "SEDI_ALARM_SOUND_LICENSE_G1.md"
PRIOR_V4 = "9e5f1b6b3979b17232a1aa7bad984dc0536b4573bbadf194808e26b4f2e63385"
PRIOR_G1 = "6d15a0e60302bb10610f54fed736132d49a108fa5a20ea3a5a0d91fe9e9d2e3b"


def remaster(samples: list[float], sr: int) -> list[float]:
    attack_n = int(sr * 0.090)
    out: list[float] = []
    for i, x in enumerate(samples):
        t = i / sr
        attack_boost = 1.0
        if i < attack_n:
            attack_boost = 1.0 + 0.55 * (1.0 - (i / max(1, attack_n)))
        presence = 1.12 if 0.05 <= t <= 0.40 else 1.0
        y = x * 1.85 * attack_boost * presence
        y = math.tanh(y * 1.15) / math.tanh(1.15)
        out.append(max(-0.97, min(0.97, y)))
    peak = max(abs(v) for v in out) or 1.0
    target_peak = 10 ** (-0.8 / 20)
    scale = target_peak / peak
    return [v * scale for v in out]


def write_wav(path: pathlib.Path, frames: bytes, sr: int) -> str:
    path.parent.mkdir(parents=True, exist_ok=True)
    with wave.open(str(path), "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(sr)
        w.writeframes(frames)
    digest = hashlib.sha256(path.read_bytes()).hexdigest()
    print(f"{path} size={path.stat().st_size} sha256={digest}")
    return digest


def main() -> None:
    with wave.open(str(SRC), "rb") as w:
        assert w.getnchannels() == 1 and w.getsampwidth() == 2
        sr = w.getframerate()
        n = w.getnframes()
        raw = w.readframes(n)
    buf = array.array("h")
    buf.frombytes(raw)
    floats = [s / 32768.0 for s in buf]
    out = remaster(floats, sr)
    peak_db = 20 * math.log10(max(abs(v) for v in out) + 1e-12)
    rms = math.sqrt(sum(v * v for v in out) / len(out))
    rms_db = 20 * math.log10(rms + 1e-12)
    print(f"PEAK_DBFS={peak_db:.2f} RMS_DBFS={rms_db:.2f}")
    ints = [int(max(-32767, min(32767, round(v * 32767)))) for v in out]
    frames = b"".join(struct.pack("<h", s) for s in ints)
    h1 = write_wav(ANDROID, frames, sr)
    h2 = write_wav(IOS, frames, sr)
    assert h1 == h2
    LICENSE.write_text(
        f"""# Sedi V1 canonical notification sound — license evidence

ASSET=sedi_alarm.wav
SHA256={h1}
DURATION_SECONDS=1.25
FORMAT=PCM WAV mono 44.1kHz 16-bit
PEAK_DBFS≈{peak_db:.2f}
RMS_DBFS≈{rms_db:.2f}
GAIN_VS_PRIOR_V4_REMASTER=attack+loudness remaster (physical UX)
CLIPPING=NO
ANDROID_IOS_BYTE_IDENTICAL=YES

SOURCE=ORIGINAL_SEDI_SYNTHESIS
GENERATOR=workspace/tmp/gen_sedi_alarm.py (G1) + A4 sound-fix remaster + PHYSICAL-UX remaster (stronger attack/loudness, soft-limited)
LICENSE=Product-owned original synthesis (no third-party sample). Redistribution with Sedi app permitted.
CC0_OR_THIRD_PARTY=NO
RUNTIME_DOWNLOAD=PROHIBITED

Android path: android/app/src/main/res/raw/sedi_alarm.wav
iOS path: ios/Runner/sedi_alarm.wav (Xcode Resources)

PRIOR_V4_SHA256={PRIOR_V4}
PRIOR_G1_SHA256={PRIOR_G1}
""",
        encoding="utf-8",
    )
    print("LICENSE_UPDATED")


if __name__ == "__main__":
    main()

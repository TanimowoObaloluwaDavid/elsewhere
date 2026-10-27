"""Build the five silent field films from the generated stills.

Each film is a slow push across one wide still, finished with a little grain,
a vignette, and a long fade. No audio: the films are intentionally silent.
"""

from __future__ import annotations

import subprocess
import sys
from pathlib import Path

try:
    import imageio_ffmpeg
except ImportError:  # pragma: no cover - only used by the build tooling
    imageio_ffmpeg = None

ROOT = Path(__file__).resolve().parent.parent
IMAGES = ROOT / "assets" / "images"
VIDEOS = ROOT / "assets" / "videos"

# (film id, place id, duration in seconds)
FILMS = [
    ("north-of-silence", "lofoten", 8),
    ("the-long-light", "sicily", 7),
    ("rain-slowly", "kyoto", 8),
    ("river-of-lanterns", "hoian", 7),
    ("between-dunes", "merzouga", 6),
]

def ffmpeg_path() -> str:
    if imageio_ffmpeg is None:
        raise RuntimeError(
            "imageio-ffmpeg is required to render the films. "
            "Install it with: python -m pip install imageio-ffmpeg"
        )
    return imageio_ffmpeg.get_ffmpeg_exe()


def build(film_id: str, place: str, duration: int, ffmpeg: str) -> None:
    src = IMAGES / f"{place}_02.jpg"
    out = VIDEOS / f"{film_id}.mp4"
    if not src.exists():
        raise FileNotFoundError(f"missing still: {src}")

    frames = duration * 30
    rate = 0.19 / frames
    fade_out = duration - 0.9
    vf = (
        "scale=2560:-2,"
        "crop=2560:1440,"
        f"zoompan=z='min(1.025+{rate:.6f}*on,1.24)'"
        ":x='iw/2-(iw/zoom/2)+sin(on/85)*26'"
        ":y='ih/2-(ih/zoom/2)'"
        ":d=1:s=1280x720:fps=30,"
        "noise=alls=4:allf=t+u,"
        "vignette=PI/6,"
        "fade=t=in:st=0:d=0.6,"
        f"fade=t=out:st={fade_out:.2f}:d=0.9,"
        "setsar=1,"
        "format=yuv420p"
    )

    cmd = [
        ffmpeg,
        "-y",
        "-loop",
        "1",
        "-framerate",
        "30",
        "-i",
        str(src),
        "-vf",
        vf,
        "-t",
        str(duration),
        "-an",
        "-c:v",
        "libx264",
        "-preset",
        "medium",
        "-crf",
        "22",
        "-movflags",
        "+faststart",
        str(out),
    ]

    print(f"  {film_id}.mp4  ({duration}s, from {place}_02.jpg)")
    result = subprocess.run(
        cmd,
        stdout=subprocess.DEVNULL,
        stderr=subprocess.PIPE,
        timeout=600,
        check=False,
    )
    if result.returncode != 0:
        tail = result.stderr.decode("utf-8", "replace").strip().splitlines()[-8:]
        raise RuntimeError(f"ffmpeg failed for {film_id}:\n" + "\n".join(tail))
    print(f"    -> {out.stat().st_size / 1024 / 1024:.1f} MB")


def main() -> int:
    VIDEOS.mkdir(parents=True, exist_ok=True)
    ffmpeg = ffmpeg_path()
    missing = [p for _, p, _ in FILMS if not (IMAGES / f"{p}_02.jpg").exists()]
    if missing:
        print("Waiting on stills: " + ", ".join(missing))
        return 1

    print("Building Elsewhere field films.")
    for film_id, place, duration in FILMS:
        build(film_id, place, duration, ffmpeg)
    print("Done.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
